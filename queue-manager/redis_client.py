"""
Redis client for job queue management
"""
import json
import logging
from typing import Optional, List, Dict, Any
from datetime import datetime
from redis import Redis
from redis.exceptions import RedisError
from models import Job, JobStatus, QueueMode
from config import settings

logger = logging.getLogger(__name__)


class RedisClient:
    """Redis client wrapper for job queue operations"""

    # Redis key patterns
    JOB_KEY = "job:{job_id}"
    QUEUE_PENDING = "queue:pending"
    QUEUE_RUNNING = "queue:running"
    QUEUE_COMPLETED = "queue:completed"
    QUEUE_FAILED = "queue:failed"
    USER_JOBS = "user:{user_id}:jobs"
    USER_COMPLETED_COUNT = "user:{user_id}:completed"
    WORKER_STATUS = "worker:{worker_id}:status"
    WORKER_HEARTBEAT = "worker:{worker_id}:heartbeat"
    PUBSUB_CHANNEL = "queue:updates"

    def __init__(self):
        """Initialize Redis connection"""
        self.redis = Redis(
            host=settings.redis_host,
            port=settings.redis_port,
            password=settings.redis_password,
            db=settings.redis_db,
            decode_responses=True,
            socket_connect_timeout=5,
            socket_keepalive=True,
            health_check_interval=30
        )
        logger.info(f"Connected to Redis at {settings.redis_host}:{settings.redis_port}")

    def ping(self) -> bool:
        """Check Redis connection"""
        try:
            return self.redis.ping()
        except RedisError as e:
            logger.error(f"Redis ping failed: {e}")
            return False

    # ========================================================================
    # Job Operations
    # ========================================================================

    def create_job(self, job: Job) -> bool:
        """Create a new job and add to pending queue"""
        try:
            job_key = self.JOB_KEY.format(job_id=job.id)
            job_data = job.model_dump_json()

            # Store job data
            self.redis.set(job_key, job_data)

            # Add to pending queue with priority score
            score = self._get_priority_score(job)
            self.redis.zadd(self.QUEUE_PENDING, {job.id: score})

            # Track user jobs
            user_jobs_key = self.USER_JOBS.format(user_id=job.user_id)
            self.redis.sadd(user_jobs_key, job.id)

            # Publish event
            self._publish_event("job_created", job.model_dump())

            logger.info(f"Created job {job.id} for user {job.user_id}")
            return True

        except RedisError as e:
            logger.error(f"Failed to create job {job.id}: {e}")
            return False

    def get_job(self, job_id: str) -> Optional[Job]:
        """Retrieve job by ID"""
        try:
            job_key = self.JOB_KEY.format(job_id=job_id)
            job_data = self.redis.get(job_key)

            if job_data:
                return Job.model_validate_json(job_data)
            return None

        except (RedisError, ValueError) as e:
            logger.error(f"Failed to get job {job_id}: {e}")
            return None

    def update_job(self, job: Job) -> bool:
        """Update job data"""
        try:
            job_key = self.JOB_KEY.format(job_id=job.id)
            job_data = job.model_dump_json()
            self.redis.set(job_key, job_data)

            # Publish update event
            self._publish_event("job_updated", job.model_dump())

            logger.debug(f"Updated job {job.id}")
            return True

        except RedisError as e:
            logger.error(f"Failed to update job {job.id}: {e}")
            return False

    def delete_job(self, job_id: str) -> bool:
        """Delete a job"""
        try:
            job = self.get_job(job_id)
            if not job:
                return False

            # Remove from all queues
            self.redis.zrem(self.QUEUE_PENDING, job_id)
            self.redis.zrem(self.QUEUE_RUNNING, job_id)
            self.redis.zrem(self.QUEUE_COMPLETED, job_id)
            self.redis.zrem(self.QUEUE_FAILED, job_id)

            # Remove from user jobs
            user_jobs_key = self.USER_JOBS.format(user_id=job.user_id)
            self.redis.srem(user_jobs_key, job_id)

            # Delete job data
            job_key = self.JOB_KEY.format(job_id=job_id)
            self.redis.delete(job_key)

            # Publish event
            self._publish_event("job_deleted", {"job_id": job_id})

            logger.info(f"Deleted job {job_id}")
            return True

        except RedisError as e:
            logger.error(f"Failed to delete job {job_id}: {e}")
            return False

    # ========================================================================
    # Queue Operations
    # ========================================================================

    def get_next_job(self, queue_mode: QueueMode = QueueMode.FIFO) -> Optional[Job]:
        """Get next job from queue based on mode"""
        try:
            if queue_mode == QueueMode.FIFO or queue_mode == QueueMode.PRIORITY:
                # Get job with lowest score (highest priority / earliest)
                result = self.redis.zpopmin(self.QUEUE_PENDING)
                if result:
                    job_id = result[0][0]
                    return self.get_job(job_id)

            elif queue_mode == QueueMode.ROUND_ROBIN:
                # Get user with fewest completed jobs
                job_id = self._get_round_robin_job()
                if job_id:
                    self.redis.zrem(self.QUEUE_PENDING, job_id)
                    return self.get_job(job_id)

            return None

        except RedisError as e:
            logger.error(f"Failed to get next job: {e}")
            return None

    def move_job_to_running(self, job_id: str, worker_id: str) -> bool:
        """Move job from pending to running"""
        try:
            job = self.get_job(job_id)
            if not job:
                return False

            job.status = JobStatus.RUNNING
            job.started_at = datetime.utcnow()
            job.worker_id = worker_id

            self.update_job(job)

            # Move between queues
            score = datetime.utcnow().timestamp()
            self.redis.zadd(self.QUEUE_RUNNING, {job_id: score})

            logger.info(f"Job {job_id} started by worker {worker_id}")
            return True

        except RedisError as e:
            logger.error(f"Failed to move job {job_id} to running: {e}")
            return False

    def move_job_to_completed(self, job_id: str, result: Dict[str, Any]) -> bool:
        """Move job from running to completed"""
        try:
            job = self.get_job(job_id)
            if not job:
                return False

            job.status = JobStatus.COMPLETED
            job.completed_at = datetime.utcnow()
            job.result = result

            self.update_job(job)

            # Move between queues
            self.redis.zrem(self.QUEUE_RUNNING, job_id)
            score = datetime.utcnow().timestamp()
            self.redis.zadd(self.QUEUE_COMPLETED, {job_id: score})

            # Increment user completed count
            user_count_key = self.USER_COMPLETED_COUNT.format(user_id=job.user_id)
            self.redis.incr(user_count_key)

            logger.info(f"Job {job_id} completed")
            return True

        except RedisError as e:
            logger.error(f"Failed to move job {job_id} to completed: {e}")
            return False

    def move_job_to_failed(self, job_id: str, error: str) -> bool:
        """Move job from running to failed"""
        try:
            job = self.get_job(job_id)
            if not job:
                return False

            job.status = JobStatus.FAILED
            job.completed_at = datetime.utcnow()
            job.error = error

            self.update_job(job)

            # Move between queues
            self.redis.zrem(self.QUEUE_RUNNING, job_id)
            score = datetime.utcnow().timestamp()
            self.redis.zadd(self.QUEUE_FAILED, {job_id: score})

            logger.error(f"Job {job_id} failed: {error}")
            return True

        except RedisError as e:
            logger.error(f"Failed to move job {job_id} to failed: {e}")
            return False

    def get_queue_depth(self, queue: str = QUEUE_PENDING) -> int:
        """Get number of jobs in queue"""
        try:
            return self.redis.zcard(queue)
        except RedisError as e:
            logger.error(f"Failed to get queue depth: {e}")
            return 0

    def get_pending_jobs(self, limit: int = 100) -> List[Job]:
        """Get list of pending jobs"""
        try:
            job_ids = self.redis.zrange(self.QUEUE_PENDING, 0, limit - 1)
            jobs = []
            for job_id in job_ids:
                job = self.get_job(job_id)
                if job:
                    jobs.append(job)
            return jobs
        except RedisError as e:
            logger.error(f"Failed to get pending jobs: {e}")
            return []

    def get_user_jobs(self, user_id: str) -> List[Job]:
        """Get all jobs for a user"""
        try:
            user_jobs_key = self.USER_JOBS.format(user_id=user_id)
            job_ids = self.redis.smembers(user_jobs_key)
            jobs = []
            for job_id in job_ids:
                job = self.get_job(job_id)
                if job:
                    jobs.append(job)
            return jobs
        except RedisError as e:
            logger.error(f"Failed to get user jobs for {user_id}: {e}")
            return []

    # ========================================================================
    # Worker Operations
    # ========================================================================

    def update_worker_heartbeat(self, worker_id: str) -> bool:
        """Update worker heartbeat timestamp"""
        try:
            key = self.WORKER_HEARTBEAT.format(worker_id=worker_id)
            self.redis.setex(key, settings.worker_heartbeat_timeout, datetime.utcnow().isoformat())
            return True
        except RedisError as e:
            logger.error(f"Failed to update worker heartbeat for {worker_id}: {e}")
            return False

    def is_worker_alive(self, worker_id: str) -> bool:
        """Check if worker is alive based on heartbeat"""
        try:
            key = self.WORKER_HEARTBEAT.format(worker_id=worker_id)
            return self.redis.exists(key) > 0
        except RedisError as e:
            logger.error(f"Failed to check worker heartbeat for {worker_id}: {e}")
            return False

    # ========================================================================
    # Pub/Sub Operations
    # ========================================================================

    def _publish_event(self, event_type: str, data: Dict[str, Any]) -> None:
        """Publish event to pub/sub channel"""
        try:
            message = {
                "type": event_type,
                "data": data,
                "timestamp": datetime.utcnow().isoformat()
            }
            self.redis.publish(self.PUBSUB_CHANNEL, json.dumps(message))
        except RedisError as e:
            logger.error(f"Failed to publish event {event_type}: {e}")

    def subscribe_to_updates(self):
        """Subscribe to queue updates"""
        pubsub = self.redis.pubsub()
        pubsub.subscribe(self.PUBSUB_CHANNEL)
        return pubsub

    # ========================================================================
    # Helper Methods
    # ========================================================================

    def _get_priority_score(self, job: Job) -> float:
        """Calculate priority score for job (lower = higher priority)"""
        # Priority level (0-3) * 1000000 + timestamp
        # This ensures priority takes precedence, then FIFO within priority
        priority_weight = job.priority.value * 1000000
        timestamp = job.created_at.timestamp()
        return priority_weight + timestamp

    def _get_round_robin_job(self) -> Optional[str]:
        """Get next job using round-robin logic"""
        try:
            # Get all pending jobs
            pending_job_ids = self.redis.zrange(self.QUEUE_PENDING, 0, -1)
            if not pending_job_ids:
                return None

            # Group jobs by user and count completed jobs per user
            user_jobs: Dict[str, List[str]] = {}
            for job_id in pending_job_ids:
                job = self.get_job(job_id)
                if job:
                    if job.user_id not in user_jobs:
                        user_jobs[job.user_id] = []
                    user_jobs[job.user_id].append(job_id)

            # Find user with fewest completed jobs
            min_completed = float('inf')
            selected_user = None

            for user_id in user_jobs.keys():
                count_key = self.USER_COMPLETED_COUNT.format(user_id=user_id)
                completed = int(self.redis.get(count_key) or 0)
                if completed < min_completed:
                    min_completed = completed
                    selected_user = user_id

            # Return first job from selected user
            if selected_user and user_jobs[selected_user]:
                return user_jobs[selected_user][0]

            return None

        except RedisError as e:
            logger.error(f"Failed to get round-robin job: {e}")
            return None

    def cleanup_stale_jobs(self, timeout_seconds: int = 3600) -> int:
        """Cleanup jobs that have been running too long"""
        try:
            cutoff = datetime.utcnow().timestamp() - timeout_seconds
            stale_job_ids = self.redis.zrangebyscore(self.QUEUE_RUNNING, 0, cutoff)

            count = 0
            for job_id in stale_job_ids:
                self.move_job_to_failed(job_id, "Job timeout exceeded")
                count += 1

            if count > 0:
                logger.warning(f"Cleaned up {count} stale jobs")

            return count

        except RedisError as e:
            logger.error(f"Failed to cleanup stale jobs: {e}")
            return 0
