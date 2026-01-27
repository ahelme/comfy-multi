#!/usr/bin/env python3
"""
ComfyUI Worker - Polls queue and executes workflows on GPU
"""
import os
import sys
import time
import json
import logging
import signal
from typing import Optional, Dict, Any
from datetime import datetime, timezone
import httpx
from redis import Redis
from redis.exceptions import RedisError

# Configure structured logging with JSON support
LOG_FORMAT = os.getenv("LOG_FORMAT", "text")  # "text" or "json"

if LOG_FORMAT == "json":
    try:
        from pythonjsonlogger import jsonlogger

        logHandler = logging.StreamHandler()
        formatter = jsonlogger.JsonFormatter(
            '%(asctime)s %(name)s %(levelname)s %(message)s',
            timestamp=True
        )
        logHandler.setFormatter(formatter)
        logging.basicConfig(
            level=logging.INFO,
            handlers=[logHandler]
        )
    except ImportError:
        # Fall back to text format if pythonjsonlogger not installed
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
else:
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

logger = logging.getLogger(__name__)

# Configuration from environment
WORKER_ID = os.getenv("WORKER_ID", "worker-1")
REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", "")
QUEUE_MANAGER_URL = os.getenv("QUEUE_MANAGER_URL", "http://queue-manager:3000")
COMFYUI_URL = os.getenv("COMFYUI_URL", "http://localhost:8188")
POLL_INTERVAL = int(os.getenv("WORKER_POLL_INTERVAL", "2"))
OUTPUTS_PATH = os.getenv("OUTPUTS_PATH", "/outputs")

# Timeout configurations (configurable via environment)
COMFYUI_TIMEOUT = int(os.getenv("COMFYUI_TIMEOUT", "300"))  # 5 minutes for ComfyUI requests
HTTP_CLIENT_TIMEOUT = int(os.getenv("HTTP_CLIENT_TIMEOUT", "30"))  # 30 seconds for queue manager

# Serverless mode configuration
SERVERLESS_MODE = os.getenv("SERVERLESS_MODE", "false").lower() == "true"
SERVERLESS_MAX_IDLE_POLLS = int(os.getenv("SERVERLESS_MAX_IDLE_POLLS", "10"))  # Exit after N empty polls
SERVERLESS_JOB_LIMIT = int(os.getenv("SERVERLESS_JOB_LIMIT", "0"))  # Max jobs before exit (0=unlimited)
INFERENCE_PROVIDER = os.getenv("INFERENCE_PROVIDER", "local")  # local, verda-instance, verda-serverless

# Graceful shutdown flag
shutdown_requested = False


def signal_handler(signum, frame):
    """Handle shutdown signals"""
    global shutdown_requested
    logger.info(f"Received signal {signum}, initiating graceful shutdown...")
    shutdown_requested = True


class ComfyUIClient:
    """Client for interacting with ComfyUI API"""

    def __init__(self, base_url: str = COMFYUI_URL):
        self.base_url = base_url.rstrip('/')
        self.client = httpx.Client(timeout=float(COMFYUI_TIMEOUT))
        logger.info(f"ComfyUI client initialized for {base_url} (timeout={COMFYUI_TIMEOUT}s)")

    def queue_prompt(self, workflow: Dict[str, Any]) -> Optional[str]:
        """Submit workflow to ComfyUI"""
        try:
            response = self.client.post(
                f"{self.base_url}/prompt",
                json={"prompt": workflow}
            )
            response.raise_for_status()
            data = response.json()
            prompt_id = data.get("prompt_id")
            logger.info(f"Workflow queued with prompt_id: {prompt_id}")
            return prompt_id

        except Exception as e:
            logger.error(f"Failed to queue workflow: {e}")
            return None

    def get_history(self, prompt_id: str) -> Optional[Dict[str, Any]]:
        """Get workflow execution history"""
        try:
            response = self.client.get(f"{self.base_url}/history/{prompt_id}")
            response.raise_for_status()
            data = response.json()
            return data.get(prompt_id)

        except Exception as e:
            logger.error(f"Failed to get history for {prompt_id}: {e}")
            return None

    def wait_for_completion(self, prompt_id: str, timeout: int = 3600) -> Dict[str, Any]:
        """Wait for workflow to complete and return results"""
        start_time = time.time()

        while True:
            if time.time() - start_time > timeout:
                raise TimeoutError(f"Workflow {prompt_id} exceeded timeout of {timeout}s")

            history = self.get_history(prompt_id)
            if history:
                status = history.get("status", {})

                if status.get("completed", False):
                    logger.info(f"Workflow {prompt_id} completed successfully")
                    return {
                        "prompt_id": prompt_id,
                        "status": "completed",
                        "outputs": history.get("outputs", {}),
                        "execution_time": time.time() - start_time
                    }

                if "error" in status:
                    error_msg = status.get("error", "Unknown error")
                    logger.error(f"Workflow {prompt_id} failed: {error_msg}")
                    raise RuntimeError(f"Workflow execution failed: {error_msg}")

            time.sleep(2)  # Poll every 2 seconds

    def close(self):
        """Close HTTP client"""
        self.client.close()


class Worker:
    """Main worker class"""

    def __init__(self):
        self.worker_id = WORKER_ID
        self.queue_manager_url = QUEUE_MANAGER_URL
        self.comfyui = ComfyUIClient()
        self.http_client = httpx.Client(timeout=float(HTTP_CLIENT_TIMEOUT))
        self.jobs_completed = 0
        self.jobs_failed = 0
        self.start_time = datetime.now(timezone.utc)

        # Serverless mode tracking
        self.serverless_mode = SERVERLESS_MODE
        self.idle_poll_count = 0
        self.max_idle_polls = SERVERLESS_MAX_IDLE_POLLS
        self.job_limit = SERVERLESS_JOB_LIMIT
        self.provider = INFERENCE_PROVIDER

        logger.info(f"Worker {self.worker_id} initialized (http_timeout={HTTP_CLIENT_TIMEOUT}s)")
        logger.info(f"Provider: {self.provider}, Serverless Mode: {self.serverless_mode}")
        if self.serverless_mode:
            logger.info(f"Serverless config: max_idle_polls={self.max_idle_polls}, job_limit={self.job_limit}")

    def get_next_job(self) -> Optional[Dict[str, Any]]:
        """Get next job from queue manager"""
        try:
            response = self.http_client.get(
                f"{self.queue_manager_url}/api/workers/next-job",
                params={"worker_id": self.worker_id}
            )
            response.raise_for_status()
            data = response.json()
            return data.get("job")

        except Exception as e:
            logger.error(f"Failed to get next job: {e}")
            return None

    def complete_job(self, job_id: str, result: Dict[str, Any]) -> bool:
        """Mark job as completed"""
        try:
            response = self.http_client.post(
                f"{self.queue_manager_url}/api/workers/complete-job",
                params={"job_id": job_id},
                json=result
            )
            response.raise_for_status()
            logger.info(f"Job {job_id} marked as completed")
            return True

        except Exception as e:
            logger.error(f"Failed to mark job {job_id} as completed: {e}")
            return False

    def fail_job(self, job_id: str, error: str) -> bool:
        """Mark job as failed"""
        try:
            response = self.http_client.post(
                f"{self.queue_manager_url}/api/workers/fail-job",
                params={"job_id": job_id, "error": error}
            )
            response.raise_for_status()
            logger.error(f"Job {job_id} marked as failed: {error}")
            return True

        except Exception as e:
            logger.error(f"Failed to mark job {job_id} as failed: {e}")
            return False

    def process_job(self, job: Dict[str, Any]) -> bool:
        """Process a single job"""
        job_id = job.get("id")
        workflow = job.get("workflow")
        user_id = job.get("user_id")

        logger.info(f"Processing job {job_id} for user {user_id}")

        try:
            # Submit workflow to ComfyUI
            prompt_id = self.comfyui.queue_prompt(workflow)
            if not prompt_id:
                raise RuntimeError("Failed to queue workflow in ComfyUI")

            # Wait for completion
            result = self.comfyui.wait_for_completion(prompt_id)

            # Save outputs to user directory
            user_output_dir = os.path.join(OUTPUTS_PATH, user_id)
            os.makedirs(user_output_dir, exist_ok=True)

            result["output_path"] = user_output_dir
            result["timestamp"] = datetime.now(timezone.utc).isoformat()

            # Mark job as completed
            self.complete_job(job_id, result)
            self.jobs_completed += 1

            logger.info(f"Job {job_id} completed successfully")
            return True

        except Exception as e:
            error_msg = str(e)
            logger.error(f"Job {job_id} failed: {error_msg}")

            # Mark job as failed
            self.fail_job(job_id, error_msg)
            self.jobs_failed += 1

            return False

    def run(self):
        """Main worker loop"""
        logger.info(f"Worker {self.worker_id} started")
        logger.info(f"Queue Manager: {self.queue_manager_url}")
        logger.info(f"ComfyUI: {self.comfyui.base_url}")
        logger.info(f"Poll interval: {POLL_INTERVAL}s")

        # Register signal handlers
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)

        while not shutdown_requested:
            try:
                # Check serverless job limit
                if self.serverless_mode and self.job_limit > 0:
                    if self.jobs_completed >= self.job_limit:
                        logger.info(f"Serverless job limit reached ({self.jobs_completed}/{self.job_limit}), exiting")
                        break

                # Get next job
                job = self.get_next_job()

                if job:
                    # Reset idle counter on job found
                    self.idle_poll_count = 0

                    # Process job
                    self.process_job(job)
                else:
                    # No jobs available
                    self.idle_poll_count += 1
                    logger.debug(f"No jobs available, sleeping for {POLL_INTERVAL}s (idle polls: {self.idle_poll_count})")

                    # Check serverless idle timeout
                    if self.serverless_mode and self.idle_poll_count >= self.max_idle_polls:
                        logger.info(f"Serverless idle timeout reached ({self.idle_poll_count} empty polls), exiting")
                        break

                    time.sleep(POLL_INTERVAL)

            except KeyboardInterrupt:
                logger.info("Keyboard interrupt received")
                break
            except Exception as e:
                logger.error(f"Unexpected error in worker loop: {e}")
                time.sleep(POLL_INTERVAL)

        # Shutdown
        self.shutdown()

    def shutdown(self):
        """Graceful shutdown"""
        logger.info("Worker shutting down...")
        logger.info(f"Total jobs completed: {self.jobs_completed}")
        logger.info(f"Total jobs failed: {self.jobs_failed}")

        uptime = (datetime.now(timezone.utc) - self.start_time).total_seconds()
        logger.info(f"Uptime: {uptime:.0f}s")

        self.comfyui.close()
        self.http_client.close()

        logger.info("Worker shutdown complete")


if __name__ == "__main__":
    try:
        worker = Worker()
        worker.run()
    except Exception as e:
        logger.critical(f"Worker failed to start: {e}")
        sys.exit(1)
