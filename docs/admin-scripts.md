**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-12
**Doc Updated:** 2026-01-12

---

# Administration Scripts Reference

Complete reference for all management and automation scripts in the ComfyUI Workshop Platform.

---

## Quick Reference

| Script | Purpose | Usage |
|--------|---------|-------|
| **start.sh** | Start platform | `./scripts/start.sh` |
| **stop.sh** | Stop platform | `./scripts/stop.sh` |
| **status.sh** | View system status | `./scripts/status.sh` |
| **add-user.sh** | Add new user | `./scripts/add-user.sh user021` |
| **remove-user.sh** | Remove user | `./scripts/remove-user.sh user021` |
| **list-users.sh** | List all users | `./scripts/list-users.sh` |
| **deploy-vps.sh** | Deploy to VPS | `./scripts/deploy-vps.sh` |
| **deploy-verda.sh** | Deploy GPU worker | `./scripts/deploy-verda.sh` |
| **setup.sh** | Initial setup | `./scripts/setup.sh` |
| **test.sh** | Run tests | `./scripts/test.sh` |
| **load-test.sh** | Load testing | `./scripts/load-test.sh` |
| **backup-verda-env.sh** | Backup Verda environment | `./scripts/backup-verda-env.sh` |
| **create-dotfiles-repo.sh** | Create dotfiles repo | `./scripts/create-dotfiles-repo.sh` |
| **verda-startup-script.sh** | GPU instance setup | Run on Verda instance |

---

## Platform Management

### start.sh
**Purpose:** Start the ComfyUI Workshop Platform with all services

**Usage:**
```bash
./scripts/start.sh
```

**What it does:**
1. Validates `.env` configuration file exists
2. Checks required environment variables (DOMAIN, SSL paths, REDIS_PASSWORD)
3. Validates SSL certificate files exist
4. Creates data directories (models, outputs, inputs, workflows)
5. Starts all Docker containers via docker-compose
6. Waits for services to become healthy
7. Displays access URLs for admin dashboard and user workspaces

**Prerequisites:**
- `.env` file configured (see `.env.example`)
- SSL certificates in place
- Docker and docker-compose installed

**Output:**
```
🚀 Starting ComfyUI Workshop Platform...
✅ Configuration validated
📁 Creating data directories...
🐳 Starting Docker containers...
✅ ComfyUI Workshop Platform is running!

📍 Access Points:
   • Landing Page: https://comfy.ahelme.net/
   • Admin Dashboard: https://comfy.ahelme.net/admin
   • API: https://comfy.ahelme.net/api/health

👥 User Workspaces:
   • https://comfy.ahelme.net/user001/
   • https://comfy.ahelme.net/user002/
   ...
```

---

### stop.sh
**Purpose:** Stop the ComfyUI Workshop Platform

**Usage:**
```bash
./scripts/stop.sh
```

**What it does:**
1. Prompts user about data preservation
2. Stops all Docker containers
3. Optionally removes volumes (if user confirms)

**Interactive prompt:**
```
Do you want to preserve data volumes? (Y/n):
```

**Options:**
- **Y (default):** Stop containers, preserve all data (models, outputs, workflows)
- **n:** Stop containers AND delete all data volumes (⚠️ destructive!)

**When to use:**
- **Preserve volumes:** Temporary shutdown, maintenance, configuration changes
- **Remove volumes:** Complete reset, fresh start, cleaning up after testing

---

### status.sh
**Purpose:** Display comprehensive system status and health checks

**Usage:**
```bash
./scripts/status.sh
```

**What it does:**
1. Shows all Docker container statuses
2. Performs health checks on core services:
   - Redis (PING test)
   - Queue Manager (HTTP health endpoint)
   - Nginx (HTTPS health endpoint)
3. Displays queue status (pending/running jobs)
4. Shows resource usage (CPU, memory per container)

**Output:**
```
📊 ComfyUI Workshop Platform Status

🐳 Docker Containers:
NAME                STATUS          PORTS
comfy-redis         Up 2 hours      6379/tcp
comfy-queue-manager Up 2 hours      3000/tcp
comfy-admin         Up 2 hours      80/tcp
comfy-user001       Up 2 hours      8188/tcp
...

🏥 Health Checks:
   Redis: ✅ Healthy
   Queue Manager: ✅ Healthy
   Nginx: ✅ Healthy

📋 Queue Status:
{
  "queue_depth": 0,
  "active_workers": 1,
  "workers_status": {...}
}

💾 Resource Usage:
NAME                CPU %    MEM USAGE
comfy-redis         0.15%    45.2MiB / 2GiB
comfy-queue-manager 0.08%    128.5MiB / 1GiB
...
```

**When to use:**
- Troubleshooting service issues
- Monitoring resource usage
- Checking queue activity
- Verifying system health

---

## User Management

### add-user.sh
**Purpose:** Add a new user workspace beyond the default 20

**Usage:**
```bash
./scripts/add-user.sh <user_id>
```

**Example:**
```bash
./scripts/add-user.sh user021
```

**What it does:**
1. Validates user doesn't already exist
2. Creates user-specific directories:
   - `data/outputs/user021/`
   - `data/inputs/user021/`
   - `data/models/user/user021/`
3. Generates docker-compose override file (`docker-compose.user-user021.yml`)
4. Starts the new user container
5. Displays access URL

**Use cases:**
- Workshop has more than 20 participants
- Adding late registrants
- Creating additional test users

**Output:**
```
Adding user: user021
📁 Creating user directories...
✅ Service file created: docker-compose.user-user021.yml
🚀 Starting user service...
✅ User user021 added successfully!
Access URL: https://comfy.ahelme.net/user021/
```

**Note:** You'll need to add HTTP Basic Auth credentials for new users:
```bash
sudo htpasswd -bB /etc/nginx/comfyui-users.htpasswd user021 <password>
```

---

### remove-user.sh
**Purpose:** Remove a user workspace and optionally delete their data

**Usage:**
```bash
./scripts/remove-user.sh <user_id>
```

**Example:**
```bash
./scripts/remove-user.sh user021
```

**What it does:**
1. Validates user exists
2. Prompts for data deletion confirmation
3. Stops and removes user container
4. Removes docker-compose override file
5. Optionally deletes user data directories

**Interactive prompt:**
```
Remove user data? (y/N):
```

**Options:**
- **N (default):** Remove container only, preserve user's data
- **y:** Remove container AND delete all user data (outputs, inputs, models)

**When to use:**
- Workshop concluded, removing temporary users
- Freeing up system resources
- Cleaning up test users

**Warning:** User data deletion is permanent! Consider backing up first:
```bash
tar -czf user021-backup.tar.gz data/outputs/user021/ data/inputs/user021/
```

---

### list-users.sh
**Purpose:** Display all user workspaces and their data usage

**Usage:**
```bash
./scripts/list-users.sh
```

**What it does:**
1. Lists all running user containers
2. Shows user data directories with disk usage
3. Displays total storage per user

**Output:**
```
📋 ComfyUI Workshop Users

Running Containers:
NAME            STATUS
comfy-user001   Up 3 hours
comfy-user002   Up 3 hours
comfy-user003   Up 3 hours
...

User Data Directories:
  • user001 - Outputs: 234M
  • user002 - Outputs: 156M
  • user003 - Outputs: 512M
  ...
```

**When to use:**
- Monitoring storage usage
- Identifying inactive users
- Planning capacity
- Auditing workshop participation

---

## Deployment Scripts

### deploy-vps.sh
**Purpose:** Deploy or update the VPS (application layer) services

**Usage:**
```bash
./scripts/deploy-vps.sh
```

**What it does:**
1. Validates environment configuration
2. Pulls latest Docker images
3. Rebuilds custom images (if needed)
4. Restarts services with zero-downtime strategy
5. Verifies health endpoints
6. Displays deployment status

**Services deployed:**
- Redis (job queue)
- Queue Manager (FastAPI)
- Admin Dashboard
- 20x User Frontend containers
- Nginx (reverse proxy)

**When to use:**
- Initial VPS setup
- Deploying code updates
- Applying configuration changes
- Updating Docker images

**Prerequisites:**
- SSH access to VPS
- `.env` configured on VPS
- SSL certificates in place
- Tailscale VPN connected

**Deployment checklist:**
```bash
# 1. Pull latest code
git pull origin main

# 2. Review changes
git log -3 --oneline

# 3. Deploy
./scripts/deploy-vps.sh

# 4. Verify
./scripts/status.sh
curl https://comfy.ahelme.net/health
```

---

### deploy-verda.sh
**Purpose:** Deploy or update GPU worker on Verda instance

**Usage:**
```bash
./scripts/deploy-verda.sh
```

**What it does:**
1. Syncs code to Verda GPU instance
2. Validates Tailscale VPN connection
3. Tests Redis connectivity (100.99.216.71:6379)
4. Pulls/rebuilds GPU worker image
5. Downloads required models (if missing)
6. Starts GPU worker container
7. Verifies worker registration with queue

**Services deployed:**
- ComfyUI GPU Worker (with CUDA support)
- Model storage (LTX-2 models)

**When to use:**
- Initial GPU worker setup
- Deploying worker updates
- Switching to new GPU instance
- Updating ComfyUI version

**Prerequisites:**
- Verda instance running
- Tailscale authenticated on both VPS and Verda
- SSH access (dev@verda)
- LTX-2 models downloaded (~20GB)

**Deployment checklist:**
```bash
# 1. Test connectivity
ssh dev@verda "echo OK"

# 2. Test Redis via Tailscale
ssh dev@verda "redis-cli -h 100.99.216.71 -p 6379 -a '<REDIS_PASSWORD>' ping"

# 3. Deploy
./scripts/deploy-verda.sh

# 4. Verify worker
docker logs comfy-worker-1
```

---

### setup.sh
**Purpose:** Initial project setup and dependency installation

**Usage:**
```bash
./scripts/setup.sh
```

**What it does:**
1. Installs system dependencies (Docker, docker-compose, etc.)
2. Creates necessary directories
3. Generates `.env` from `.env.example`
4. Prompts for configuration values
5. Downloads initial models
6. Performs initial Docker image builds

**When to use:**
- First-time setup on new VPS
- Setting up development environment
- Recovering from complete system failure

**Interactive prompts:**
```
Enter domain name (e.g., comfy.ahelme.net):
Enter SSL certificate path:
Enter SSL key path:
Enter Redis password:
```

**Output:**
```
🔧 Setting up ComfyUI Workshop Platform...
✅ Docker installed
✅ System dependencies installed
✅ Data directories created
✅ .env file generated
✅ Setup complete!

Next steps:
  1. Review .env configuration
  2. Place SSL certificates
  3. Run ./scripts/start.sh
```

---

## Testing Scripts

### test.sh
**Purpose:** Run comprehensive test suite for the platform

**Usage:**
```bash
./scripts/test.sh [options]
```

**Options:**
```bash
./scripts/test.sh              # Run all tests
./scripts/test.sh --unit       # Unit tests only
./scripts/test.sh --integration # Integration tests only
./scripts/test.sh --e2e        # End-to-end tests only
```

**What it tests:**
1. **Unit Tests:**
   - Queue Manager API logic
   - Redis client operations
   - Job scheduling algorithms
   - Authentication middleware

2. **Integration Tests:**
   - VPS ↔ Redis connectivity
   - Redis ↔ GPU worker connectivity
   - Queue Manager ↔ Worker communication
   - Admin dashboard API calls

3. **End-to-End Tests:**
   - Submit job via user frontend
   - Job queues correctly
   - Worker picks up job
   - Job completes successfully
   - Output file created

**Output:**
```
🧪 Running ComfyUI Platform Tests...

Unit Tests:
✅ test_redis_connection
✅ test_queue_enqueue
✅ test_queue_dequeue
✅ test_job_status_update
✅ test_worker_registration

Integration Tests:
✅ test_vps_to_redis
✅ test_redis_to_worker
✅ test_queue_manager_health
✅ test_admin_dashboard_api

End-to-End Tests:
✅ test_submit_job_workflow
✅ test_job_execution
✅ test_output_generation

Test Summary:
  Total: 161 tests
  Passed: 161
  Failed: 0
  Duration: 45.2s
```

**When to use:**
- Before deploying updates
- After configuration changes
- Verifying bug fixes
- Continuous integration (CI)

---

### load-test.sh
**Purpose:** Stress test the platform with simulated workshop load

**Usage:**
```bash
./scripts/load-test.sh [num_users] [jobs_per_user]
```

**Examples:**
```bash
./scripts/load-test.sh                    # Default: 20 users, 5 jobs each
./scripts/load-test.sh 20 10              # 20 users, 10 jobs each
./scripts/load-test.sh 50 3               # Stress test: 50 users
```

**What it does:**
1. Simulates multiple concurrent users
2. Submits jobs from all users simultaneously
3. Monitors queue depth and worker performance
4. Measures job completion times
5. Tracks errors and timeouts
6. Generates performance report

**Metrics tracked:**
- Jobs submitted per second
- Average queue time
- Average processing time
- Worker utilization
- Error rate
- P95/P99 latency

**Output:**
```
🔥 Load Testing ComfyUI Platform

Configuration:
  Users: 20
  Jobs per user: 5
  Total jobs: 100

Starting load test...

Progress: [████████████████████] 100/100 jobs submitted

Results:
  ✅ Jobs submitted: 100
  ✅ Jobs completed: 100
  ❌ Jobs failed: 0

  Submission rate: 12.5 jobs/sec
  Avg queue time: 2.3s
  Avg processing time: 45.6s
  Worker utilization: 87%

  Latency:
    P50: 42.1s
    P95: 58.3s
    P99: 62.7s
```

**When to use:**
- Before workshop to validate capacity
- Tuning worker count (1 vs 2 vs 3 workers)
- Identifying bottlenecks
- Capacity planning

**Recommended tests:**
```bash
# Workshop simulation (20 users, moderate load)
./scripts/load-test.sh 20 5

# Peak load test (all users submit at once)
./scripts/load-test.sh 20 1

# Sustained load test (verify stability)
./scripts/load-test.sh 10 20
```

---

## Environment Backup & Restore

### backup-verda-env.sh
**Purpose:** Create complete backup of Verda GPU worker environment

**Usage:**
```bash
./scripts/backup-verda-env.sh
```

**Environment variables:**
```bash
VERDA_HOST=dev@verda        # SSH target
BACKUP_DIR=~/backups/verda  # Local backup storage
```

**What it does:**
1. Connects to Verda GPU instance via SSH
2. Creates tar archive of `/home/dev` directory
3. Excludes large files (models, cache, outputs)
4. Downloads backup to VPS
5. Cleans up remote backup file
6. Keeps last 5 backups, deletes older ones

**Backup includes:**
- ✓ Dotfiles (.zshrc, .vimrc, .gitconfig)
- ✓ Oh-my-zsh configuration and custom themes
- ✓ SSH keys (~/.ssh/) ⚠️
- ✓ Shell history
- ✓ Application configs
- ✓ Git repositories (without .git/objects)

**Backup excludes:**
- ✗ Model files (data/models/) - ~20GB
- ✗ Generated outputs (data/outputs/)
- ✗ Cache directories (.cache, .npm, .docker)
- ✗ Package caches (.local/share)

**Output:**
```
🔄 Backing up Verda environment...
   Source: dev@verda:/home/dev
   Destination: ~/backups/verda/verda-env-backup-20260112-143022.tar.gz

Step 1: Creating backup archive on Verda...
Step 2: Downloading backup to VPS...
Step 3: Cleaning up remote backup...

✅ Backup complete!
   File: ~/backups/verda/verda-env-backup-20260112-143022.tar.gz
   Size: 127M

To restore on a new machine:
  scp ~/backups/verda/verda-env-backup-20260112-143022.tar.gz newmachine:/tmp/
  ssh newmachine 'tar -xzf /tmp/verda-env-backup-20260112-143022.tar.gz -C /home/dev'

Cleaning up old backups (keeping last 5)...
removed 'verda-env-backup-20260110-120045.tar.gz'

Current backups:
-rw-r--r-- 1 dev dev 127M Jan 12 14:30 verda-env-backup-20260112-143022.tar.gz
-rw-r--r-- 1 dev dev 125M Jan 11 18:22 verda-env-backup-20260111-182245.tar.gz
-rw-r--r-- 1 dev dev 124M Jan 11 09:15 verda-env-backup-20260111-091533.tar.gz
```

**When to use:**
- Weekly scheduled backups
- Before major system changes
- Before terminating Verda instance
- Disaster recovery preparation

**Schedule automatic backups:**
```bash
# On VPS - add to crontab
crontab -e

# Backup every Sunday at 2 AM
0 2 * * 0 /home/dev/projects/comfyui/scripts/backup-verda-env.sh >> /var/log/verda-backup.log 2>&1
```

---

### create-dotfiles-repo.sh
**Purpose:** Create a Git repository of your dotfiles for reproducible setups

**Usage:**
```bash
# Run on Verda GPU instance
ssh dev@verda "bash /tmp/create-dotfiles-repo.sh"
```

**What it does:**
1. Creates `~/dotfiles` directory
2. Copies configuration files:
   - `.zshrc` (zsh configuration)
   - `.vimrc` (vim configuration)
   - `.tmux.conf` (tmux configuration)
   - `.gitconfig` (git configuration)
3. Copies oh-my-zsh custom themes (bullet-train, etc.)
4. Generates `install.sh` script for automated restoration
5. Creates README.md with usage instructions
6. Initializes Git repository

**Output:**
```
🔧 Creating dotfiles repository...
  Copying config files...
  Copying oh-my-zsh themes...
  Creating install.sh...

✅ Dotfiles repo created at ~/dotfiles

Next steps:
  1. Create GitHub repo: https://github.com/new
  2. Push dotfiles:
     cd ~/dotfiles
     git remote add origin git@github.com:ahelme/dotfiles.git
     git branch -M main
     git push -u origin main

To restore on a new machine:
  git clone https://github.com/ahelme/dotfiles.git ~/dotfiles
  cd ~/dotfiles && ./install.sh
```

**Files created:**
```
~/dotfiles/
├── .zshrc              # Your zsh config
├── .vimrc              # Your vim config
├── .gitconfig          # Your git config
├── oh-my-zsh-themes/   # Custom themes
│   └── bullet-train.zsh-theme
├── install.sh          # Automated installer
└── README.md           # Usage documentation
```

**When to use:**
- One-time setup for reproducible environments
- Before creating dotfiles backup
- When standardizing team environments
- Switching GPU providers

**After creating, push to GitHub:**
```bash
ssh dev@verda
cd ~/dotfiles
git remote add origin git@github.com:ahelme/dotfiles.git
git push -u origin main
```

**Restore on new machine:**
```bash
git clone https://github.com/ahelme/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh  # Start using your shell
```

---

## GPU Worker Setup

### verda-startup-script.sh
**Purpose:** Automated setup script for new Verda GPU instances

**Usage:**
```bash
# On new Verda instance (as root or with sudo)
curl -fsSL https://raw.githubusercontent.com/ahelme/comfy-multi/main/scripts/verda-startup-script.sh | sudo bash

# Or manually:
scp scripts/verda-startup-script.sh root@new-verda:/tmp/
ssh root@new-verda "bash /tmp/verda-startup-script.sh"
```

**What it does:**
1. Updates system packages (apt-get update/upgrade)
2. Installs basic tools (curl, wget, git, htop, vim, tmux)
3. Installs Docker Engine (latest stable)
4. Installs nvidia-docker2 for GPU support
5. Configures Docker daemon for GPU access
6. Adds dev user to docker group
7. Installs Tailscale VPN
8. Displays next steps

**Output:**
```
=== ComfyUI GPU Worker Setup Script ===
Starting at: Sun Jan 12 14:30:22 UTC 2026

Step 1: Updating system packages...
Step 2: Installing basic tools...
Step 3: Installing Docker...
Docker installed successfully
Step 4: Installing nvidia-docker2...
nvidia-docker2 installed successfully
Step 5: Configuring Docker for GPU...
Docker configured for GPU access

=== Setup Complete ===
✅ Docker + nvidia-docker2 installed
✅ Basic tools installed
✅ Tailscale ready for installation

Next steps:
  1. Authenticate Tailscale: sudo tailscale up
  2. Test GPU: docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
  3. Clone repo: git clone https://github.com/ahelme/comfy-multi.git ~/comfy-multi
  4. Download models: cd ~/comfy-multi && bash /tmp/download-ltx2-models.sh
  5. Start worker: docker compose up -d worker-1
```

**Prerequisites:**
- Fresh Ubuntu 22.04 instance
- Root or sudo access
- NVIDIA GPU with drivers installed
- Internet connectivity

**Post-installation:**
```bash
# 1. Authenticate Tailscale
sudo tailscale up

# 2. Verify Tailscale connectivity
tailscale status
ping 100.99.216.71  # VPS Tailscale IP

# 3. Test Redis connectivity
redis-cli -h 100.99.216.71 -p 6379 -a '<REDIS_PASSWORD>' ping
# Should return: PONG

# 4. Clone comfy-multi repo
git clone https://github.com/ahelme/comfy-multi.git ~/comfy-multi

# 5. Configure environment
cd ~/comfy-multi
cp .env.example .env
nano .env  # Update REDIS_HOST=100.99.216.71

# 6. Download LTX-2 models (~20GB, ~30 minutes)
# See model download script in repo

# 7. Start GPU worker
docker compose up -d worker-1
```

**When to use:**
- Setting up new Verda instance
- Rebuilding GPU worker after termination
- Switching to different GPU provider (RunPod, Modal, Hetzner)
- Creating development GPU environment

---

## Script Maintenance

### Updating Scripts

All scripts are version controlled in the repository:

```bash
# Pull latest scripts
git pull origin main

# Review script changes
git log -p scripts/

# Make scripts executable (if needed)
chmod +x scripts/*.sh
```

### Adding New Scripts

When adding new scripts, follow this template:

```bash
#!/bin/bash
set -e

# Script Name - Brief Description
# ===============================

# Usage information
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Usage: $0 [options]"
    echo "Description: What this script does"
    exit 0
fi

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Main script logic here
echo "✅ Done!"
```

**Checklist:**
- [ ] Includes usage information
- [ ] Has set -e for error handling
- [ ] Uses SCRIPT_DIR/PROJECT_DIR variables
- [ ] Provides clear output with emoji/formatting
- [ ] Validates prerequisites
- [ ] Handles errors gracefully
- [ ] Includes --help flag
- [ ] Documented in admin-scripts.md

---

## Common Script Workflows

### Daily Operations

**Morning startup:**
```bash
./scripts/start.sh              # Start platform
./scripts/status.sh             # Verify health
```

**Evening shutdown:**
```bash
./scripts/status.sh             # Check activity
./scripts/stop.sh               # Stop (preserve data)
```

### Workshop Day

**Pre-workshop:**
```bash
./scripts/start.sh              # Start all services
./scripts/load-test.sh 20 5     # Verify capacity
./scripts/status.sh             # Confirm health
```

**During workshop:**
```bash
./scripts/status.sh             # Monitor every 30 min
docker logs -f comfy-worker-1   # Watch GPU worker
```

**Post-workshop:**
```bash
./scripts/list-users.sh         # Review usage
# Backup outputs before cleanup
tar -czf workshop-outputs.tar.gz data/outputs/
```

### Deployment

**VPS update:**
```bash
git pull origin main            # Get latest code
./scripts/test.sh               # Run tests
./scripts/deploy-vps.sh         # Deploy
./scripts/status.sh             # Verify
```

**GPU worker update:**
```bash
git pull origin main            # Get latest code
./scripts/deploy-verda.sh       # Deploy to Verda
ssh dev@verda "docker logs comfy-worker-1"  # Verify
```

### Maintenance

**Weekly tasks:**
```bash
# Backup Verda environment
./scripts/backup-verda-env.sh

# Review logs
docker logs comfy-queue-manager --since 7d | grep ERROR
docker logs comfy-worker-1 --since 7d | grep ERROR

# Check disk usage
df -h
du -sh data/outputs/*
```

**Before workshop:**
```bash
# Update platform
git pull origin main
./scripts/deploy-vps.sh

# Verify LTX-2 models
ssh dev@verda "ls -lh ~/comfy-multi/data/models/checkpoints/"

# Load test
./scripts/load-test.sh 20 5
```

---

## Troubleshooting Scripts

### Script fails with "Permission denied"

**Solution:**
```bash
# Make script executable
chmod +x scripts/<script-name>.sh

# Or run with bash
bash scripts/<script-name>.sh
```

### Script can't find .env file

**Solution:**
```bash
# Ensure running from project root
cd /home/dev/projects/comfyui
./scripts/start.sh

# Create .env if missing
cp .env.example .env
nano .env  # Configure
```

### Docker commands fail in script

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker  # Or logout/login

# Start Docker service
sudo systemctl start docker
```

### SSH to Verda fails in scripts

**Solution:**
```bash
# Test SSH connectivity
ssh dev@verda "echo OK"

# Add SSH key if needed
ssh-copy-id dev@verda

# Check ~/.ssh/config
cat ~/.ssh/config | grep verda
```

---

## Related Documentation

- **[Admin Guide →](./admin-guide.md)** - Main administrator documentation
- **[Environment Backup →](./admin-gpu-environment-backup.md)** - Detailed backup strategies
- **[Troubleshooting →](./admin-troubleshooting-redis-connection.md)** - Common issues
- **[Deployment Guide →](../implementation-deployment.md)** - VPS deployment details
- **[GPU Worker Guide →](../implementation-deployment-verda.md)** - Verda deployment details

---

**Last Updated:** 2026-01-12
