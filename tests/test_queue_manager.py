"""
Tests for Queue Manager FastAPI endpoints
"""
import pytest
from unittest.mock import patch, MagicMock, AsyncMock
from fastapi.testclient import TestClient
from fastapi import FastAPI, WebSocket
from datetime import datetime, timezone
import json

from models import (
    Job, JobStatus, JobPriority, QueueMode,
    HealthCheck, QueueStatus
)


@pytest.fixture
def app_with_mocks(mock_redis_client, mock_ws_manager):
    """Create FastAPI app with mocked dependencies"""
    from fastapi.testclient import TestClient

    # Create app
    with patch('main.redis_client', mock_redis_client):
        with patch('main.ws_manager', mock_ws_manager):
            with patch('main.app_start_time', datetime.now(timezone.utc)):
                from main import app
                return TestClient(app)


class TestHealthEndpoint:
    """Test health check endpoint"""

    def test_health_check_healthy(self, mock_redis_client):
        """Test health check when system is healthy"""
        mock_redis_client.ping.return_value = True
        mock_redis_client.get_queue_depth.return_value = 5

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.get("/health")

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "healthy"
            assert data["redis_connected"] is True

    def test_health_check_unhealthy(self, mock_redis_client):
        """Test health check when Redis is down"""
        mock_redis_client.ping.return_value = False

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.get("/health")

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "unhealthy"

    def test_health_check_response_format(self, mock_redis_client):
        """Test health check response includes required fields"""
        mock_redis_client.ping.return_value = True
        mock_redis_client.get_queue_depth.return_value = 0

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.get("/health")

            data = response.json()
            assert "status" in data
            assert "version" in data
            assert "redis_connected" in data
            assert "workers_active" in data
            assert "queue_depth" in data
            assert "uptime_seconds" in data


class TestQueueStatusEndpoint:
    """Test queue status endpoint"""

    def test_queue_status_success(self, mock_redis_client):
        """Test getting queue status"""
        mock_redis_client.get_all_queue_stats.return_value = {
            "pending": 10,
            "running": 2,
            "completed": 50,
            "failed": 3
        }

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.get("/api/queue/status")

            assert response.status_code == 200
            data = response.json()
            assert data["pending_jobs"] == 10
            assert data["running_jobs"] == 2
            assert data["completed_jobs"] == 50
            assert data["failed_jobs"] == 3
            assert "mode" in data

    def test_queue_status_error_handling(self, mock_redis_client):
        """Test queue status error handling"""
        mock_redis_client.get_all_queue_stats.side_effect = Exception("Redis error")

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.get("/api/queue/status")

            assert response.status_code == 500


class TestJobSubmissionEndpoint:
    """Test job submission endpoint"""

    def test_submit_job_success(self, mock_redis_client, sample_workflow):
        """Test successful job submission"""
        created_job = Job(
            user_id="user-1",
            workflow=sample_workflow,
            priority=JobPriority.NORMAL
        )
        mock_redis_client.create_job.return_value = True
        mock_redis_client.get_pending_jobs.return_value = [created_job]

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.post(
                "/api/jobs",
                json={
                    "user_id": "user-1",
                    "workflow": sample_workflow,
                    "priority": "normal"
                }
            )

            assert response.status_code == 201
            data = response.json()
            assert "id" in data
            assert data["user_id"] == "user-1"
            assert data["status"] == "pending"

    def test_submit_job_invalid_user_id(self, mock_redis_client):
        """Test job submission with invalid user_id"""
        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.post(
                "/api/jobs",
                json={
                    "user_id": "../admin",  # Path traversal attempt
                    "workflow": {"test": "data"}
                }
            )

            assert response.status_code == 422  # Validation error

    def test_submit_job_empty_workflow(self, mock_redis_client):
        """Test job submission with empty workflow"""
        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.post(
                "/api/jobs",
                json={
                    "user_id": "user-1",
                    "workflow": {}
                }
            )

            assert response.status_code == 422  # Validation error

    def test_submit_job_queue_full(self, mock_redis_client, sample_workflow):
        """Test job submission when queue is full"""
        mock_redis_client.get_queue_depth.return_value = 100  # Max depth
        mock_redis_client.create_job.return_value = True

        with patch('main.redis_client', mock_redis_client):
            with patch('main.settings') as mock_settings:
                mock_settings.max_queue_depth = 100
                mock_settings.queue_mode = "fifo"
                from main import app
                client = TestClient(app)
                response = client.post(
                    "/api/jobs",
                    json={
                        "user_id": "user-1",
                        "workflow": sample_workflow
                    }
                )

                assert response.status_code == 429  # Too many requests


class TestGetJobEndpoint:
    """Test get job endpoint"""

    def test_get_job_success(self, mock_redis_client, sample_job):
        """Test getting existing job"""
        mock_redis_client.get_job.return_value = sample_job
        mock_redis_client.get_pending_jobs.return_value = [sample_job]

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.get(f"/api/jobs/{sample_job.id}")

            assert response.status_code == 200
            data = response.json()
            assert data["id"] == sample_job.id
            assert data["user_id"] == "user-1"

    def test_get_job_not_found(self, mock_redis_client):
        """Test getting nonexistent job"""
        mock_redis_client.get_job.return_value = None

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.get("/api/jobs/nonexistent-id")

            assert response.status_code == 404
            data = response.json()
            assert "not found" in data["detail"].lower()


class TestListJobsEndpoint:
    """Test list jobs endpoint"""

    def test_list_all_jobs(self, mock_redis_client, multiple_jobs):
        """Test listing all jobs"""
        mock_redis_client.get_pending_jobs.return_value = multiple_jobs[:3]

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.get("/api/jobs")

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 3

    def test_list_user_jobs(self, mock_redis_client, multiple_jobs):
        """Test listing jobs for specific user"""
        user_jobs = [j for j in multiple_jobs if j.user_id == "user-1"]
        mock_redis_client.get_user_jobs.return_value = user_jobs

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.get("/api/jobs?user_id=user-1")

            assert response.status_code == 200
            data = response.json()
            for job in data:
                assert job["user_id"] == "user-1"

    def test_list_jobs_with_limit(self, mock_redis_client, multiple_jobs):
        """Test listing jobs with limit"""
        mock_redis_client.get_pending_jobs.return_value = multiple_jobs[:2]

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.get("/api/jobs?limit=2")

            assert response.status_code == 200
            data = response.json()
            assert len(data) <= 2

    def test_list_jobs_with_status_filter(self, mock_redis_client):
        """Test listing jobs with status filter"""
        pending_jobs = [
            Job(user_id="user-1", workflow={"test": 1}, status=JobStatus.PENDING),
            Job(user_id="user-2", workflow={"test": 1}, status=JobStatus.PENDING),
        ]
        mock_redis_client.get_pending_jobs.return_value = pending_jobs

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.get("/api/jobs?status=pending")

            assert response.status_code == 200


class TestCancelJobEndpoint:
    """Test cancel job endpoint"""

    def test_cancel_pending_job(self, mock_redis_client, sample_job):
        """Test canceling a pending job"""
        mock_redis_client.get_job.return_value = sample_job
        mock_redis_client.delete_job.return_value = True

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.delete(f"/api/jobs/{sample_job.id}")

            assert response.status_code == 204

    def test_cancel_running_job(self, mock_redis_client, sample_job):
        """Test canceling a running job"""
        running_job = sample_job.copy()
        running_job.status = JobStatus.RUNNING
        mock_redis_client.get_job.return_value = running_job
        mock_redis_client.update_job.return_value = True

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.delete(f"/api/jobs/{running_job.id}")

            assert response.status_code == 204

    def test_cancel_completed_job_error(self, mock_redis_client, job_with_result):
        """Test canceling completed job returns error"""
        mock_redis_client.get_job.return_value = job_with_result

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.delete(f"/api/jobs/{job_with_result.id}")

            assert response.status_code == 400
            data = response.json()
            assert "cannot cancel" in data["detail"].lower()

    def test_cancel_nonexistent_job(self, mock_redis_client):
        """Test canceling nonexistent job"""
        mock_redis_client.get_job.return_value = None

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.delete("/api/jobs/nonexistent-id")

            assert response.status_code == 404


class TestPriorityUpdateEndpoint:
    """Test priority update endpoint"""

    def test_update_job_priority_success(self, mock_redis_client, sample_job):
        """Test successfully updating job priority"""
        mock_redis_client.get_job.return_value = sample_job
        mock_redis_client.update_job.return_value = True

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.patch(
                f"/api/jobs/{sample_job.id}/priority",
                json={"priority": 0}  # INSTRUCTOR priority
            )

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "success"

    def test_update_priority_running_job_error(self, mock_redis_client, sample_job):
        """Test updating priority of running job returns error"""
        running_job = sample_job.copy()
        running_job.status = JobStatus.RUNNING
        mock_redis_client.get_job.return_value = running_job

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.patch(
                f"/api/jobs/{running_job.id}/priority",
                json={"priority": 0}
            )

            assert response.status_code == 400

    def test_update_priority_nonexistent_job(self, mock_redis_client):
        """Test updating priority of nonexistent job"""
        mock_redis_client.get_job.return_value = None

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.patch(
                "/api/jobs/nonexistent-id/priority",
                json={"priority": 0}
            )

            assert response.status_code == 404


class TestWorkerEndpoints:
    """Test worker-related endpoints"""

    def test_get_next_job_success(self, mock_redis_client, sample_job):
        """Test getting next job for worker"""
        mock_redis_client.get_next_job.return_value = sample_job
        mock_redis_client.move_job_to_running.return_value = True
        mock_redis_client.update_worker_heartbeat.return_value = True

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.get("/api/workers/next-job?worker_id=worker-1")

            assert response.status_code == 200
            data = response.json()
            assert data["job"] is not None
            assert data["job"]["id"] == sample_job.id

    def test_get_next_job_empty_queue(self, mock_redis_client):
        """Test getting next job when queue is empty"""
        mock_redis_client.get_next_job.return_value = None
        mock_redis_client.update_worker_heartbeat.return_value = True

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.get("/api/workers/next-job?worker_id=worker-1")

            assert response.status_code == 200
            data = response.json()
            assert data["job"] is None

    def test_complete_job_success(self, mock_redis_client, sample_job, job_completion_request):
        """Test completing a job"""
        mock_redis_client.move_job_to_completed.return_value = True

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.post(
                f"/api/workers/complete-job?job_id={sample_job.id}",
                json=job_completion_request.model_dump()
            )

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "success"

    def test_complete_job_not_found(self, mock_redis_client, job_completion_request):
        """Test completing nonexistent job"""
        mock_redis_client.move_job_to_completed.return_value = False

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.post(
                "/api/workers/complete-job?job_id=nonexistent",
                json=job_completion_request.model_dump()
            )

            assert response.status_code == 404

    def test_fail_job_success(self, mock_redis_client, sample_job, job_failure_request):
        """Test marking job as failed"""
        mock_redis_client.move_job_to_failed.return_value = True

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.post(
                f"/api/workers/fail-job?job_id={sample_job.id}",
                json=job_failure_request.model_dump()
            )

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "success"

    def test_fail_job_invalid_error_message(self, mock_redis_client, sample_job):
        """Test failing job with invalid error message"""
        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.post(
                f"/api/workers/fail-job?job_id={sample_job.id}",
                json={"error": ""}  # Empty error
            )

            assert response.status_code == 422  # Validation error


class TestCORSConfiguration:
    """Test CORS configuration"""

    def test_cors_allowed_origin(self, mock_redis_client):
        """Test CORS with allowed origin"""
        mock_redis_client.ping.return_value = True
        mock_redis_client.get_queue_depth.return_value = 0

        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.get(
                "/health",
                headers={"Origin": "https://comfy.ahelme.net"}
            )

            assert response.status_code == 200

    def test_options_request(self, mock_redis_client):
        """Test OPTIONS request for CORS"""
        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.options(
                "/health",
                headers={"Origin": "https://comfy.ahelme.net"}
            )

            # Should allow or pass through
            assert response.status_code in [200, 204]


class TestErrorHandling:
    """Test error handling"""

    def test_invalid_request_body(self, mock_redis_client):
        """Test handling of invalid request body"""
        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.post(
                "/api/jobs",
                json={"invalid": "data"}
            )

            assert response.status_code == 422

    def test_missing_required_fields(self, mock_redis_client):
        """Test handling of missing required fields"""
        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.post(
                "/api/jobs",
                json={"user_id": "user-1"}  # Missing workflow
            )

            assert response.status_code == 422

    def test_method_not_allowed(self, mock_redis_client):
        """Test 405 method not allowed"""
        with patch('main.redis_client', mock_redis_client):
            from main import app
            client = TestClient(app)
            response = client.put("/api/jobs")  # PUT not allowed

            assert response.status_code == 405
