#!/bin/bash
# Verda H100 Startup Script for ComfyUI GPU Worker
# This script installs Docker, nvidia-docker2, and basic tools

set -e  # Exit on error

echo "=== ComfyUI GPU Worker Setup Script ==="
echo "Starting at: $(date)"

# Update system
echo "Step 1: Updating system packages..."
apt-get update
apt-get upgrade -y

# Install basic tools
echo "Step 2: Installing basic tools..."
apt-get install -y \
    curl \
    wget \
    git \
    htop \
    vim \
    tmux \
    python3-pip \
    build-essential

# Install Docker
echo "Step 3: Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo "Docker installed successfully"
else
    echo "Docker already installed"
fi

# Install nvidia-docker2
echo "Step 4: Installing nvidia-docker2..."
if ! dpkg -l | grep -q nvidia-docker2; then
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    apt-get update
    apt-get install -y nvidia-docker2
    systemctl restart docker
    echo "nvidia-docker2 installed successfully"
else
    echo "nvidia-docker2 already installed"
fi

# Verify GPU access
echo "Step 5: Verifying GPU access..."
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi

# Install Docker Compose
echo "Step 6: Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully"
else
    echo "Docker Compose already installed"
fi

# Install huggingface-cli for model downloads
echo "Step 7: Installing HuggingFace CLI..."
pip3 install huggingface-hub

# Create working directory
echo "Step 8: Creating working directory..."
mkdir -p /workspace
cd /workspace

# Print completion message
echo ""
echo "=== Setup Complete ==="
echo "Finished at: $(date)"
echo ""
echo "NEXT STEPS (Manual):"
echo "1. Clone repository: git clone https://github.com/ahelme/comfy-multi.git"
echo "2. Configure .env with REDIS_HOST=comfy.ahelme.net and Redis password"
echo "3. Download workshop models to data/models/shared/"
echo "4. Build worker: docker compose build worker-1"
echo "5. Start worker: docker compose up -d worker-1"
echo ""
echo "See: implementation-deployment-verda.md for detailed instructions"
echo ""
echo "GPU Info:"
nvidia-smi --query-gpu=name,memory.total --format=csv

echo ""
echo "System Info:"
echo "Docker version: $(docker --version)"
echo "Docker Compose version: $(docker compose version)"
echo "Disk space: $(df -h / | tail -1 | awk '{print $4}' ) available"
