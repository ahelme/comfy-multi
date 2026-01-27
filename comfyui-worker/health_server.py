#!/usr/bin/env python3
"""
Health Check Server for Serverless Containers
Provides /health endpoint for Verda liveness checks
"""
import os
import logging
import httpx
from fastapi import FastAPI
from pydantic import BaseModel

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration
HEALTH_PORT = int(os.getenv("HEALTH_PORT", "8000"))
COMFYUI_URL = os.getenv("COMFYUI_URL", "http://localhost:8188")
QUEUE_MANAGER_URL = os.getenv("QUEUE_MANAGER_URL", "http://queue-manager:3000")

app = FastAPI(title="ComfyUI Worker Health Check")


class HealthResponse(BaseModel):
    status: str
    comfyui_ready: bool
    queue_manager_reachable: bool
    worker_ready: bool


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """
    Health check endpoint for serverless container liveness probes
    Returns 200 if worker is ready to accept jobs
    """
    comfyui_ready = False
    queue_manager_reachable = False

    # Check ComfyUI availability
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{COMFYUI_URL}/system_stats")
            comfyui_ready = response.status_code == 200
    except Exception as e:
        logger.warning(f"ComfyUI health check failed: {e}")

    # Check Queue Manager connectivity
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{QUEUE_MANAGER_URL}/health")
            queue_manager_reachable = response.status_code == 200
    except Exception as e:
        logger.warning(f"Queue Manager health check failed: {e}")

    # Worker is ready if both ComfyUI and Queue Manager are available
    worker_ready = comfyui_ready and queue_manager_reachable

    return HealthResponse(
        status="healthy" if worker_ready else "unhealthy",
        comfyui_ready=comfyui_ready,
        queue_manager_reachable=queue_manager_reachable,
        worker_ready=worker_ready
    )


@app.get("/")
async def root():
    """Root endpoint"""
    return {"service": "ComfyUI Worker Health Check", "version": "1.0.0"}


if __name__ == "__main__":
    import uvicorn
    logger.info(f"Starting health server on port {HEALTH_PORT}")
    logger.info(f"ComfyUI URL: {COMFYUI_URL}")
    logger.info(f"Queue Manager URL: {QUEUE_MANAGER_URL}")
    uvicorn.run(app, host="0.0.0.0", port=HEALTH_PORT)
