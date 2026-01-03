"""
Queue Manager - FastAPI Application
Main entrypoint for the job queue management service
"""
import logging
import asyncio
from datetime import datetime
from typing import List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from models import (
    Job, JobSubmitRequest, JobResponse, QueueStatus,
    HealthCheck, JobStatus, QueueMode, JobPriority
)
from config import settings
from redis_client import RedisClient
from websocket_manager import WebSocketManager

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.log_level),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Global instances
redis_client: Optional[RedisClient] = None
ws_manager: Optional[WebSocketManager] = None
app_start_time: datetime = datetime.utcnow()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    global redis_client, ws_manager

    # Startup
    logger.info(f"Starting {settings.app_name} v{settings.app_version}")
    redis_client = RedisClient()
    ws_manager = WebSocketManager(redis_client)

    # Start background tasks
    asyncio.create_task(cleanup_task())

    logger.info("Queue Manager started successfully")

    yield

    # Shutdown
    logger.info("Shutting down Queue Manager")


# Initialize FastAPI app
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    lifespan=lifespan
)

# CORS middleware - Security: Only allow specific origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://comfy.ahelme.net",
        "https://www.comfy.ahelme.net",
        "http://localhost:8080",  # For local admin dashboard testing
    ],
    allow_credentials=False,  # Disabled for security - no cookies needed
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
)


# ============================================================================
# Health & Status Endpoints
# ============================================================================

@app.get("/health", response_model=HealthCheck)
async def health_check():
    """Health check endpoint"""
    uptime = (datetime.utcnow() - app_start_time).total_seconds()

    return HealthCheck(
        status="healthy" if redis_client.ping() else "unhealthy",
        version=settings.app_version,
        redis_connected=redis_client.ping(),
        workers_active=0,  # TODO: Track active workers
        queue_depth=redis_client.get_queue_depth(),
        uptime_seconds=int(uptime)
    )


@app.get("/api/queue/status", response_model=QueueStatus)
async def get_queue_status():
    """Get overall queue status"""
    try:
        return QueueStatus(
            mode=QueueMode(settings.queue_mode),
            pending_jobs=redis_client.get_queue_depth(redis_client.QUEUE_PENDING),
            running_jobs=redis_client.get_queue_depth(redis_client.QUEUE_RUNNING),
            completed_jobs=redis_client.get_queue_depth(redis_client.QUEUE_COMPLETED),
            failed_jobs=redis_client.get_queue_depth(redis_client.QUEUE_FAILED),
            total_workers=settings.num_workers,
            active_workers=0,  # TODO: Implement worker tracking
            queue_depth=redis_client.get_queue_depth(redis_client.QUEUE_PENDING)
        )
    except Exception as e:
        logger.error(f"Failed to get queue status: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# Job Management Endpoints
# ============================================================================

@app.post("/api/jobs", response_model=JobResponse, status_code=201)
async def submit_job(request: JobSubmitRequest):
    """Submit a new job to the queue"""
    try:
        # Check queue depth limit
        if settings.max_queue_depth > 0:
            current_depth = redis_client.get_queue_depth()
            if current_depth >= settings.max_queue_depth:
                raise HTTPException(
                    status_code=429,
                    detail=f"Queue is full (max depth: {settings.max_queue_depth})"
                )

        # Create job
        job = Job(
            user_id=request.user_id,
            workflow=request.workflow,
            priority=request.priority,
            metadata=request.metadata
        )

        # Save to Redis
        if not redis_client.create_job(job):
            raise HTTPException(status_code=500, detail="Failed to create job")

        # Get queue position
        pending_jobs = redis_client.get_pending_jobs()
        position = next((i for i, j in enumerate(pending_jobs) if j.id == job.id), None)

        logger.info(f"Job {job.id} submitted by user {job.user_id}")

        return JobResponse(
            id=job.id,
            user_id=job.user_id,
            status=job.status,
            priority=job.priority,
            created_at=job.created_at,
            started_at=None,
            completed_at=None,
            worker_id=None,
            result=None,
            error=None,
            position_in_queue=position
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to submit job: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/jobs/{job_id}", response_model=JobResponse)
async def get_job(job_id: str):
    """Get job status by ID"""
    try:
        job = redis_client.get_job(job_id)
        if not job:
            raise HTTPException(status_code=404, detail="Job not found")

        # Calculate position in queue if pending
        position = None
        if job.status == JobStatus.PENDING:
            pending_jobs = redis_client.get_pending_jobs()
            position = next((i for i, j in enumerate(pending_jobs) if j.id == job_id), None)

        return JobResponse(
            id=job.id,
            user_id=job.user_id,
            status=job.status,
            priority=job.priority,
            created_at=job.created_at,
            started_at=job.started_at,
            completed_at=job.completed_at,
            worker_id=job.worker_id,
            result=job.result,
            error=job.error,
            position_in_queue=position
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get job {job_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/jobs", response_model=List[JobResponse])
async def list_jobs(
    user_id: Optional[str] = None,
    status: Optional[JobStatus] = None,
    limit: int = 100
):
    """List jobs with optional filters"""
    try:
        if user_id:
            jobs = redis_client.get_user_jobs(user_id)
        else:
            # Get from all queues
            jobs = redis_client.get_pending_jobs(limit)
            # TODO: Add running, completed, failed

        # Filter by status if specified
        if status:
            jobs = [j for j in jobs if j.status == status]

        # Convert to response models
        responses = []
        for job in jobs[:limit]:
            position = None
            if job.status == JobStatus.PENDING:
                pending_jobs = redis_client.get_pending_jobs()
                position = next((i for i, j in enumerate(pending_jobs) if j.id == job.id), None)

            responses.append(JobResponse(
                id=job.id,
                user_id=job.user_id,
                status=job.status,
                priority=job.priority,
                created_at=job.created_at,
                started_at=job.started_at,
                completed_at=job.completed_at,
                worker_id=job.worker_id,
                result=job.result,
                error=job.error,
                position_in_queue=position
            ))

        return responses

    except Exception as e:
        logger.error(f"Failed to list jobs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/api/jobs/{job_id}", status_code=204)
async def cancel_job(job_id: str):
    """Cancel a job"""
    try:
        job = redis_client.get_job(job_id)
        if not job:
            raise HTTPException(status_code=404, detail="Job not found")

        if job.status == JobStatus.RUNNING:
            # Mark as cancelled, worker will handle cleanup
            job.status = JobStatus.CANCELLED
            redis_client.update_job(job)
            logger.info(f"Job {job_id} marked for cancellation")
        elif job.status == JobStatus.PENDING:
            # Remove from queue
            redis_client.delete_job(job_id)
            logger.info(f"Job {job_id} cancelled and removed from queue")
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot cancel job in {job.status} state"
            )

        return None

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to cancel job {job_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.patch("/api/jobs/{job_id}/priority")
async def update_job_priority(job_id: str, priority: JobPriority):
    """Update job priority (admin/instructor only)"""
    try:
        job = redis_client.get_job(job_id)
        if not job:
            raise HTTPException(status_code=404, detail="Job not found")

        if job.status != JobStatus.PENDING:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot change priority of {job.status} job"
            )

        # Update priority
        job.priority = priority
        redis_client.update_job(job)

        # Re-score in queue
        score = redis_client._get_priority_score(job)
        redis_client.redis.zadd(redis_client.QUEUE_PENDING, {job_id: score})

        logger.info(f"Updated job {job_id} priority to {priority}")

        return {"status": "success", "job_id": job_id, "priority": priority}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update job {job_id} priority: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# Worker Endpoints
# ============================================================================

@app.get("/api/workers/next-job")
async def get_next_job(worker_id: str):
    """Get next job for worker to process"""
    try:
        # Update worker heartbeat
        redis_client.update_worker_heartbeat(worker_id)

        # Get next job based on queue mode
        queue_mode = QueueMode(settings.queue_mode)
        job = redis_client.get_next_job(queue_mode)

        if not job:
            return {"job": None}

        # Move to running
        redis_client.move_job_to_running(job.id, worker_id)

        logger.info(f"Assigned job {job.id} to worker {worker_id}")

        return {
            "job": {
                "id": job.id,
                "workflow": job.workflow,
                "user_id": job.user_id,
                "metadata": job.metadata
            }
        }

    except Exception as e:
        logger.error(f"Failed to get next job for worker {worker_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/workers/complete-job")
async def complete_job(job_id: str, result: dict):
    """Mark job as completed"""
    try:
        if not redis_client.move_job_to_completed(job_id, result):
            raise HTTPException(status_code=404, detail="Job not found")

        logger.info(f"Job {job_id} completed")
        return {"status": "success"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to complete job {job_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/workers/fail-job")
async def fail_job(job_id: str, error: str):
    """Mark job as failed"""
    try:
        if not redis_client.move_job_to_failed(job_id, error):
            raise HTTPException(status_code=404, detail="Job not found")

        logger.error(f"Job {job_id} failed: {error}")
        return {"status": "success"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to mark job {job_id} as failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# WebSocket Endpoint
# ============================================================================

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time updates"""
    await ws_manager.connect(websocket)
    try:
        while True:
            # Keep connection alive and handle incoming messages
            data = await websocket.receive_text()
            # Echo back for ping/pong
            await websocket.send_text(f"pong: {data}")
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
        logger.info("WebSocket client disconnected")


# ============================================================================
# Background Tasks
# ============================================================================

async def cleanup_task():
    """Background task to cleanup stale jobs"""
    while True:
        try:
            await asyncio.sleep(60)  # Run every minute
            redis_client.cleanup_stale_jobs(settings.job_timeout)
        except Exception as e:
            logger.error(f"Cleanup task error: {e}")


# ============================================================================
# Error Handlers
# ============================================================================

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        log_level=settings.log_level.lower(),
        reload=settings.debug
    )
