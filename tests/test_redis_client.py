"""
Tests for Redis client operations
"""
import pytest
import json
from datetime import datetime, timezone
from unittest.mock import MagicMock, patch, call
from redis.exceptions import RedisError

from models import Job, JobStatus, JobPriority, QueueMode


# We'll use a mock redis instead of fakeredis for more control
@pytest.fixture
def redis_client_with_mock(mocker):
    """Create a RedisClient with mocked Redis connection"""
    mock_redis = MagicMock()

    with patch('redis_client.Redis', return_value=mock_redis):
        from redis_client import RedisClient
        client = RedisClient()
        return client, mock_redis


class TestRedisClientConnection:
    """Test Redis client connection"""

    def test_redis_client_initialization(self, mock_settings, mocker):
        """Test RedisClient initialization"""
        mock_redis = MagicMock()
        with patch('redis_client.Redis', return_value=mock_redis):
            from redis_client import RedisClient
            client = RedisClient()
            assert client.redis is not None

    def test_ping_success(self, redis_client_with_mock):
        """Test successful Redis ping"""
        client, mock_redis = redis_client_with_mock
        mock_redis.ping.return_value = True

        result = client.ping()
        assert result is True
        mock_redis.ping.assert_called_once()

    def test_ping_failure(self, redis_client_with_mock):
        """Test Redis ping failure"""
        client, mock_redis = redis_client_with_mock
        mock_redis.ping.side_effect = RedisError("Connection failed")

        result = client.ping()
        assert result is False


class TestJobCRUDOperations:
    """Test Job CRUD operations"""

    def test_create_job_success(self, redis_client_with_mock, sample_job):
        """Test successful job creation"""
        client, mock_redis = redis_client_with_mock
        mock_redis.set.return_value = True
        mock_redis.zadd.return_value = 1
        mock_redis.sadd.return_value = 1

        result = client.create_job(sample_job)
        assert result is True

        # Verify Redis calls
        mock_redis.set.assert_called_once()
        mock_redis.zadd.assert_called_once()
        mock_redis.sadd.assert_called_once()

    def test_create_job_redis_error(self, redis_client_with_mock, sample_job):
        """Test job creation with Redis error"""
        client, mock_redis = redis_client_with_mock
        mock_redis.set.side_effect = RedisError("Connection error")

        result = client.create_job(sample_job)
        assert result is False

    def test_get_job_success(self, redis_client_with_mock, sample_job):
        """Test successful job retrieval"""
        client, mock_redis = redis_client_with_mock
        job_json = sample_job.model_dump_json()
        mock_redis.get.return_value = job_json

        result = client.get_job(sample_job.id)
        assert result is not None
        assert result.id == sample_job.id

    def test_get_job_not_found(self, redis_client_with_mock):
        """Test job retrieval when not found"""
        client, mock_redis = redis_client_with_mock
        mock_redis.get.return_value = None

        result = client.get_job("nonexistent-id")
        assert result is None

    def test_get_job_invalid_json(self, redis_client_with_mock):
        """Test job retrieval with invalid JSON"""
        client, mock_redis = redis_client_with_mock
        mock_redis.get.return_value = "invalid json"

        result = client.get_job("job-id")
        assert result is None

    def test_update_job_success(self, redis_client_with_mock, sample_job):
        """Test successful job update"""
        client, mock_redis = redis_client_with_mock
        mock_redis.set.return_value = True

        sample_job.status = JobStatus.RUNNING
        result = client.update_job(sample_job)
        assert result is True
        mock_redis.set.assert_called_once()

    def test_delete_job_success(self, redis_client_with_mock, sample_job):
        """Test successful job deletion"""
        client, mock_redis = redis_client_with_mock
        job_json = sample_job.model_dump_json()
        mock_redis.get.return_value = job_json
        mock_redis.zrem.return_value = 1
        mock_redis.srem.return_value = 1
        mock_redis.delete.return_value = 1

        result = client.delete_job(sample_job.id)
        assert result is True

        # Verify all queues were cleared
        assert mock_redis.zrem.call_count >= 4

    def test_delete_job_not_found(self, redis_client_with_mock):
        """Test deletion of nonexistent job"""
        client, mock_redis = redis_client_with_mock
        mock_redis.get.return_value = None

        result = client.delete_job("nonexistent-id")
        assert result is False


class TestQueueOperations:
    """Test queue operations"""

    def test_get_queue_depth(self, redis_client_with_mock):
        """Test getting queue depth"""
        client, mock_redis = redis_client_with_mock
        mock_redis.zcard.return_value = 5

        depth = client.get_queue_depth()
        assert depth == 5

    def test_get_queue_depth_error(self, redis_client_with_mock):
        """Test queue depth with error"""
        client, mock_redis = redis_client_with_mock
        mock_redis.zcard.side_effect = RedisError("Connection error")

        depth = client.get_queue_depth()
        assert depth == 0

    def test_get_all_queue_stats(self, redis_client_with_mock):
        """Test getting all queue stats"""
        client, mock_redis = redis_client_with_mock
        # Mock pipeline
        pipe = MagicMock()
        pipe.execute.return_value = [5, 2, 10, 1]  # pending, running, completed, failed
        mock_redis.pipeline.return_value = pipe

        stats = client.get_all_queue_stats()
        assert stats["pending"] == 5
        assert stats["running"] == 2
        assert stats["completed"] == 10
        assert stats["failed"] == 1

    def test_get_pending_jobs(self, redis_client_with_mock, sample_job):
        """Test getting pending jobs"""
        client, mock_redis = redis_client_with_mock
        mock_redis.zrange.return_value = [sample_job.id]
        job_json = sample_job.model_dump_json()
        mock_redis.get.return_value = job_json

        jobs = client.get_pending_jobs(limit=10)
        assert len(jobs) == 1
        assert jobs[0].id == sample_job.id

    def test_get_user_jobs(self, redis_client_with_mock, sample_job):
        """Test getting jobs for a user"""
        client, mock_redis = redis_client_with_mock
        mock_redis.smembers.return_value = {sample_job.id}
        job_json = sample_job.model_dump_json()
        mock_redis.get.return_value = job_json

        jobs = client.get_user_jobs("user-1")
        assert len(jobs) == 1
        assert jobs[0].user_id == "user-1"


class TestJobStateTransitions:
    """Test job state transitions"""

    def test_move_job_to_running(self, redis_client_with_mock, sample_job):
        """Test moving job to running state"""
        client, mock_redis = redis_client_with_mock
        job_json = sample_job.model_dump_json()
        mock_redis.get.return_value = job_json
        mock_redis.set.return_value = True
        mock_redis.zadd.return_value = 1

        result = client.move_job_to_running(sample_job.id, "worker-1")
        assert result is True

    def test_move_job_to_completed(self, redis_client_with_mock, sample_job):
        """Test moving job to completed state"""
        client, mock_redis = redis_client_with_mock
        job_json = sample_job.model_dump_json()
        mock_redis.get.return_value = job_json
        mock_redis.set.return_value = True
        mock_redis.zrem.return_value = 1
        mock_redis.zadd.return_value = 1
        mock_redis.incr.return_value = 1

        result = client.move_job_to_completed(sample_job.id, {"result": "data"})
        assert result is True
        # Should increment user completed count
        mock_redis.incr.assert_called_once()

    def test_move_job_to_failed(self, redis_client_with_mock, sample_job):
        """Test moving job to failed state"""
        client, mock_redis = redis_client_with_mock
        job_json = sample_job.model_dump_json()
        mock_redis.get.return_value = job_json
        mock_redis.set.return_value = True
        mock_redis.zrem.return_value = 1
        mock_redis.zadd.return_value = 1

        result = client.move_job_to_failed(sample_job.id, "Error message")
        assert result is True

    def test_move_job_nonexistent(self, redis_client_with_mock):
        """Test moving nonexistent job"""
        client, mock_redis = redis_client_with_mock
        mock_redis.get.return_value = None

        result = client.move_job_to_running("nonexistent", "worker-1")
        assert result is False


class TestQueueModes:
    """Test different queue modes"""

    @pytest.mark.asyncio
    async def test_get_next_job_fifo_mode(self, redis_client_with_mock, sample_job):
        """Test FIFO mode next job selection"""
        client, mock_redis = redis_client_with_mock
        # zpopmin returns list of tuples: [(job_id, score)]
        mock_redis.zpopmin.return_value = [(sample_job.id, 0)]
        job_json = sample_job.model_dump_json()
        mock_redis.get.return_value = job_json

        job = client.get_next_job(QueueMode.FIFO)
        assert job is not None
        assert job.id == sample_job.id

    @pytest.mark.asyncio
    async def test_get_next_job_fifo_no_jobs(self, redis_client_with_mock):
        """Test FIFO mode with no jobs"""
        client, mock_redis = redis_client_with_mock
        mock_redis.zpopmin.return_value = []

        job = client.get_next_job(QueueMode.FIFO)
        assert job is None

    @pytest.mark.asyncio
    async def test_get_next_job_priority_mode(self, redis_client_with_mock, sample_job):
        """Test PRIORITY mode next job selection"""
        client, mock_redis = redis_client_with_mock
        mock_redis.zpopmin.return_value = [(sample_job.id, 0)]
        job_json = sample_job.model_dump_json()
        mock_redis.get.return_value = job_json

        job = client.get_next_job(QueueMode.PRIORITY)
        assert job is not None


class TestWorkerHeartbeat:
    """Test worker heartbeat operations"""

    def test_update_worker_heartbeat(self, redis_client_with_mock):
        """Test updating worker heartbeat"""
        client, mock_redis = redis_client_with_mock
        mock_redis.setex.return_value = True

        result = client.update_worker_heartbeat("worker-1")
        assert result is True
        mock_redis.setex.assert_called_once()

    def test_is_worker_alive_true(self, redis_client_with_mock):
        """Test worker alive check when alive"""
        client, mock_redis = redis_client_with_mock
        mock_redis.exists.return_value = 1

        result = client.is_worker_alive("worker-1")
        assert result is True

    def test_is_worker_alive_false(self, redis_client_with_mock):
        """Test worker alive check when dead"""
        client, mock_redis = redis_client_with_mock
        mock_redis.exists.return_value = 0

        result = client.is_worker_alive("worker-1")
        assert result is False


class TestPriorityScoring:
    """Test priority scoring logic"""

    def test_priority_score_ordering(self, redis_client_with_mock):
        """Test that priority scores are correctly ordered"""
        client, _ = redis_client_with_mock

        # Create jobs with different priorities
        base_time = datetime.now(timezone.utc).timestamp()

        job_low = Job(user_id="user", workflow={"test": 1}, priority=JobPriority.LOW)
        job_normal = Job(user_id="user", workflow={"test": 1}, priority=JobPriority.NORMAL)
        job_high = Job(user_id="user", workflow={"test": 1}, priority=JobPriority.HIGH)
        job_instructor = Job(user_id="user", workflow={"test": 1}, priority=JobPriority.INSTRUCTOR)

        score_low = client._get_priority_score(job_low)
        score_normal = client._get_priority_score(job_normal)
        score_high = client._get_priority_score(job_high)
        score_instructor = client._get_priority_score(job_instructor)

        # Lower score = higher priority (selected first)
        assert score_instructor < score_high < score_normal < score_low


class TestCleanupOperations:
    """Test cleanup operations"""

    def test_cleanup_stale_jobs(self, redis_client_with_mock):
        """Test cleanup of stale jobs"""
        client, mock_redis = redis_client_with_mock
        old_job_id = "old-job-1"
        mock_redis.zrangebyscore.return_value = [old_job_id]
        job_data = {
            "id": old_job_id,
            "user_id": "user-1",
            "workflow": {},
            "status": "running",
            "priority": 2,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "started_at": None,
            "completed_at": None,
            "worker_id": None,
            "result": None,
            "error": None,
            "metadata": {}
        }
        job_json = json.dumps(job_data)
        mock_redis.get.return_value = job_json
        mock_redis.set.return_value = True
        mock_redis.zrem.return_value = 1
        mock_redis.zadd.return_value = 1

        count = client.cleanup_stale_jobs(timeout_seconds=3600)
        assert count == 1


class TestPubSubOperations:
    """Test pub/sub operations"""

    def test_publish_event(self, redis_client_with_mock):
        """Test publishing event"""
        client, mock_redis = redis_client_with_mock
        mock_redis.publish.return_value = 1

        client._publish_event("job_created", {"job_id": "job-1"})
        mock_redis.publish.assert_called_once()

    def test_subscribe_to_updates(self, redis_client_with_mock):
        """Test subscribing to updates"""
        client, mock_redis = redis_client_with_mock
        mock_pubsub = MagicMock()
        mock_redis.pubsub.return_value = mock_pubsub

        pubsub = client.subscribe_to_updates()
        assert pubsub == mock_pubsub
        mock_pubsub.subscribe.assert_called_once()


class TestAtomicOperations:
    """Test atomic operations for race condition prevention"""

    def test_move_job_atomic(self, redis_client_with_mock, sample_job):
        """Test that job moves are atomic"""
        client, mock_redis = redis_client_with_mock
        job_json = sample_job.model_dump_json()
        mock_redis.get.return_value = job_json
        mock_redis.set.return_value = True
        mock_redis.zadd.return_value = 1

        # Verify zpopmin is used (atomic operation)
        mock_redis.zpopmin.return_value = [(sample_job.id, 0)]
        job = client.get_next_job(QueueMode.FIFO)

        # zpopmin should be called (atomic pop)
        mock_redis.zpopmin.assert_called_once()
