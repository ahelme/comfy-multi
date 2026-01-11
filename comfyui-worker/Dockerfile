FROM nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    COMFYUI_VERSION=v0.8.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /workspace

# Clone ComfyUI v0.8.2
RUN git clone --branch v0.8.2 --depth 1 https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI

# Install ComfyUI dependencies
WORKDIR /workspace/ComfyUI
RUN pip3 install --no-cache-dir -r requirements.txt

# Install worker dependencies
COPY requirements.txt /workspace/worker-requirements.txt
RUN pip3 install --no-cache-dir -r /workspace/worker-requirements.txt

# Copy worker script
COPY worker.py /workspace/worker.py
COPY start-worker.sh /workspace/start-worker.sh
RUN chmod +x /workspace/start-worker.sh /workspace/worker.py

# Create directories for models and outputs
RUN mkdir -p /workspace/ComfyUI/models \
    /workspace/ComfyUI/output \
    /workspace/ComfyUI/input \
    /outputs \
    /inputs

# Create non-root user
RUN useradd -m -u 1000 comfyuser && \
    chown -R comfyuser:comfyuser /workspace /outputs /inputs

USER comfyuser

# Expose ComfyUI port
EXPOSE 8188

# Health check
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD python3 -c "import requests; requests.get('http://localhost:8188/system_stats', timeout=5)"

# Start worker
CMD ["/workspace/start-worker.sh"]
