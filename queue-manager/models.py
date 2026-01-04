"""
Data models for the Queue Manager
"""
import re
import json
from datetime import datetime
from enum import Enum
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field, field_validator
from uuid import uuid4


# Constants for payload size limits
MAX_WORKFLOW_SIZE_BYTES = 10 * 1024 * 1024  # 10MB
MAX_METADATA_SIZE_BYTES = 1 * 1024 * 1024   # 1MB
MAX_RESULT_SIZE_BYTES = 50 * 1024 * 1024     # 50MB
MAX_ERROR_MESSAGE_LENGTH = 10000


class JobStatus(str, Enum):
    """Job execution status"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class QueueMode(str, Enum):
    """Queue scheduling mode"""
    FIFO = "fifo"  # First In, First Out
    ROUND_ROBIN = "round_robin"  # Fair distribution per user
    PRIORITY = "priority"  # Priority-based (with fallback to FIFO)


class JobPriority(int, Enum):
    """Job priority levels (lower number = higher priority)"""
    INSTRUCTOR = 0  # Instructor override
    HIGH = 1
    NORMAL = 2
    LOW = 3


class Job(BaseModel):
    """Job model representing a ComfyUI workflow execution"""
    id: str = Field(default_factory=lambda: str(uuid4()))
    user_id: str = Field(..., description="User who submitted the job")
    workflow: Dict[str, Any] = Field(..., description="ComfyUI workflow JSON")
    status: JobStatus = Field(default=JobStatus.PENDING)
    priority: JobPriority = Field(default=JobPriority.NORMAL)

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    # Execution details
    worker_id: Optional[str] = None
    result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

    # Metadata
    metadata: Dict[str, Any] = Field(default_factory=dict)

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class JobSubmitRequest(BaseModel):
    """Request model for job submission"""
    user_id: str = Field(..., description="User submitting the job", min_length=1, max_length=100)
    workflow: Dict[str, Any] = Field(..., description="ComfyUI workflow JSON")
    priority: JobPriority = Field(default=JobPriority.NORMAL)
    metadata: Dict[str, Any] = Field(default_factory=dict)

    @field_validator('user_id')
    @classmethod
    def validate_user_id(cls, v: str) -> str:
        """Validate user_id format to prevent path traversal and command injection"""
        # Only allow alphanumeric, underscore, and hyphen (no dots, slashes, etc.)
        if not re.match(r'^[a-zA-Z0-9_-]{1,100}$', v):
            raise ValueError(
                "user_id must contain only alphanumeric characters, underscores, and hyphens (1-100 chars)"
            )
        # Prevent path traversal
        if '..' in v or '/' in v or '\\' in v:
            raise ValueError("user_id cannot contain path traversal sequences")
        return v

    @field_validator('workflow')
    @classmethod
    def validate_workflow(cls, v: Dict[str, Any]) -> Dict[str, Any]:
        """Validate workflow size and structure"""
        # Check workflow is not empty
        if not v or not isinstance(v, dict):
            raise ValueError("workflow must be a non-empty dictionary")

        # Check workflow size (prevent DoS via large payloads)
        workflow_json = json.dumps(v)
        workflow_size = len(workflow_json)

        if workflow_size > MAX_WORKFLOW_SIZE_BYTES:
            raise ValueError(
                f"workflow size ({workflow_size} bytes) exceeds maximum ({MAX_WORKFLOW_SIZE_BYTES} bytes)"
            )

        return v

    @field_validator('metadata')
    @classmethod
    def validate_metadata(cls, v: Dict[str, Any]) -> Dict[str, Any]:
        """Validate metadata size"""
        if not v:
            return v

        # Limit metadata size to prevent abuse
        metadata_json = json.dumps(v)
        metadata_size = len(metadata_json)

        if metadata_size > MAX_METADATA_SIZE_BYTES:
            raise ValueError(
                f"metadata size ({metadata_size} bytes) exceeds maximum ({MAX_METADATA_SIZE_BYTES} bytes)"
            )

        return v


class JobCompletionRequest(BaseModel):
    """Request model for job completion (worker endpoint)"""
    result: Dict[str, Any] = Field(..., description="Execution result payload")

    @field_validator('result')
    @classmethod
    def validate_result_size(cls, v: Dict[str, Any]) -> Dict[str, Any]:
        """Limit result payload size to prevent Redis memory exhaustion"""
        if not isinstance(v, dict):
            raise ValueError("result must be a dictionary")

        result_json = json.dumps(v)
        result_size = len(result_json)

        if result_size > MAX_RESULT_SIZE_BYTES:
            raise ValueError(
                f"result payload too large ({result_size} bytes) - exceeds {MAX_RESULT_SIZE_BYTES} bytes"
            )

        return v


class JobFailureRequest(BaseModel):
    """Request model for job failure (worker endpoint)"""
    error: str = Field(
        ...,
        min_length=1,
        max_length=MAX_ERROR_MESSAGE_LENGTH,
        description="Error message"
    )

    @field_validator('error')
    @classmethod
    def validate_error_message(cls, v: str) -> str:
        """Ensure error message is reasonable"""
        if not v or not v.strip():
            raise ValueError("error message cannot be empty")
        return v.strip()


class JobResponse(BaseModel):
    """Response model for job queries"""
    id: str
    user_id: str
    status: JobStatus
    priority: JobPriority
    created_at: datetime
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    worker_id: Optional[str]
    result: Optional[Dict[str, Any]]
    error: Optional[str]
    position_in_queue: Optional[int] = None
    estimated_wait_time: Optional[int] = None  # seconds


class QueueStatus(BaseModel):
    """Overall queue status"""
    mode: QueueMode
    pending_jobs: int
    running_jobs: int
    completed_jobs: int
    failed_jobs: int
    total_workers: int
    active_workers: int
    queue_depth: int


class WorkerStatus(BaseModel):
    """Worker status information"""
    worker_id: str
    status: str  # idle, busy, offline
    current_job_id: Optional[str] = None
    jobs_completed: int
    last_heartbeat: datetime
    provider: InferenceProvider
    gpu_memory_used: Optional[int] = None  # MB
    gpu_memory_total: Optional[int] = None  # MB


class WebSocketMessage(BaseModel):
    """WebSocket message format for real-time updates"""
    type: str  # job_status, queue_status, worker_status
    data: Dict[str, Any]
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class HealthCheck(BaseModel):
    """Health check response"""
    status: str
    version: str
    redis_connected: bool
    workers_active: int
    queue_depth: int
    uptime_seconds: int
