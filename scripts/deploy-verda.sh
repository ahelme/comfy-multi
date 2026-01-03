#!/bin/bash
#
# Deploy ComfyUI Multi-User Platform to Verda H100 Instance
#
# Usage: ./scripts/deploy-verda.sh [verda-instance-ip]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=================================================="
echo "  ComfyUI Multi-User - Verda Deployment"
echo "=================================================="
echo ""

# Check arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <verda-instance-ip>"
    echo ""
    echo "Example:"
    echo "  $0 192.168.1.100"
    echo "  $0 user@verda.example.com"
    echo ""
    exit 1
fi

VERDA_HOST="$1"
REMOTE_DIR="/opt/comfyui-workshop"

echo "📋 Deployment Configuration:"
echo "   Target: $VERDA_HOST"
echo "   Remote directory: $REMOTE_DIR"
echo ""

# Verify SSH access
echo "🔐 Verifying SSH access..."
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$VERDA_HOST" echo "SSH connection successful" 2>/dev/null; then
    echo "❌ Cannot connect to $VERDA_HOST via SSH"
    echo "   Please ensure:"
    echo "   1. SSH key is added to the instance"
    echo "   2. Firewall allows SSH connections"
    echo "   3. Host address is correct"
    exit 1
fi
echo "✅ SSH connection verified"

# Check .env exists
if [ ! -f "$PROJECT_DIR/.env" ]; then
    echo "❌ .env file not found. Please run ./scripts/setup.sh first"
    exit 1
fi

# Create deployment package
echo ""
echo "📦 Creating deployment package..."
DEPLOY_ARCHIVE="/tmp/comfyui-deploy-$(date +%s).tar.gz"

cd "$PROJECT_DIR"
tar -czf "$DEPLOY_ARCHIVE" \
    --exclude='.git' \
    --exclude='data/outputs/*' \
    --exclude='data/models/shared/*' \
    --exclude='data/models/custom/*' \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    --exclude='.pytest_cache' \
    --exclude='node_modules' \
    .

echo "✅ Created deployment package: $DEPLOY_ARCHIVE"
echo "   Size: $(du -h "$DEPLOY_ARCHIVE" | cut -f1)"

# Upload to Verda instance
echo ""
echo "📤 Uploading to Verda instance..."
ssh "$VERDA_HOST" "mkdir -p $REMOTE_DIR"
scp "$DEPLOY_ARCHIVE" "$VERDA_HOST:$REMOTE_DIR/deploy.tar.gz"
echo "✅ Upload complete"

# Extract and setup on remote
echo ""
echo "📂 Extracting on remote instance..."
ssh "$VERDA_HOST" << EOF
cd $REMOTE_DIR
tar -xzf deploy.tar.gz
rm deploy.tar.gz
echo "✅ Extraction complete"
EOF

# Run setup on remote
echo ""
echo "⚙️  Running setup on remote instance..."
ssh "$VERDA_HOST" << 'EOF'
cd $REMOTE_DIR

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not installed on remote instance"
    echo "   Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installed"
fi

# Check NVIDIA Docker
if command -v nvidia-smi &> /dev/null; then
    echo "✅ NVIDIA GPU detected"

    # Install NVIDIA Container Toolkit if needed
    if ! docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi &> /dev/null 2>&1; then
        echo "Installing NVIDIA Container Toolkit..."
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
            sudo tee /etc/apt/sources.list.d/nvidia-docker.list
        sudo apt-get update && sudo apt-get install -y nvidia-docker2
        sudo systemctl restart docker
        echo "✅ NVIDIA Container Toolkit installed"
    fi
else
    echo "⚠️  No NVIDIA GPU detected"
fi

# Create required directories
mkdir -p data/models/shared
mkdir -p data/outputs
mkdir -p data/inputs
mkdir -p data/workflows

echo "✅ Remote setup complete"
EOF

# Start services
echo ""
echo "🚀 Starting services on remote instance..."
read -p "   Start services now? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh "$VERDA_HOST" << EOF
cd $REMOTE_DIR
docker-compose pull
docker-compose up -d
echo "✅ Services started"
EOF

    echo ""
    echo "⏳ Waiting for services to be ready..."
    sleep 10

    # Check service health
    echo ""
    echo "🏥 Checking service health..."
    ssh "$VERDA_HOST" << EOF
cd $REMOTE_DIR
docker-compose ps
EOF
fi

# Cleanup
rm "$DEPLOY_ARCHIVE"

echo ""
echo "=================================================="
echo "  ✅ Deployment Complete!"
echo "=================================================="
echo ""
echo "Remote instance: $VERDA_HOST"
echo "Installation directory: $REMOTE_DIR"
echo ""
echo "Next steps:"
echo "  1. SSH to instance: ssh $VERDA_HOST"
echo "  2. Navigate to: cd $REMOTE_DIR"
echo "  3. Edit .env configuration"
echo "  4. Place SSL certificates in the specified paths"
echo "  5. Download models to: data/models/shared/"
echo "  6. Start services: docker-compose up -d"
echo ""
echo "Useful commands (on remote):"
echo "  docker-compose ps        - Check service status"
echo "  docker-compose logs -f   - View logs"
echo "  docker-compose down      - Stop all services"
echo "  ./scripts/status.sh      - System status"
echo ""
