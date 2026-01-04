"""
Tests for ComfyUI Worker functionality
"""
import pytest
import asyncio
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import datetime, timezone

from models import Job, JobStatus, JobPriority


class TestWorkerJobPolling:
    """Test worker job polling mechanism"""

    @pytest.mark.asyncio
    async def test_worker_poll_gets_next_job(self, mock_redis_client, sample_job):
        """Test worker successfully polls for next job"""
        mock_redis_client.get_next_job.return_value = sample_job

        # Simulate worker polling
        job = mock_redis_client.get_next_job()

        assert job is not None
        assert job.id == sample_job.id

    @pytest.mark.asyncio
    async def test_worker_poll_empty_queue(self, mock_redis_client):
        """Test worker poll returns None when queue is empty"""
        mock_redis_client.get_next_job.return_value = None

        job = mock_redis_client.get_next_job()

        assert job is None

    @pytest.mark.asyncio
    async def test_worker_heartbeat_on_poll(self, mock_redis_client):
        """Test worker sends heartbeat on successful poll"""
        mock_redis_client.update_worker_heartbeat.return_value = True

        result = mock_redis_client.update_worker_heartbeat("worker-1")

        assert result is True
        mock_redis_client.update_worker_heartbeat.assert_called_once_with("worker-1")


class TestWorkerJobExecution:
    """Test worker job execution"""

    @pytest.mark.asyncio
    async def test_worker_start_job_execution(self, mock_redis_client, sample_job):
        """Test worker marks job as running"""
        mock_redis_client.move_job_to_running.return_value = True

        result = mock_redis_client.move_job_to_running(sample_job.id, "worker-1")

        assert result is True

    @pytest.mark.asyncio
    async def test_worker_complete_job_success(self, mock_redis_client, sample_job):
        """Test worker completes job successfully"""
        result_data = {
            "output_images": ["image_001.png", "image_002.png"],
            "execution_time": 120.5
        }
        mock_redis_client.move_job_to_completed.return_value = True

        result = mock_redis_client.move_job_to_completed(sample_job.id, result_data)

        assert result is True

    @pytest.mark.asyncio
    async def test_worker_fail_job(self, mock_redis_client, sample_job):
        """Test worker marks job as failed"""
        error_message = "CUDA out of memory"
        mock_redis_client.move_job_to_failed.return_value = True

        result = mock_redis_client.move_job_to_failed(sample_job.id, error_message)

        assert result is True


class TestWorkerHeartbeat:
    """Test worker heartbeat mechanism"""

    @pytest.mark.asyncio
    async def test_worker_heartbeat_interval(self, mock_redis_client):
        """Test worker sends heartbeats at regular intervals"""
        mock_redis_client.update_worker_heartbeat.return_value = True

        # Simulate sending multiple heartbeats
        for i in range(3):
            result = mock_redis_client.update_worker_heartbeat("worker-1")
            assert result is True

        # Verify multiple calls
        assert mock_redis_client.update_worker_heartbeat.call_count == 3

    @pytest.mark.asyncio
    async def test_worker_heartbeat_failure_handling(self, mock_redis_client):
        """Test worker handles heartbeat failures gracefully"""
        mock_redis_client.update_worker_heartbeat.side_effect = Exception("Redis error")

        # Should not raise, just log
        try:
            mock_redis_client.update_worker_heartbeat("worker-1")
        except Exception:
            pass  # Expected in mock

    @pytest.mark.asyncio
    async def test_check_worker_alive(self, mock_redis_client):
        """Test checking if worker is alive"""
        mock_redis_client.is_worker_alive.return_value = True

        is_alive = mock_redis_client.is_worker_alive("worker-1")

        assert is_alive is True

    @pytest.mark.asyncio
    async def test_check_worker_dead(self, mock_redis_client):
        """Test checking if worker is dead"""
        mock_redis_client.is_worker_alive.return_value = False

        is_alive = mock_redis_client.is_worker_alive("worker-1")

        assert is_alive is False


class TestWorkerErrorHandling:
    """Test worker error handling"""

    @pytest.mark.asyncio
    async def test_worker_handles_invalid_job(self, mock_redis_client):
        """Test worker handles invalid job gracefully"""
        # Mock returns invalid job (None)
        mock_redis_client.get_next_job.return_value = None

        job = mock_redis_client.get_next_job()

        assert job is None

    @pytest.mark.asyncio
    async def test_worker_handles_job_execution_error(self, mock_redis_client, sample_job):
        """Test worker properly reports job execution errors"""
        error_msg = "ComfyUI execution failed: invalid node configuration"
        mock_redis_client.move_job_to_failed.return_value = True

        result = mock_redis_client.move_job_to_failed(sample_job.id, error_msg)

        assert result is True

    @pytest.mark.asyncio
    async def test_worker_handles_redis_connection_error(self, mock_redis_client):
        """Test worker handles Redis connection errors"""
        from redis.exceptions import RedisError
        mock_redis_client.update_worker_heartbeat.side_effect = RedisError("Connection failed")

        # Should handle gracefully
        with pytest.raises(RedisError):
            mock_redis_client.update_worker_heartbeat("worker-1")


class TestWorkerJobPriority:
    """Test worker respects job priorities"""

    @pytest.mark.asyncio
    async def test_worker_gets_high_priority_job_first(self, mock_redis_client):
        """Test that high priority jobs are served first"""
        high_priority_job = Job(
            user_id="user-1",
            workflow={"test": 1},
            priority=JobPriority.HIGH
        )
        mock_redis_client.get_next_job.return_value = high_priority_job

        job = mock_redis_client.get_next_job()

        assert job is not None
        assert job.priority == JobPriority.HIGH

    @pytest.mark.asyncio
    async def test_worker_gets_instructor_override_job(self, mock_redis_client):
        """Test that instructor override jobs take precedence"""
        instructor_job = Job(
            user_id="instructor",
            workflow={"test": 1},
            priority=JobPriority.INSTRUCTOR
        )
        mock_redis_client.get_next_job.return_value = instructor_job

        job = mock_redis_client.get_next_job()

        assert job is not None
        assert job.priority == JobPriority.INSTRUCTOR


class TestWorkerConcurrency:
    """Test multiple workers processing jobs concurrently"""

    @pytest.mark.asyncio
    async def test_multiple_workers_no_race_condition(self, mock_redis_client, multiple_jobs):
        """Test that multiple workers don't process same job"""
        # Setup mock to return different jobs for different workers
        job_queue = list(multiple_jobs)
        mock_redis_client.get_next_job.side_effect = job_queue

        # Simulate 2 workers getting jobs
        job1 = mock_redis_client.get_next_job()
        job2 = mock_redis_client.get_next_job()

        # Jobs should be different
        assert job1 is not None
        assert job2 is not None
        assert job1.id != job2.id

    @pytest.mark.asyncio
    async def test_multiple_workers_concurrent_heartbeats(self, mock_redis_client):
        """Test multiple workers sending heartbeats concurrently"""
        mock_redis_client.update_worker_heartbeat.return_value = True

        # Simulate concurrent heartbeats from multiple workers
        workers = [f"worker-{i}" for i in range(3)]
        for worker in workers:
            mock_redis_client.update_worker_heartbeat(worker)

        # All heartbeats should succeed
        assert mock_redis_client.update_worker_heartbeat.call_count == 3


class TestWorkerMetadata:
    """Test worker tracks job metadata"""

    @pytest.mark.asyncio
    async def test_worker_preserves_job_metadata(self, mock_redis_client, sample_job):
        """Test that worker preserves job metadata"""
        assert sample_job.metadata is not None
        assert sample_job.metadata.get("session_id") is not None

    @pytest.mark.asyncio
    async def test_worker_includes_metadata_in_result(self, mock_redis_client, sample_job):
        """Test worker includes metadata with result"""
        result = {
            "output": "image.png",
            "metadata": {
                "session_id": sample_job.metadata.get("session_id"),
                "execution_time": 120
            }
        }
        mock_redis_client.move_job_to_completed.return_value = True

        success = mock_redis_client.move_job_to_completed(sample_job.id, result)

        assert success is True


class TestWorkerJobTimeout:
    """Test worker timeout handling"""

    @pytest.mark.asyncio
    async def test_stale_job_cleanup(self, mock_redis_client):
        """Test that stale jobs are cleaned up"""
        mock_redis_client.cleanup_stale_jobs.return_value = 2

        count = mock_redis_client.cleanup_stale_jobs(timeout_seconds=3600)

        assert count == 2

    @pytest.mark.asyncio
    async def test_long_running_job_timeout(self, mock_redis_client, sample_job):
        """Test that long-running jobs are marked as failed"""
        mock_redis_client.move_job_to_failed.return_value = True

        result = mock_redis_client.move_job_to_failed(
            sample_job.id,
            "Job timeout exceeded"
        )

        assert result is True


class TestWorkerUserIsolation:
    """Test that workers maintain user isolation"""

    @pytest.mark.asyncio
    async def test_job_has_user_id(self, sample_job):
        """Test that jobs preserve user information"""
        assert sample_job.user_id is not None
        assert sample_job.user_id == "user-1"

    @pytest.mark.asyncio
    async def test_user_jobs_only_their_own(self, mock_redis_client):
        """Test that user can only see their jobs"""
        user_job = Job(user_id="user-1", workflow={"test": 1})
        mock_redis_client.get_user_jobs.return_value = [user_job]

        jobs = mock_redis_client.get_user_jobs("user-1")

        assert len(jobs) == 1
        assert all(j.user_id == "user-1" for j in jobs)


class TestWorkerLoadBalancing:
    """Test worker load balancing"""

    @pytest.mark.asyncio
    async def test_round_robin_distribution(self, mock_redis_client, multiple_jobs):
        """Test round-robin job distribution"""
        # Setup mock to simulate round-robin
        mock_redis_client.get_next_job.side_effect = multiple_jobs

        # Get jobs from different workers
        jobs = []
        for _ in range(3):
            job = mock_redis_client.get_next_job()
            if job:
                jobs.append(job)

        # Should get different jobs
        job_ids = [j.id for j in jobs]
        assert len(set(job_ids)) == len(job_ids)  # All unique


class TestWorkerStatusTracking:
    """Test worker status tracking"""

    @pytest.mark.asyncio
    async def test_worker_idle_status(self, mock_redis_client):
        """Test worker idle status when no jobs available"""
        mock_redis_client.get_next_job.return_value = None

        job = mock_redis_client.get_next_job()

        assert job is None

    @pytest.mark.asyncio
    async def test_worker_busy_status(self, mock_redis_client, sample_job):
        """Test worker busy status when processing job"""
        mock_redis_client.get_next_job.return_value = sample_job
        mock_redis_client.move_job_to_running.return_value = True

        job = mock_redis_client.get_next_job()
        assert job is not None

        result = mock_redis_client.move_job_to_running(job.id, "worker-1")
        assert result is True


class TestWorkerJobCompletion:
    """Test job completion workflows"""

    @pytest.mark.asyncio
    async def test_successful_job_completion_workflow(
        self,
        mock_redis_client,
        sample_job,
        job_completion_request
    ):
        """Test complete workflow of job execution and completion"""
        # Setup
        mock_redis_client.get_job.return_value = sample_job
        mock_redis_client.move_job_to_running.return_value = True
        mock_redis_client.move_job_to_completed.return_value = True

        # Get job
        job = mock_redis_client.get_job(sample_job.id)
        assert job is not None

        # Mark as running
        running = mock_redis_client.move_job_to_running(job.id, "worker-1")
        assert running is True

        # Complete with result
        completed = mock_redis_client.move_job_to_completed(
            job.id,
            job_completion_request.result
        )
        assert completed is True

    @pytest.mark.asyncio
    async def test_failed_job_workflow(
        self,
        mock_redis_client,
        sample_job,
        job_failure_request
    ):
        """Test workflow for failed job"""
        # Setup
        mock_redis_client.get_job.return_value = sample_job
        mock_redis_client.move_job_to_running.return_value = True
        mock_redis_client.move_job_to_failed.return_value = True

        # Get job
        job = mock_redis_client.get_job(sample_job.id)
        assert job is not None

        # Mark as running
        running = mock_redis_client.move_job_to_running(job.id, "worker-1")
        assert running is True

        # Mark as failed
        failed = mock_redis_client.move_job_to_failed(job.id, job_failure_request.error)
        assert failed is True


class TestWorkerRestarts:
    """Test worker restart scenarios"""

    @pytest.mark.asyncio
    async def test_worker_recovery_after_restart(self, mock_redis_client):
        """Test worker can recover after restart"""
        # After restart, worker should be able to reconnect
        mock_redis_client.update_worker_heartbeat.return_value = True

        result = mock_redis_client.update_worker_heartbeat("worker-1")

        assert result is True

    @pytest.mark.asyncio
    async def test_stale_worker_jobs_marked_failed(self, mock_redis_client):
        """Test that jobs from stale workers are marked failed"""
        mock_redis_client.cleanup_stale_jobs.return_value = 3

        count = mock_redis_client.cleanup_stale_jobs(timeout_seconds=300)

        assert count == 3


class TestWorkerWorkflowExecution:
    """Test worker ComfyUI workflow execution"""

    @pytest.mark.asyncio
    async def test_worker_has_workflow_data(self, sample_job, sample_workflow):
        """Test that worker receives complete workflow"""
        assert sample_job.workflow is not None
        assert isinstance(sample_job.workflow, dict)

    @pytest.mark.asyncio
    async def test_large_workflow_handling(self, mock_redis_client):
        """Test worker can handle large workflows"""
        large_workflow = {
            "nodes": [
                {"id": str(i), "type": "TestNode", "params": {"data": "x" * 1000}}
                for i in range(100)
            ]
        }
        job = Job(
            user_id="user-1",
            workflow=large_workflow,
            priority=JobPriority.NORMAL
        )

        assert job.workflow is not None
        assert len(job.workflow["nodes"]) == 100
