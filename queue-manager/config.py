"""
Configuration management for Queue Manager
"""
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    # Redis Configuration
    redis_host: str = "redis"
    redis_port: int = 6379
    redis_password: str
    redis_db: int = 0

    # Queue Configuration
    queue_mode: str = "fifo"
    enable_priority: bool = True
    job_timeout: int = 3600  # seconds
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
    worker_heartbeat_timeout: int = 60  # seconds
    worker_poll_interval: int = 1  # seconds

    # Storage paths
    outputs_path: str = "/outputs"
    inputs_path: str = "/inputs"

    # Application metadata
    app_name: str = "ComfyUI Queue Manager"
    app_version: str = "0.1.0"

    class Config:
        env_file = ".env"
        case_sensitive = False


# Singleton instance
settings = Settings()
