**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-02
**Doc Updated:** 2026-01-10

---

# ComfyUI Multi-User Workshop Platform

**Project Status:** Test Deployment Stage

A scalable, multi-user ComfyUI platform with split app-server/inference-provider architecture, designed for AI workshops with shared GPU resources. Supports 20 isolated user workspaces with centralized job queue management.

## 🎯 Features

- **Isolated User Workspaces** - Each participant gets their own ComfyUI interface
- **Intelligent Queue System** - FIFO, round-robin, and priority-based job scheduling
- **Shared GPU Workers** - Efficient resource sharing across multiple users
- **HTTPS Enabled** - Secure access with SSL/TLS
- **Real-time Updates** - WebSocket-based queue status broadcasting
- **Admin Dashboard** - Monitor and manage all user activity
- **Persistent Storage** - User outputs and uploads saved between sessions
- **Multi-Provider Support** - Works with Verda, RunPod, Modal, or local GPUs

## 🏗️ Architecture

```
  Split Server Architecture:
  ┌─────────────────────────────────────────┐
  │ Web App                                 │
  │  - Nginx (HTTPS, SSL)                   │
  │  - Redis (job queue)                    │
  │  - Queue Manager (FastAPI)              │
  │  - Admin Dashboard                      │
  │  - User Frontends x20 (CPU only)        │
  └──────────────┬──────────────────────────┘
                 │ Network
                 │ (Redis connection)
  ┌──────────────▼──────────────────────────┐
  │ Remote GPU                              │
  │  - Worker 1 (ComfyUI + GPU)             │
  │  - Worker 2 (ComfyUI + GPU) [optional]  │
  │  - Worker 3 (ComfyUI + GPU) [optional]  │
  │                                         │
  │  REDIS_HOST=comfy.xxxxxx.net            │
  └─────────────────────────────────────────┘

```

## 📋 Prerequisites

- Docker 24.0+ and Docker Compose 2.0+
- NVIDIA GPU with Docker GPU support (for local deployment)
- SSL certificate and key files
- 80GB+ free disk space (for models and outputs)

## 🚀 Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/ahelme/comfy-multi.git
cd comfy-multi

# Copy and edit configuration
cp .env.example .env
nano .env
```

### 2. Configure Environment

Edit `.env` and set at minimum:

```env
DOMAIN=workshop.example.com
SSL_CERT_PATH=/path/to/fullchain.pem
SSL_KEY_PATH=/path/to/privkey.pem
REDIS_PASSWORD=your_secure_password
```

### 3. Start Platform

```bash
./scripts/start.sh
```

### 4. Access

- **Landing Page**: `https://your-domain/`
- **Health Check**: `https://your-domain/health` *(Check system status)*
- **Admin Dashboard**: `https://your-domain/admin`
- **User Workspaces**: `https://your-domain/user001/` through `/user020/`

## 📖 Documentation

### For Participants
- **[Quick Start Guide](./docs/quick-start.md)** - Get creating in 5 minutes! 🚀
- **[How-To Guides](./docs/how-to-guides.md)** - Step-by-step task guides
- **[FAQ](./docs/faq.md)** - Common questions answered
- [Complete User Guide](./docs/user-guide.md) - Full reference manual

### For Instructors
- **[Deployment Guide](./DEPLOYMENT.md)** - Deploy to comfy.ahelme.net
- [Admin Guide](./docs/admin-guide.md) - Workshop management
- [Workshop Runbook](./docs/workshop-runbook.md) - Day-of execution
- [Troubleshooting Guide](./docs/troubleshooting.md) - Fix common issues

### For Developers
- [README.md](./README.md) - Public code project overview and dev quickstart
- [Progress Log](./progress.md) - Session logs, metrics, standup notes
- [Implementation Plan](./implementation.md) - Architecture & success criteria
- [Product Requirements](./prd.md) - Full requirements
- [Claude Guide](./claude.md) - Development context
- [Test Report](./TEST_REPORT.md) - Comprehensive test suite analysis
- [Code Review](./CODE_REVIEW.md) - Quality review findings

## 🧪 Testing

The platform includes a comprehensive test suite with 161 tests:

```bash
# Install test dependencies
pip install -r tests/requirements.txt

# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=queue-manager --cov=comfyui-worker --cov-report=term-missing

# Run specific test module
pytest tests/test_models.py -v
```

**Test Coverage:**
- 42 model validation tests (security, size limits, path traversal)
- 32 worker functionality tests (job lifecycle, error handling)
- 31 API endpoint tests (FastAPI routes, error responses)
- 33 Redis operation tests (CRUD, queues, atomic operations)
- 23 WebSocket tests (connections, broadcasting, reconnection)

## 🛠️ Management Commands

```bash
# Start all services
./scripts/start.sh

# Stop platform
./scripts/stop.sh

# Check status
./scripts/status.sh

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f queue-manager
docker-compose logs -f worker-1
```

## 📁 Project Structure

```
comfy-multi/
├── docker-compose.yml       # Service orchestration
├── .env.example             # Configuration template
├── nginx/                   # Reverse proxy with SSL
├── redis/                   # Job queue configuration
├── queue-manager/           # FastAPI job scheduler
├── comfyui-worker/          # GPU workers
├── comfyui-frontend/        # User interface containers
├── admin/                   # Admin dashboard
├── scripts/                 # Management scripts
├── data/                    # Persistent storage
│   ├── models/              # Shared & user models
│   ├── outputs/             # Generated outputs
│   ├── inputs/              # User uploads
│   └── workflows/           # Pre-loaded workflows
└── docs/                    # Documentation
```

## ⚙️ Configuration

### Inference Providers

The platform supports multiple inference providers:

- **Verda** (default) - European GPU cloud
- **RunPod** - Serverless GPU containers
- **Modal** - Serverless infrastructure
- **Local** - On-premises GPU

Configure in `.env`:

```env
INFERENCE_PROVIDER=verda
VERDA_API_KEY=your_api_key
```

### Queue Modes

- **FIFO** (First In, First Out) - Fair sequential processing
- **Round-robin** - Equal distribution across users
- **Priority** - Instructor override for demos

```env
QUEUE_MODE=fifo
ENABLE_PRIORITY=true
```

### Scaling Workers

Adjust the number of GPU workers:

```env
NUM_WORKERS=1  # Start with 1, scale to 2-3 based on usage
```

## 🔒 Security

- HTTPS enforced (HTTP redirects to HTTPS)
- Redis password-protected
- User workspace isolation
- Admin dashboard authentication (optional)

## 📊 Monitoring

### Health Checks

**Web Dashboard:**
- Visit: `https://your-domain/health` (beautiful real-time dashboard)

**Command Line:**
```bash
# Check all services
./scripts/status.sh

# Simple ping
curl https://your-domain/health/ping

# API status JSON
curl https://your-domain/api/queue/status
```

### Logs

```bash
# All services
docker-compose logs -f

# Queue manager only
docker-compose logs -f queue-manager

# Worker only
docker-compose logs -f worker-1
```

## 🐛 Troubleshooting

### Services won't start

```bash
# Check configuration
./scripts/status.sh

# Validate .env
cat .env | grep -v "^#" | grep -v "^$"

# Check SSL certificates
ls -la /path/to/certs/
```

### Queue not processing jobs

```bash
# Check worker status
docker-compose logs worker-1

# Check Redis connection
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping

# Restart queue manager
docker-compose restart queue-manager
```

### User can't access workspace

```bash
# Check nginx configuration
docker-compose logs nginx

# Test routing
curl -k https://localhost/user001/
```

## 🚧 Development

### Local Development

```bash
# Use development overrides
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Run with debug logging
DEBUG=true VERBOSE_LOGS=true docker-compose up
```

### Testing

```bash
# Run integration tests (coming soon)
./scripts/test.sh

# Load test with 20 concurrent users (coming soon)
./scripts/load-test.sh
```

## 📝 License

MIT License - see LICENSE file for details

## 🤝 Contributing

This is a workshop-specific platform. For issues or suggestions, please contact the workshop organizer.

## 🙏 Acknowledgments

- Built with [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- Queue patterns inspired by [SaladTechnologies/comfyui-api](https://github.com/SaladTechnologies/comfyui-api)
- Architecture concepts from [Visionatrix](https://github.com/Visionatrix/Visionatrix)

## 📞 Support

- **Repository**: https://github.com/ahelme/comfy-multi
- **Issues**: https://github.com/ahelme/comfy-multi/issues
- **Documentation**: See `/docs` directory

---

**Status**: ✅ Phase 4 Complete - Production Ready!
**Next**: Phase 5 - Deployment & Testing
**Version**: 1.0.0-beta
