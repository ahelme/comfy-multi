FROM node:20-slim AS frontend-builder

# Build ComfyUI frontend
WORKDIR /build
RUN apt-get update && apt-get install -y git && \
    git clone https://github.com/comfyanonymous/ComfyUI.git . && \
    rm -rf .git

# Install Python dependencies for running ComfyUI (CPU only)
FROM python:3.11-slim

# Install system dependencies
# Note: Using libgl1 instead of libgl1-mesa-glx for newer Debian/Ubuntu compatibility
RUN apt-get update && apt-get install -y \
    git \
    wget \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /comfyui

# Copy ComfyUI from builder
COPY --from=frontend-builder /build /comfyui

# Install ComfyUI dependencies (CPU-only versions)
RUN pip install --no-cache-dir \
    torch==2.5.1 \
    torchvision==0.20.1 \
    torchaudio==2.5.1 \
    --index-url https://download.pytorch.org/whl/cpu

# Install remaining ComfyUI requirements
RUN pip install --no-cache-dir -r requirements.txt

# Copy custom nodes
COPY custom_nodes /comfyui/custom_nodes

# Copy entrypoint script and make it executable for all users
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 755 /docker-entrypoint.sh

# Create directories
RUN mkdir -p \
    /comfyui/output \
    /comfyui/input \
    /comfyui/models \
    /comfyui/user_workflows

# Create non-root user
RUN useradd -m -u 1000 comfyuser && \
    chown -R comfyuser:comfyuser /comfyui

USER comfyuser

# Expose ComfyUI port
EXPOSE 8188

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8188/', timeout=5)"

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--cpu"]
