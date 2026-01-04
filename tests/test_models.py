"""
Tests for Pydantic models - validation and serialization
"""
import pytest
import json
from datetime import datetime, timezone
from pydantic import ValidationError

from models import (
    Job, JobStatus, JobPriority, QueueMode,
    JobSubmitRequest, JobCompletionRequest, JobFailureRequest,
    JobResponse, QueueStatus, HealthCheck, WorkerStatus,
    MAX_WORKFLOW_SIZE_BYTES, MAX_METADATA_SIZE_BYTES,
    MAX_RESULT_SIZE_BYTES, MAX_ERROR_MESSAGE_LENGTH
)


class TestJobStatus:
    """Test JobStatus enum"""

    def test_job_status_values(self):
        """Test that job status enum has correct values"""
        assert JobStatus.PENDING.value == "pending"
        assert JobStatus.RUNNING.value == "running"
        assert JobStatus.COMPLETED.value == "completed"
        assert JobStatus.FAILED.value == "failed"
        assert JobStatus.CANCELLED.value == "cancelled"

    def test_job_status_creation(self):
        """Test creating JobStatus from string"""
        assert JobStatus("pending") == JobStatus.PENDING
        assert JobStatus("running") == JobStatus.RUNNING


class TestJobPriority:
    """Test JobPriority enum"""

    def test_job_priority_ordering(self):
        """Test that priorities are correctly ordered (lower = higher priority)"""
        assert JobPriority.INSTRUCTOR.value == 0  # Highest priority
        assert JobPriority.HIGH.value == 1
        assert JobPriority.NORMAL.value == 2
        assert JobPriority.LOW.value == 3  # Lowest priority

    def test_job_priority_comparison(self):
        """Test priority comparison"""
        assert JobPriority.INSTRUCTOR < JobPriority.HIGH
        assert JobPriority.HIGH < JobPriority.NORMAL


class TestQueueMode:
    """Test QueueMode enum"""

    def test_queue_mode_values(self):
        """Test queue mode enum values"""
        assert QueueMode.FIFO.value == "fifo"
        assert QueueMode.ROUND_ROBIN.value == "round_robin"
        assert QueueMode.PRIORITY.value == "priority"


class TestJobModel:
    """Test Job model"""

    def test_job_creation(self, sample_job):
        """Test creating a job"""
        assert sample_job.id is not None
        assert sample_job.user_id == "user-1"
        assert sample_job.status == JobStatus.PENDING
        assert sample_job.priority == JobPriority.NORMAL
        assert sample_job.created_at is not None

    def test_job_default_id_generation(self):
        """Test that job ID is auto-generated"""
        job1 = Job(
            user_id="user-1",
            workflow={"test": "workflow"}
        )
        job2 = Job(
            user_id="user-1",
            workflow={"test": "workflow"}
        )
        assert job1.id != job2.id

    def test_job_default_priority(self):
        """Test that default priority is NORMAL"""
        job = Job(
            user_id="user-1",
            workflow={"test": "workflow"}
        )
        assert job.priority == JobPriority.NORMAL

    def test_job_default_status(self):
        """Test that default status is PENDING"""
        job = Job(
            user_id="user-1",
            workflow={"test": "workflow"}
        )
        assert job.status == JobStatus.PENDING

    def test_job_serialization(self, sample_job):
        """Test job serialization to JSON"""
        job_json = sample_job.model_dump_json()
        assert isinstance(job_json, str)
        data = json.loads(job_json)
        assert data["id"] == sample_job.id
        assert data["user_id"] == "user-1"

    def test_job_deserialization(self):
        """Test job deserialization from JSON"""
        job_data = {
            "id": "test-id",
            "user_id": "user-1",
            "workflow": {"test": "data"},
            "status": "pending",
            "priority": 2,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "started_at": None,
            "completed_at": None,
            "worker_id": None,
            "result": None,
            "error": None,
            "metadata": {}
        }
        job = Job.model_validate(job_data)
        assert job.id == "test-id"
        assert job.user_id == "user-1"


class TestJobSubmitRequest:
    """Test JobSubmitRequest model and validation"""

    def test_valid_submission(self, job_submit_request):
        """Test valid job submission"""
        assert job_submit_request.user_id == "user-1"
        assert job_submit_request.workflow is not None

    def test_user_id_validation_valid_formats(self):
        """Test valid user_id formats"""
        valid_ids = [
            "user-1",
            "user_1",
            "USER1",
            "user-123-abc",
            "a",
            "test_user_with_underscores",
        ]
        for user_id in valid_ids:
            request = JobSubmitRequest(
                user_id=user_id,
                workflow={"test": "workflow"}
            )
            assert request.user_id == user_id

    def test_user_id_validation_invalid_formats(self):
        """Test invalid user_id formats"""
        invalid_ids = [
            "",  # Empty
            "../admin",  # Path traversal
            "user/1",  # Slash
            "user\\1",  # Backslash
            "user..name",  # Double dots
            "user@domain",  # Special char
            "a" * 101,  # Too long
        ]
        for user_id in invalid_ids:
            with pytest.raises(ValidationError):
                JobSubmitRequest(
                    user_id=user_id,
                    workflow={"test": "workflow"}
                )

    def test_workflow_empty_validation(self):
        """Test that empty workflow is rejected"""
        with pytest.raises(ValidationError):
            JobSubmitRequest(
                user_id="user-1",
                workflow={}
            )

    def test_workflow_non_dict_validation(self):
        """Test that non-dict workflow is rejected"""
        with pytest.raises(ValidationError):
            JobSubmitRequest(
                user_id="user-1",
                workflow="not a dict"
            )

    def test_workflow_size_validation_under_limit(self):
        """Test workflow under size limit"""
        workflow = {"data": "x" * 1000}
        request = JobSubmitRequest(
            user_id="user-1",
            workflow=workflow
        )
        assert request.workflow == workflow

    def test_workflow_size_validation_over_limit(self):
        """Test workflow over size limit"""
        # Create workflow larger than MAX_WORKFLOW_SIZE_BYTES
        large_data = "x" * (MAX_WORKFLOW_SIZE_BYTES + 1000)
        workflow = {"data": large_data}
        with pytest.raises(ValidationError) as exc_info:
            JobSubmitRequest(
                user_id="user-1",
                workflow=workflow
            )
        assert "exceeds maximum" in str(exc_info.value)

    def test_metadata_size_validation_over_limit(self):
        """Test metadata over size limit"""
        large_metadata = {"data": "x" * (MAX_METADATA_SIZE_BYTES + 1000)}
        with pytest.raises(ValidationError):
            JobSubmitRequest(
                user_id="user-1",
                workflow={"test": "data"},
                metadata=large_metadata
            )

    def test_priority_validation(self):
        """Test priority field"""
        request = JobSubmitRequest(
            user_id="user-1",
            workflow={"test": "data"},
            priority=JobPriority.HIGH
        )
        assert request.priority == JobPriority.HIGH

    def test_default_priority(self):
        """Test default priority is NORMAL"""
        request = JobSubmitRequest(
            user_id="user-1",
            workflow={"test": "data"}
        )
        assert request.priority == JobPriority.NORMAL

    def test_metadata_default_empty(self):
        """Test metadata defaults to empty dict"""
        request = JobSubmitRequest(
            user_id="user-1",
            workflow={"test": "data"}
        )
        assert request.metadata == {}


class TestJobCompletionRequest:
    """Test JobCompletionRequest model"""

    def test_valid_completion(self, job_completion_request):
        """Test valid job completion"""
        assert job_completion_request.result is not None
        assert isinstance(job_completion_request.result, dict)

    def test_result_validation_non_dict(self):
        """Test that non-dict result is rejected"""
        with pytest.raises(ValidationError):
            JobCompletionRequest(result="not a dict")

    def test_result_size_validation_under_limit(self):
        """Test result under size limit"""
        result = {"output": "x" * 1000}
        request = JobCompletionRequest(result=result)
        assert request.result == result

    def test_result_size_validation_over_limit(self):
        """Test result over size limit"""
        large_data = "x" * (MAX_RESULT_SIZE_BYTES + 1000)
        with pytest.raises(ValidationError) as exc_info:
            JobCompletionRequest(result={"data": large_data})
        assert "too large" in str(exc_info.value)

    def test_result_with_complex_structure(self):
        """Test result with complex nested structure"""
        result = {
            "images": ["img1.png", "img2.png"],
            "metadata": {
                "execution_time": 120.5,
                "nodes_processed": 5,
                "gpu_memory_used": 8192
            },
            "status": "success"
        }
        request = JobCompletionRequest(result=result)
        assert request.result == result


class TestJobFailureRequest:
    """Test JobFailureRequest model"""

    def test_valid_failure(self, job_failure_request):
        """Test valid job failure"""
        assert job_failure_request.error is not None
        assert len(job_failure_request.error) > 0

    def test_error_empty_validation(self):
        """Test that empty error is rejected"""
        with pytest.raises(ValidationError):
            JobFailureRequest(error="")

    def test_error_whitespace_only_validation(self):
        """Test that whitespace-only error is rejected"""
        with pytest.raises(ValidationError):
            JobFailureRequest(error="   ")

    def test_error_size_validation_under_limit(self):
        """Test error under size limit"""
        error = "x" * 1000
        request = JobFailureRequest(error=error)
        assert request.error == error

    def test_error_size_validation_over_limit(self):
        """Test error over size limit"""
        long_error = "x" * (MAX_ERROR_MESSAGE_LENGTH + 1)
        with pytest.raises(ValidationError):
            JobFailureRequest(error=long_error)

    def test_error_whitespace_stripping(self):
        """Test that error message whitespace is stripped"""
        request = JobFailureRequest(error="  error message  ")
        assert request.error == "error message"


class TestJobResponse:
    """Test JobResponse model"""

    def test_job_response_creation(self, sample_job):
        """Test creating a job response"""
        response = JobResponse(
            id=sample_job.id,
            user_id=sample_job.user_id,
            status=sample_job.status,
            priority=sample_job.priority,
            created_at=sample_job.created_at,
            started_at=None,
            completed_at=None,
            worker_id=None,
            result=None,
            error=None,
            position_in_queue=0
        )
        assert response.id == sample_job.id
        assert response.position_in_queue == 0

    def test_job_response_with_estimated_wait_time(self, sample_job):
        """Test job response with estimated wait time"""
        response = JobResponse(
            id=sample_job.id,
            user_id=sample_job.user_id,
            status=sample_job.status,
            priority=sample_job.priority,
            created_at=sample_job.created_at,
            started_at=None,
            completed_at=None,
            worker_id=None,
            result=None,
            error=None,
            estimated_wait_time=300
        )
        assert response.estimated_wait_time == 300


class TestQueueStatus:
    """Test QueueStatus model"""

    def test_queue_status_creation(self):
        """Test creating queue status"""
        status = QueueStatus(
            mode=QueueMode.FIFO,
            pending_jobs=5,
            running_jobs=2,
            completed_jobs=10,
            failed_jobs=1,
            total_workers=2,
            active_workers=2,
            queue_depth=5
        )
        assert status.mode == QueueMode.FIFO
        assert status.pending_jobs == 5
        assert status.running_jobs == 2


class TestHealthCheck:
    """Test HealthCheck model"""

    def test_health_check_healthy(self):
        """Test healthy health check response"""
        health = HealthCheck(
            status="healthy",
            version="0.1.0",
            redis_connected=True,
            workers_active=2,
            queue_depth=5,
            uptime_seconds=3600
        )
        assert health.status == "healthy"
        assert health.redis_connected is True

    def test_health_check_unhealthy(self):
        """Test unhealthy health check response"""
        health = HealthCheck(
            status="unhealthy",
            version="0.1.0",
            redis_connected=False,
            workers_active=0,
            queue_depth=0,
            uptime_seconds=10
        )
        assert health.status == "unhealthy"
        assert health.redis_connected is False


class TestWorkerStatus:
    """Test WorkerStatus model"""

    def test_worker_status_creation(self):
        """Test creating worker status"""
        now = datetime.now(timezone.utc)
        status = WorkerStatus(
            worker_id="worker-1",
            status="busy",
            current_job_id="job-001",
            jobs_completed=5,
            last_heartbeat=now,
            provider="local"
        )
        assert status.worker_id == "worker-1"
        assert status.jobs_completed == 5

    def test_worker_status_with_gpu_info(self):
        """Test worker status with GPU information"""
        now = datetime.now(timezone.utc)
        status = WorkerStatus(
            worker_id="worker-1",
            status="idle",
            current_job_id=None,
            jobs_completed=3,
            last_heartbeat=now,
            provider="verda",
            gpu_memory_used=4096,
            gpu_memory_total=81920
        )
        assert status.gpu_memory_used == 4096
        assert status.gpu_memory_total == 81920


class TestDatetimeSerialization:
    """Test datetime serialization in models"""

    def test_job_datetime_serialization(self, sample_job):
        """Test that datetime is properly serialized"""
        json_str = sample_job.model_dump_json()
        data = json.loads(json_str)
        # Should be ISO format string
        assert isinstance(data["created_at"], str)
        assert "T" in data["created_at"]  # ISO format has 'T'

    def test_job_response_datetime_serialization(self, sample_job):
        """Test that JobResponse datetime is serialized"""
        response = JobResponse(
            id=sample_job.id,
            user_id=sample_job.user_id,
            status=sample_job.status,
            priority=sample_job.priority,
            created_at=sample_job.created_at,
            started_at=None,
            completed_at=None,
            worker_id=None,
            result=None,
            error=None
        )
        json_str = response.model_dump_json()
        data = json.loads(json_str)
        assert isinstance(data["created_at"], str)
