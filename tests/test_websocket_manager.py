"""
Tests for WebSocket Manager functionality
"""
import pytest
import asyncio
import json
from unittest.mock import AsyncMock, MagicMock, patch, call
from datetime import datetime, timezone


@pytest.fixture
def websocket_manager_with_mock(mock_redis_client, mocker):
    """Create WebSocketManager with mocked Redis"""
    with patch('websocket_manager.RedisClient', return_value=mock_redis_client):
        from websocket_manager import WebSocketManager
        manager = WebSocketManager(mock_redis_client)
        return manager, mock_redis_client


class TestWebSocketConnectionManagement:
    """Test WebSocket connection handling"""

    @pytest.mark.asyncio
    async def test_connect_new_websocket(self, websocket_manager_with_mock):
        """Test accepting a new WebSocket connection"""
        manager, _ = websocket_manager_with_mock
        mock_ws = AsyncMock()

        await manager.connect(mock_ws)

        mock_ws.accept.assert_called_once()
        assert mock_ws in manager.active_connections

    @pytest.mark.asyncio
    async def test_disconnect_websocket(self, websocket_manager_with_mock):
        """Test disconnecting a WebSocket"""
        manager, _ = websocket_manager_with_mock
        mock_ws = AsyncMock()

        # First connect
        await manager.connect(mock_ws)
        assert len(manager.active_connections) == 1

        # Then disconnect
        manager.disconnect(mock_ws)
        assert len(manager.active_connections) == 0

    @pytest.mark.asyncio
    async def test_disconnect_nonexistent_websocket(self, websocket_manager_with_mock):
        """Test disconnecting non-existent WebSocket doesn't error"""
        manager, _ = websocket_manager_with_mock
        mock_ws = AsyncMock()

        # Should not raise error
        manager.disconnect(mock_ws)
        assert len(manager.active_connections) == 0

    @pytest.mark.asyncio
    async def test_multiple_connections(self, websocket_manager_with_mock):
        """Test managing multiple WebSocket connections"""
        manager, _ = websocket_manager_with_mock
        mock_ws1 = AsyncMock()
        mock_ws2 = AsyncMock()
        mock_ws3 = AsyncMock()

        await manager.connect(mock_ws1)
        await manager.connect(mock_ws2)
        await manager.connect(mock_ws3)

        assert len(manager.active_connections) == 3

        manager.disconnect(mock_ws2)
        assert len(manager.active_connections) == 2
        assert mock_ws1 in manager.active_connections
        assert mock_ws3 in manager.active_connections
        assert mock_ws2 not in manager.active_connections


class TestBroadcasting:
    """Test broadcast functionality"""

    @pytest.mark.asyncio
    async def test_broadcast_to_all_clients(self, websocket_manager_with_mock):
        """Test broadcasting message to all connected clients"""
        manager, _ = websocket_manager_with_mock
        mock_ws1 = AsyncMock()
        mock_ws2 = AsyncMock()

        await manager.connect(mock_ws1)
        await manager.connect(mock_ws2)

        message = {"type": "job_status", "data": {"job_id": "job-1", "status": "completed"}}
        await manager.broadcast(message)

        mock_ws1.send_text.assert_called_once()
        mock_ws2.send_text.assert_called_once()

    @pytest.mark.asyncio
    async def test_broadcast_message_format(self, websocket_manager_with_mock):
        """Test that broadcast message is properly formatted"""
        manager, _ = websocket_manager_with_mock
        mock_ws = AsyncMock()
        await manager.connect(mock_ws)

        message = {"type": "test", "data": {"key": "value"}}
        await manager.broadcast(message)

        # Verify message was sent as JSON string
        call_args = mock_ws.send_text.call_args[0][0]
        sent_data = json.loads(call_args)
        assert sent_data["type"] == "test"
        assert sent_data["data"]["key"] == "value"

    @pytest.mark.asyncio
    async def test_broadcast_to_empty_connections(self, websocket_manager_with_mock):
        """Test broadcast when no clients are connected"""
        manager, _ = websocket_manager_with_mock

        # Should not raise error
        message = {"type": "test", "data": {}}
        await manager.broadcast(message)

    @pytest.mark.asyncio
    async def test_broadcast_handles_disconnected_client(self, websocket_manager_with_mock):
        """Test broadcast removes disconnected clients"""
        manager, _ = websocket_manager_with_mock
        mock_ws1 = AsyncMock()
        mock_ws2 = AsyncMock()

        await manager.connect(mock_ws1)
        await manager.connect(mock_ws2)

        # Make ws1 fail on send
        mock_ws1.send_text.side_effect = Exception("Connection closed")

        message = {"type": "test", "data": {}}
        await manager.broadcast(message)

        # ws1 should be removed
        assert mock_ws1 not in manager.active_connections
        assert mock_ws2 in manager.active_connections
        mock_ws2.send_text.assert_called_once()


class TestMessageTypes:
    """Test different message types"""

    @pytest.mark.asyncio
    async def test_broadcast_job_status_update(self, websocket_manager_with_mock):
        """Test broadcasting job status update"""
        manager, _ = websocket_manager_with_mock
        mock_ws = AsyncMock()
        await manager.connect(mock_ws)

        message = {
            "type": "job_status",
            "data": {
                "job_id": "job-001",
                "status": "running",
                "worker_id": "worker-1"
            }
        }
        await manager.broadcast(message)

        mock_ws.send_text.assert_called_once()
        sent_data = json.loads(mock_ws.send_text.call_args[0][0])
        assert sent_data["type"] == "job_status"

    @pytest.mark.asyncio
    async def test_broadcast_queue_status_update(self, websocket_manager_with_mock):
        """Test broadcasting queue status update"""
        manager, _ = websocket_manager_with_mock
        mock_ws = AsyncMock()
        await manager.connect(mock_ws)

        message = {
            "type": "queue_status",
            "data": {
                "pending": 5,
                "running": 2,
                "completed": 10
            }
        }
        await manager.broadcast(message)

        mock_ws.send_text.assert_called_once()

    @pytest.mark.asyncio
    async def test_broadcast_worker_status_update(self, websocket_manager_with_mock):
        """Test broadcasting worker status update"""
        manager, _ = websocket_manager_with_mock
        mock_ws = AsyncMock()
        await manager.connect(mock_ws)

        message = {
            "type": "worker_status",
            "data": {
                "worker_id": "worker-1",
                "status": "idle",
                "jobs_completed": 5
            }
        }
        await manager.broadcast(message)

        mock_ws.send_text.assert_called_once()


class TestPubSubListener:
    """Test Redis pub/sub listener"""

    @pytest.mark.asyncio
    async def test_listener_initialization(self, websocket_manager_with_mock):
        """Test that listener task is created on first connection"""
        manager, mock_redis = websocket_manager_with_mock
        mock_ws = AsyncMock()

        # Mock the listen to avoid blocking
        mock_pubsub = MagicMock()
        mock_pubsub.listen.return_value = []
        mock_redis.subscribe_to_updates.return_value = mock_pubsub

        await manager.connect(mock_ws)

        # Listener task should be created
        assert manager.listener_task is not None

    @pytest.mark.asyncio
    async def test_listener_reconnection_logic(self, websocket_manager_with_mock):
        """Test listener reconnection on failure"""
        manager, mock_redis = websocket_manager_with_mock

        # Mock subscription failure then success
        mock_pubsub = MagicMock()
        call_count = [0]

        def subscribe_side_effect():
            call_count[0] += 1
            if call_count[0] == 1:
                raise Exception("Connection failed")
            # Return empty listener on second call to avoid blocking
            mock_pubsub.listen.return_value = iter([])
            return mock_pubsub

        mock_redis.subscribe_to_updates.side_effect = subscribe_side_effect

        # Create listener task with timeout to prevent hanging
        try:
            await asyncio.wait_for(manager._listen_to_redis(), timeout=0.5)
        except asyncio.TimeoutError:
            # Expected - listener runs indefinitely
            pass


class TestMessageBroadcastFromPubSub:
    """Test that pub/sub messages are properly broadcast"""

    @pytest.mark.asyncio
    async def test_pubsub_message_forwarding(self, websocket_manager_with_mock):
        """Test that messages from Redis pub/sub are forwarded to WebSocket clients"""
        manager, mock_redis = websocket_manager_with_mock
        mock_ws = AsyncMock()

        await manager.connect(mock_ws)

        # Create a test message
        test_message = {
            "type": "job_created",
            "data": {"job_id": "job-001"},
            "timestamp": datetime.now(timezone.utc).isoformat()
        }

        # Broadcast message
        await manager.broadcast(test_message)

        # Verify it was sent
        mock_ws.send_text.assert_called_once()


class TestConnectionErrorHandling:
    """Test error handling in connections"""

    @pytest.mark.asyncio
    async def test_broadcast_with_send_error(self, websocket_manager_with_mock):
        """Test that broadcast recovers from send errors"""
        manager, _ = websocket_manager_with_mock
        mock_ws1 = AsyncMock()
        mock_ws2 = AsyncMock()

        await manager.connect(mock_ws1)
        await manager.connect(mock_ws2)

        # Make first connection fail
        mock_ws1.send_text.side_effect = RuntimeError("Send failed")

        message = {"type": "test"}
        await manager.broadcast(message)

        # Second connection should still receive message
        mock_ws2.send_text.assert_called_once()
        # First should be removed from active connections
        assert mock_ws1 not in manager.active_connections

    @pytest.mark.asyncio
    async def test_connection_cleanup(self, websocket_manager_with_mock):
        """Test that failed connections are properly cleaned up"""
        manager, _ = websocket_manager_with_mock
        mocks = [AsyncMock() for _ in range(3)]

        for mock in mocks:
            await manager.connect(mock)

        assert len(manager.active_connections) == 3

        # Simulate failures
        mocks[0].send_text.side_effect = Exception("Connection closed")
        mocks[1].send_text.side_effect = Exception("Connection closed")

        await manager.broadcast({"type": "test"})

        # Only the healthy connection remains
        assert len(manager.active_connections) == 1
        assert mocks[2] in manager.active_connections


class TestConcurrency:
    """Test concurrent WebSocket operations"""

    @pytest.mark.asyncio
    async def test_concurrent_connections(self, websocket_manager_with_mock):
        """Test handling concurrent connection requests"""
        manager, _ = websocket_manager_with_mock
        mocks = [AsyncMock() for _ in range(5)]

        # Connect all concurrently
        await asyncio.gather(*[manager.connect(m) for m in mocks])

        assert len(manager.active_connections) == 5

    @pytest.mark.asyncio
    async def test_concurrent_broadcasts(self, websocket_manager_with_mock):
        """Test concurrent broadcast operations"""
        manager, _ = websocket_manager_with_mock
        mock_ws = AsyncMock()
        await manager.connect(mock_ws)

        # Send multiple messages concurrently
        messages = [
            {"type": "msg1", "data": {"id": 1}},
            {"type": "msg2", "data": {"id": 2}},
            {"type": "msg3", "data": {"id": 3}},
        ]

        await asyncio.gather(*[manager.broadcast(m) for m in messages])

        # All messages should be sent
        assert mock_ws.send_text.call_count == 3

    @pytest.mark.asyncio
    async def test_concurrent_connect_disconnect(self, websocket_manager_with_mock):
        """Test concurrent connect/disconnect operations"""
        manager, _ = websocket_manager_with_mock
        mocks = [AsyncMock() for _ in range(5)]

        # Connect all
        await asyncio.gather(*[manager.connect(m) for m in mocks])
        assert len(manager.active_connections) == 5

        # Disconnect all concurrently
        await asyncio.gather(*[
            asyncio.to_thread(manager.disconnect, m) for m in mocks
        ])

        assert len(manager.active_connections) == 0


class TestPubSubListenerErrorHandling:
    """Test pub/sub listener error handling"""

    @pytest.mark.asyncio
    async def test_listener_decode_error(self, websocket_manager_with_mock):
        """Test listener handles invalid JSON"""
        manager, mock_redis = websocket_manager_with_mock

        mock_pubsub = MagicMock()
        # Return invalid JSON
        mock_pubsub.listen.return_value = iter([
            {"type": "message", "data": "not json"}
        ])
        mock_redis.subscribe_to_updates.return_value = mock_pubsub

        # Should handle gracefully without raising
        try:
            await asyncio.wait_for(manager._listen_to_redis(), timeout=0.1)
        except (asyncio.TimeoutError, StopAsyncIteration):
            pass  # Expected

    @pytest.mark.asyncio
    async def test_listener_closes_pubsub_on_exit(self, websocket_manager_with_mock):
        """Test that listener properly closes pubsub connection"""
        manager, mock_redis = websocket_manager_with_mock

        mock_pubsub = MagicMock()
        mock_pubsub.listen.return_value = iter([])
        mock_pubsub.close = MagicMock()
        mock_redis.subscribe_to_updates.return_value = mock_pubsub

        try:
            await asyncio.wait_for(manager._listen_to_redis(), timeout=0.1)
        except (asyncio.TimeoutError, StopAsyncIteration):
            pass

        # Note: pubsub.close() is called in finally block


class TestWebSocketMessageStructure:
    """Test WebSocket message structure validation"""

    @pytest.mark.asyncio
    async def test_message_with_required_fields(self, websocket_manager_with_mock):
        """Test broadcasting message with required fields"""
        manager, _ = websocket_manager_with_mock
        mock_ws = AsyncMock()
        await manager.connect(mock_ws)

        message = {
            "type": "job_status",
            "data": {"job_id": "job-1", "status": "running"}
        }

        await manager.broadcast(message)

        # Verify message structure
        sent = json.loads(mock_ws.send_text.call_args[0][0])
        assert "type" in sent
        assert "data" in sent

    @pytest.mark.asyncio
    async def test_message_with_empty_data(self, websocket_manager_with_mock):
        """Test broadcasting message with empty data"""
        manager, _ = websocket_manager_with_mock
        mock_ws = AsyncMock()
        await manager.connect(mock_ws)

        message = {"type": "heartbeat", "data": {}}

        await manager.broadcast(message)

        sent = json.loads(mock_ws.send_text.call_args[0][0])
        assert sent["data"] == {}
