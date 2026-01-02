"""
Data models for the Queue Manager
"""
from datetime import datetime
from enum import Enum
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field
from uuid import uuid4


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


class InferenceProvider(str, Enum):
    """Supported inference providers"""
    LOCAL = "local"
    VERDA = "verda"
    RUNPOD = "runpod"
    MODAL = "modal"


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
    user_id: str = Field(..., description="User submitting the job")
    workflow: Dict[str, Any] = Field(..., description="ComfyUI workflow JSON")
    priority: JobPriority = Field(default=JobPriority.NORMAL)
    metadata: Dict[str, Any] = Field(default_factory=dict)


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
