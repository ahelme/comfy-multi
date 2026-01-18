#!/bin/bash
#
# Setup script for ComfyUI Multi-User Workshop Platform
# Prepares the environment for first-time deployment
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=================================================="
echo "  ComfyUI Multi-User Workshop - Setup"
echo "=================================================="
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first:"
    echo "   https://docs.docker.com/get-docker/"
    exit 1
fi
echo "✅ Docker installed: $(docker --version)"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first:"
    echo "   https://docs.docker.com/compose/install/"
    exit 1
fi
if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose installed: $(docker-compose --version)"
else
    echo "✅ Docker Compose installed: $(docker compose version)"
fi

# Check NVIDIA Docker (optional for GPU)
if command -v nvidia-smi &> /dev/null; then
    echo "✅ NVIDIA GPU detected: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)"

    if ! docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
        echo "⚠️  NVIDIA Docker runtime not configured properly"
        echo "   Please install nvidia-docker2:"
        echo "   https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
    else
        echo "✅ NVIDIA Docker runtime configured"
    fi
else
    echo "⚠️  No NVIDIA GPU detected (CPU-only mode)"
fi

echo ""
echo "📁 Creating required directories..."

# Create data directories
mkdir -p "$PROJECT_DIR/data/models/shared"
mkdir -p "$PROJECT_DIR/data/models/custom"
mkdir -p "$PROJECT_DIR/data/outputs"
mkdir -p "$PROJECT_DIR/data/inputs"
mkdir -p "$PROJECT_DIR/data/workflows"

# Create user directories (outputs + user_data for workflows/settings)
for i in $(seq 1 20); do
    USER_ID=$(printf "user%03d" $i)
    mkdir -p "$PROJECT_DIR/data/outputs/$USER_ID"
    mkdir -p "$PROJECT_DIR/data/user_data/$USER_ID"
done

echo "✅ Directories created"

echo ""
echo "⚙️  Configuration setup..."

# Create .env from template if it doesn't exist
if [ ! -f "$PROJECT_DIR/.env" ]; then
    if [ -f "$PROJECT_DIR/.env.example" ]; then
        cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
        echo "✅ Created .env from .env.example"
        echo ""
        echo "⚠️  IMPORTANT: Please edit .env and configure the following:"
        echo "   - DOMAIN (your domain name)"
        echo "   - SSL_CERT_PATH (path to SSL certificate)"
        echo "   - SSL_KEY_PATH (path to SSL private key)"
        echo "   - REDIS_PASSWORD (generate a secure password)"
        echo "   - ADMIN_PASSWORD (generate a secure password)"
        echo ""
        read -p "   Press Enter to edit .env now, or Ctrl+C to exit and edit later..."
        ${EDITOR:-nano} "$PROJECT_DIR/.env"
    else
        echo "❌ .env.example not found. Cannot create .env"
        exit 1
    fi
else
    echo "✅ .env already exists (skipping)"
fi

echo ""
echo "🔐 Validating SSL certificates..."

# Source .env to get paths
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"

    if [ -z "$SSL_CERT_PATH" ] || [ -z "$SSL_KEY_PATH" ]; then
        echo "⚠️  SSL_CERT_PATH or SSL_KEY_PATH not set in .env"
        echo "   Please configure SSL certificate paths before starting"
    elif [ ! -f "$SSL_CERT_PATH" ]; then
        echo "❌ SSL certificate not found at: $SSL_CERT_PATH"
        echo "   Please provide a valid SSL certificate"
    elif [ ! -f "$SSL_KEY_PATH" ]; then
        echo "❌ SSL private key not found at: $SSL_KEY_PATH"
        echo "   Please provide a valid SSL private key"
    else
        echo "✅ SSL certificate found"

        # Validate certificate
        if openssl x509 -in "$SSL_CERT_PATH" -noout -text &> /dev/null; then
            CERT_DOMAIN=$(openssl x509 -in "$SSL_CERT_PATH" -noout -subject | sed -n 's/.*CN=\([^,]*\).*/\1/p')
            CERT_EXPIRY=$(openssl x509 -in "$SSL_CERT_PATH" -noout -enddate | cut -d= -f2)
            echo "   Certificate for: $CERT_DOMAIN"
            echo "   Expires: $CERT_EXPIRY"
        else
            echo "⚠️  SSL certificate validation failed"
        fi
    fi
fi

echo ""
echo "📦 Downloading models (optional)..."
echo "   To download ComfyUI models, you can:"
echo "   1. Place model files in: $PROJECT_DIR/data/models/shared/"
echo "   2. Or skip and download later via ComfyUI UI"
echo ""
read -p "   Download models now? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   Model download URLs:"
    echo "   - SDXL Base: https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0"
    echo "   - LTX-Video: https://huggingface.co/Lightricks/LTX-Video"
    echo ""
    echo "   Please download manually and place in: $PROJECT_DIR/data/models/shared/"
else
    echo "   Skipping model download"
fi

echo ""
echo "=================================================="
echo "  ✅ Setup Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "  1. Edit .env and configure all required settings"
echo "  2. Place SSL certificates in the specified paths"
echo "  3. Download ComfyUI models to data/models/shared/"
echo "  4. Run: ./scripts/start.sh"
echo ""
echo "Useful commands:"
echo "  ./scripts/start.sh    - Start all services"
echo "  ./scripts/stop.sh     - Stop all services"
echo "  ./scripts/status.sh   - Check system status"
echo "  ./scripts/add-user.sh - Add a new user"
echo ""
echo "Access points:"
echo "  Admin Dashboard: https://${DOMAIN:-yourdomain.com}/admin"
echo "  User Workspaces: https://${DOMAIN:-yourdomain.com}/user001 - user020"
echo "  Queue Manager API: https://${DOMAIN:-yourdomain.com}/api/"
echo ""
