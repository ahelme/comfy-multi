"""
Pytest configuration and fixtures for Queue Manager tests
"""
import pytest
import asyncio
import json
from datetime import datetime, timezone
from unittest.mock import Mock, AsyncMock, MagicMock, patch
from typing import Optional, Dict, Any
import sys
import os

# Set test environment before imports
os.environ.setdefault("REDIS_PASSWORD", "test")
os.environ.setdefault("REDIS_HOST", "localhost")
os.environ.setdefault("REDIS_PORT", "6379")
os.environ["DOTENV_PATH"] = "/dev/null"  # Disable .env loading

# Add queue-manager to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'queue-manager'))

from models import (
    Job, JobStatus, JobPriority, QueueMode,
    JobSubmitRequest, JobCompletionRequest, JobFailureRequest
)

# Create a test-safe Settings class
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Application settings for testing - allows extra fields from .env"""
    # Redis Configuration
    redis_host: str = "redis"
    redis_port: int = 6379
    redis_password: str
    redis_db: int = 0

    # Queue Configuration
    queue_mode: str = "fifo"
    enable_priority: bool = True
    job_timeout: int = 3600
    max_queue_depth: int = 100

    # Inference Provider
    inference_provider: str = "local"
    num_workers: int = 1

    # Server Configuration
    host: str = "0.0.0.0"
    port: int = 3000
    log_level: str = "INFO"
    debug: bool = False

    # Worker Configuration
    worker_heartbeat_timeout: int = 60
    worker_poll_interval: int = 1

    # Storage paths
    outputs_path: str = "/outputs"
    inputs_path: str = "/inputs"

    # Application metadata
    app_name: str = "ComfyUI Queue Manager"
    app_version: str = "0.1.0"

    class Config:
        env_file = None  # Don't load .env
        extra = "ignore"  # Ignore extra fields
        case_sensitive = False


@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for async tests"""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
def mock_settings(monkeypatch):
    """Mock Settings object"""
    # Prevent loading from .env file
    monkeypatch.delenv("REDIS_HOST", raising=False)
    monkeypatch.delenv("REDIS_PORT", raising=False)
    monkeypatch.delenv("REDIS_PASSWORD", raising=False)

    settings = Settings(
        redis_host="localhost",
        redis_port=6379,
        redis_password="testpass",
        redis_db=0,
        queue_mode="fifo",
        job_timeout=3600,
        max_queue_depth=100,
        num_workers=2,
        worker_heartbeat_timeout=60,
        debug=True,
        _env_file=None  # Don't load from .env
    )
    return settings


@pytest.fixture
def sample_job():
    """Create a sample job for testing"""
    return Job(
        id="job-001",
        user_id="user-1",
        workflow={"nodes": [{"id": "1", "type": "LoadImage", "pos": [0, 0]}]},
        status=JobStatus.PENDING,
        priority=JobPriority.NORMAL,
        metadata={"session_id": "sess-001"}
    )


@pytest.fixture
def sample_workflow():
    """Create a sample ComfyUI workflow"""
    return {
        "nodes": [
            {
                "id": "1",
                "type": "CheckpointLoaderSimple",
                "pos": [0, 0],
                "size": [300, 60],
                "flags": {},
                "order": 0,
                "mode": 0,
                "outputs": ["CLIP", "CONDITIONING"],
                "title": "Load Checkpoint",
                "properties": {},
                "widgets_values": ["model.safetensors"]
            },
            {
                "id": "2",
                "type": "PrimitiveNode",
                "pos": [320, 20],
                "size": [320, 60],
                "flags": {},
                "order": 1,
                "mode": 0,
                "outputs": [],
                "title": "Steps",
                "properties": {},
                "widgets_values": [20]
            }
        ],
        "groups": [],
        "config": {},
        "version": 0.4
    }


@pytest.fixture
def job_submit_request(sample_workflow):
    """Create a job submission request"""
    return JobSubmitRequest(
        user_id="user-1",
        workflow=sample_workflow,
        priority=JobPriority.NORMAL,
        metadata={"session_id": "sess-001"}
    )


@pytest.fixture
def job_completion_request():
    """Create a job completion request"""
    return JobCompletionRequest(
        result={
            "status": "success",
            "outputs": ["image_001.png", "image_002.png"],
            "execution_time": 120.5
        }
    )


@pytest.fixture
def job_failure_request():
    """Create a job failure request"""
    return JobFailureRequest(
        error="CUDA out of memory: tried to allocate 8.00 GiB"
    )


@pytest.fixture
def mock_redis_client(mocker):
    """Mock Redis client"""
    mock = MagicMock()
    mock.ping.return_value = True
    mock.create_job.return_value = True
    mock.get_job.return_value = None
    mock.update_job.return_value = True
    mock.delete_job.return_value = True
    mock.get_queue_depth.return_value = 0
    mock.get_all_queue_stats.return_value = {
        "pending": 0,
        "running": 0,
        "completed": 0,
        "failed": 0
    }
    mock.get_pending_jobs.return_value = []
    mock.get_user_jobs.return_value = []
    mock.move_job_to_running.return_value = True
    mock.move_job_to_completed.return_value = True
    mock.move_job_to_failed.return_value = True
    mock.update_worker_heartbeat.return_value = True
    mock.is_worker_alive.return_value = True
    mock.get_next_job.return_value = None
    mock._publish_event = MagicMock()
    mock._get_priority_score.return_value = 2000020.0
    mock.redis = MagicMock()
    mock.redis.zadd = MagicMock()
    mock.redis.zrem = MagicMock()
    mock.redis.zpopmin = MagicMock(return_value=[])

    return mock


@pytest.fixture
def mock_ws_manager(mock_redis_client):
    """Mock WebSocket Manager"""
    mock = MagicMock()
    mock.redis_client = mock_redis_client
    mock.active_connections = []
    mock.broadcast = AsyncMock()
    mock.connect = AsyncMock()
    mock.disconnect = MagicMock()

    return mock


@pytest.fixture
def multiple_jobs():
    """Create multiple sample jobs"""
    jobs = []
    for i in range(5):
        job = Job(
            id=f"job-{i:03d}",
            user_id=f"user-{i % 3}",
            workflow={"nodes": [{"id": "1", "type": "test"}]},
            status=JobStatus.PENDING,
            priority=JobPriority.NORMAL if i % 2 == 0 else JobPriority.HIGH,
            metadata={"index": i}
        )
        jobs.append(job)
    return jobs


@pytest.fixture
def job_with_result(sample_job):
    """Job with completion result"""
    job = sample_job.copy()
    job.status = JobStatus.COMPLETED
    job.completed_at = datetime.now(timezone.utc)
    job.result = {"output": "image.png", "execution_time": 45.2}
    return job


@pytest.fixture
def job_with_error(sample_job):
    """Job with error"""
    job = sample_job.copy()
    job.status = JobStatus.FAILED
    job.completed_at = datetime.now(timezone.utc)
    job.error = "CUDA out of memory"
    return job


@pytest.fixture
def mock_fastapi_app(mocker, mock_redis_client, mock_ws_manager):
    """Mock FastAPI app with injected dependencies"""
    from fastapi import FastAPI
    from fastapi.testclient import TestClient

    app = FastAPI()

    # Store mocked dependencies in app.state
    app.state.redis_client = mock_redis_client
    app.state.ws_manager = mock_ws_manager

    return TestClient(app)


@pytest.fixture(params=[QueueMode.FIFO, QueueMode.ROUND_ROBIN, QueueMode.PRIORITY])
def queue_modes(request):
    """Parametrized fixture for queue modes"""
    return request.param


@pytest.fixture(params=[JobPriority.LOW, JobPriority.NORMAL, JobPriority.HIGH, JobPriority.INSTRUCTOR])
def job_priorities(request):
    """Parametrized fixture for job priorities"""
    return request.param


@pytest.fixture(params=[JobStatus.PENDING, JobStatus.RUNNING, JobStatus.COMPLETED, JobStatus.FAILED])
def job_statuses(request):
    """Parametrized fixture for job statuses"""
    return request.param
