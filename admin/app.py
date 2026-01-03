"""
Admin Dashboard - Web UI for ComfyUI Queue Management
Simple FastAPI app serving static HTML dashboard
"""
import logging
from datetime import datetime
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import httpx
import os

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration
QUEUE_MANAGER_URL = os.getenv("QUEUE_MANAGER_URL", "http://queue-manager:3000")

app = FastAPI(
    title="ComfyUI Admin Dashboard",
    version="0.1.0"
)

# HTTP client for queue manager
http_client = httpx.AsyncClient(timeout=10.0)


@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request):
    """Serve the main dashboard page"""
    html_content = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ComfyUI Admin Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
        }

        .header {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            padding: 30px;
            border-radius: 15px;
            margin-bottom: 20px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }

        .header h1 {
            color: #333;
            font-size: 32px;
            margin-bottom: 10px;
        }

        .header .subtitle {
            color: #666;
            font-size: 16px;
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }

        .stat-card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }

        .stat-card h3 {
            color: #666;
            font-size: 14px;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 10px;
        }

        .stat-card .value {
            font-size: 42px;
            font-weight: 700;
            color: #667eea;
            margin-bottom: 5px;
        }

        .stat-card .label {
            color: #999;
            font-size: 14px;
        }

        .content {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 20px;
        }

        .panel {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }

        .panel h2 {
            color: #333;
            font-size: 24px;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid #f0f0f0;
        }

        .job-list {
            max-height: 600px;
            overflow-y: auto;
        }

        .job-item {
            padding: 15px;
            margin-bottom: 10px;
            border-radius: 10px;
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            transition: all 0.3s ease;
        }

        .job-item:hover {
            transform: translateX(5px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }

        .job-item.pending {
            border-left-color: #ffa500;
        }

        .job-item.running {
            border-left-color: #28a745;
            background: linear-gradient(90deg, #d4edda 0%, #f8f9fa 50%);
        }

        .job-item.completed {
            border-left-color: #6c757d;
            opacity: 0.7;
        }

        .job-item.failed {
            border-left-color: #dc3545;
        }

        .job-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
        }

        .job-id {
            font-weight: 600;
            color: #333;
            font-size: 14px;
        }

        .job-status {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }

        .job-status.pending {
            background: #fff3cd;
            color: #856404;
        }

        .job-status.running {
            background: #d4edda;
            color: #155724;
        }

        .job-status.completed {
            background: #d1ecf1;
            color: #0c5460;
        }

        .job-status.failed {
            background: #f8d7da;
            color: #721c24;
        }

        .job-info {
            display: flex;
            gap: 15px;
            font-size: 13px;
            color: #666;
        }

        .job-actions {
            margin-top: 10px;
            display: flex;
            gap: 10px;
        }

        .btn {
            padding: 6px 14px;
            border: none;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .btn-cancel {
            background: #dc3545;
            color: white;
        }

        .btn-cancel:hover {
            background: #c82333;
        }

        .btn-priority {
            background: #667eea;
            color: white;
        }

        .btn-priority:hover {
            background: #5568d3;
        }

        .worker-card {
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 10px;
            background: #f8f9fa;
        }

        .worker-status {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 8px;
        }

        .status-indicator {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: #28a745;
            animation: pulse 2s infinite;
        }

        .status-indicator.idle {
            background: #6c757d;
            animation: none;
        }

        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }

        .worker-name {
            font-weight: 600;
            color: #333;
        }

        .worker-info {
            font-size: 13px;
            color: #666;
            margin-left: 22px;
        }

        .empty-state {
            text-align: center;
            padding: 40px;
            color: #999;
        }

        .empty-state svg {
            width: 64px;
            height: 64px;
            margin-bottom: 15px;
            opacity: 0.3;
        }

        .refresh-indicator {
            display: inline-block;
            margin-left: 10px;
            font-size: 12px;
            color: #28a745;
            font-weight: 500;
        }

        @media (max-width: 1024px) {
            .content {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>ComfyUI Admin Dashboard</h1>
            <div class="subtitle">Multi-User Workshop Queue Management <span class="refresh-indicator" id="refresh-indicator">● Live</span></div>
        </div>

        <div class="stats">
            <div class="stat-card">
                <h3>Pending</h3>
                <div class="value" id="stat-pending">-</div>
                <div class="label">Jobs in queue</div>
            </div>
            <div class="stat-card">
                <h3>Running</h3>
                <div class="value" id="stat-running">-</div>
                <div class="label">Currently processing</div>
            </div>
            <div class="stat-card">
                <h3>Completed</h3>
                <div class="value" id="stat-completed">-</div>
                <div class="label">Successfully finished</div>
            </div>
            <div class="stat-card">
                <h3>Failed</h3>
                <div class="value" id="stat-failed">-</div>
                <div class="label">Errors encountered</div>
            </div>
        </div>

        <div class="content">
            <div class="panel">
                <h2>Job Queue</h2>
                <div class="job-list" id="job-list">
                    <div class="empty-state">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                        </svg>
                        <div>Loading jobs...</div>
                    </div>
                </div>
            </div>

            <div class="panel">
                <h2>Workers</h2>
                <div id="worker-list">
                    <div class="empty-state">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01" />
                        </svg>
                        <div>Loading workers...</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        const QUEUE_MANAGER_URL = window.location.origin.replace(':8080', ':3000');
        let ws = null;

        async function fetchQueueStatus() {
            try {
                const response = await fetch(`${QUEUE_MANAGER_URL}/api/queue/status`);
                const data = await response.json();

                document.getElementById('stat-pending').textContent = data.pending_jobs;
                document.getElementById('stat-running').textContent = data.running_jobs;
                document.getElementById('stat-completed').textContent = data.completed_jobs;
                document.getElementById('stat-failed').textContent = data.failed_jobs;
            } catch (error) {
                console.error('Failed to fetch queue status:', error);
            }
        }

        async function fetchJobs() {
            try {
                const response = await fetch(`${QUEUE_MANAGER_URL}/api/jobs?limit=50`);
                const jobs = await response.json();

                const jobList = document.getElementById('job-list');

                if (jobs.length === 0) {
                    jobList.innerHTML = `
                        <div class="empty-state">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                            <div>No jobs in queue</div>
                        </div>
                    `;
                    return;
                }

                jobList.innerHTML = jobs.map(job => `
                    <div class="job-item ${job.status}">
                        <div class="job-header">
                            <div class="job-id">Job ${job.id.substring(0, 8)}</div>
                            <div class="job-status ${job.status}">${job.status}</div>
                        </div>
                        <div class="job-info">
                            <span>👤 ${job.user_id}</span>
                            <span>🕐 ${new Date(job.created_at).toLocaleTimeString()}</span>
                            ${job.position_in_queue !== null ? `<span>📍 Position: ${job.position_in_queue + 1}</span>` : ''}
                            ${job.worker_id ? `<span>🖥️ ${job.worker_id}</span>` : ''}
                        </div>
                        ${job.error ? `<div class="job-info" style="color: #dc3545; margin-top: 8px;">❌ ${job.error}</div>` : ''}
                        ${job.status === 'pending' || job.status === 'running' ? `
                            <div class="job-actions">
                                ${job.status === 'pending' ? `<button class="btn btn-priority" onclick="updatePriority('${job.id}')">⚡ Prioritize</button>` : ''}
                                <button class="btn btn-cancel" onclick="cancelJob('${job.id}')">✕ Cancel</button>
                            </div>
                        ` : ''}
                    </div>
                `).join('');
            } catch (error) {
                console.error('Failed to fetch jobs:', error);
            }
        }

        async function cancelJob(jobId) {
            if (!confirm('Are you sure you want to cancel this job?')) return;

            try {
                await fetch(`${QUEUE_MANAGER_URL}/api/jobs/${jobId}`, {
                    method: 'DELETE'
                });
                fetchJobs();
                fetchQueueStatus();
            } catch (error) {
                console.error('Failed to cancel job:', error);
                alert('Failed to cancel job');
            }
        }

        async function updatePriority(jobId) {
            try {
                await fetch(`${QUEUE_MANAGER_URL}/api/jobs/${jobId}/priority`, {
                    method: 'PATCH',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ priority: 0 })
                });
                fetchJobs();
            } catch (error) {
                console.error('Failed to update priority:', error);
                alert('Failed to update priority');
            }
        }

        function updateWorkers() {
            // Placeholder for worker status
            // TODO: Implement worker tracking in queue manager
            const workerList = document.getElementById('worker-list');
            workerList.innerHTML = `
                <div class="worker-card">
                    <div class="worker-status">
                        <div class="status-indicator"></div>
                        <div class="worker-name">Worker 1 (GPU)</div>
                    </div>
                    <div class="worker-info">Status: Active</div>
                    <div class="worker-info">Provider: Local H100</div>
                </div>
            `;
        }

        function connectWebSocket() {
            const wsUrl = QUEUE_MANAGER_URL.replace('http', 'ws') + '/ws';
            ws = new WebSocket(wsUrl);

            ws.onopen = () => {
                console.log('WebSocket connected');
                document.getElementById('refresh-indicator').textContent = '● Live';
                document.getElementById('refresh-indicator').style.color = '#28a745';
            };

            ws.onmessage = (event) => {
                const message = JSON.parse(event.data);
                if (message.type === 'job_updated' || message.type === 'job_created') {
                    fetchJobs();
                    fetchQueueStatus();
                }
            };

            ws.onerror = (error) => {
                console.error('WebSocket error:', error);
            };

            ws.onclose = () => {
                console.log('WebSocket disconnected');
                document.getElementById('refresh-indicator').textContent = '● Reconnecting...';
                document.getElementById('refresh-indicator').style.color = '#ffa500';
                setTimeout(connectWebSocket, 3000);
            };
        }

        // Initialize
        fetchQueueStatus();
        fetchJobs();
        updateWorkers();
        connectWebSocket();

        // Fallback polling
        setInterval(() => {
            fetchQueueStatus();
            fetchJobs();
        }, 5000);
    </script>
</body>
</html>
    """
    return HTMLResponse(content=html_content)


@app.get("/api/proxy/queue/status")
async def proxy_queue_status():
    """Proxy endpoint for queue status"""
    try:
        response = await http_client.get(f"{QUEUE_MANAGER_URL}/api/queue/status")
        return response.json()
    except Exception as e:
        logger.error(f"Failed to fetch queue status: {e}")
        return JSONResponse(
            status_code=500,
            content={"error": str(e)}
        )


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "admin-dashboard"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=8080,
        log_level="info"
    )
