"""
WebSocket Manager for real-time queue updates
"""
import json
import logging
import asyncio
from typing import List, Set
from fastapi import WebSocket
from redis_client import RedisClient

logger = logging.getLogger(__name__)


class WebSocketManager:
    """Manages WebSocket connections and broadcasts queue updates"""

    def __init__(self, redis_client: RedisClient):
        self.redis_client = redis_client
        self.active_connections: List[WebSocket] = []
        self.pubsub = None
        self.listener_task = None

    async def connect(self, websocket: WebSocket):
        """Accept new WebSocket connection"""
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(f"WebSocket connected. Total connections: {len(self.active_connections)}")

        # Start listener if not already running
        if not self.listener_task:
            self.listener_task = asyncio.create_task(self._listen_to_redis())

    def disconnect(self, websocket: WebSocket):
        """Remove WebSocket connection"""
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        logger.info(f"WebSocket disconnected. Total connections: {len(self.active_connections)}")

    async def broadcast(self, message: dict):
        """Broadcast message to all connected clients"""
        if not self.active_connections:
            return

        message_str = json.dumps(message)
        disconnected = []

        for connection in self.active_connections:
            try:
                await connection.send_text(message_str)
            except Exception as e:
                logger.error(f"Failed to send to WebSocket: {e}")
                disconnected.append(connection)

        # Remove disconnected clients
        for connection in disconnected:
            self.disconnect(connection)

    async def _listen_to_redis(self):
        """
        Listen to Redis pub/sub and broadcast updates.
        Implements automatic reconnection with exponential backoff.
        """
        max_retries = 5
        retry_count = 0
        base_delay = 2  # seconds

        while retry_count < max_retries:
            try:
                self.pubsub = self.redis_client.subscribe_to_updates()
                logger.info("Started Redis pub/sub listener")
                retry_count = 0  # Reset on successful connection

                for message in self.pubsub.listen():
                    if message['type'] == 'message':
                        try:
                            data = json.loads(message['data'])
                            await self.broadcast(data)
                        except json.JSONDecodeError as e:
                            logger.error(f"Failed to decode Redis message: {e}")

            except Exception as e:
                retry_count += 1
                delay = base_delay ** retry_count  # Exponential backoff: 2s, 4s, 8s, 16s, 32s

                if retry_count >= max_retries:
                    logger.error(
                        f"Redis listener failed after {max_retries} attempts. "
                        f"Real-time updates disabled. Error: {e}"
                    )
                    self.listener_task = None
                    break

                logger.warning(
                    f"Redis listener error (attempt {retry_count}/{max_retries}): {e}. "
                    f"Retrying in {delay}s..."
                )
                await asyncio.sleep(delay)

        # If we exit the loop, listener has failed
        if retry_count >= max_retries:
            logger.critical("WebSocket real-time updates permanently disabled due to Redis connection failure")
