/**
 * Queue Redirect Extension for ComfyUI
 * Intercepts queue submissions and redirects to Queue Manager API
 */

import { app } from "/scripts/app.js";
import { api } from "/scripts/api.js";

// Get configuration from environment
const USER_ID = window.COMFYUI_USER_ID || "unknown";
const QUEUE_MANAGER_URL = window.QUEUE_MANAGER_URL || "http://localhost:3000";

// Job status tracking
let currentJobId = null;
let statusCheckInterval = null;
let jobStatusElement = null;

// Create UI elements for job status
function createJobStatusUI() {
    const container = document.createElement("div");
    container.id = "queue-redirect-status";
    container.style.cssText = `
        position: fixed;
        top: 60px;
        right: 20px;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 15px 20px;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        font-size: 14px;
        min-width: 300px;
        z-index: 10000;
        display: none;
    `;

    const title = document.createElement("div");
    title.style.cssText = "font-weight: 600; margin-bottom: 8px;";
    title.textContent = "Job Status";

    const status = document.createElement("div");
    status.id = "job-status-text";
    status.style.cssText = "margin: 5px 0;";

    const position = document.createElement("div");
    position.id = "job-position";
    position.style.cssText = "margin: 5px 0; font-size: 12px; opacity: 0.9;";

    const progress = document.createElement("div");
    progress.id = "job-progress";
    progress.style.cssText = `
        margin: 10px 0 5px 0;
        height: 4px;
        background: rgba(255,255,255,0.2);
        border-radius: 2px;
        overflow: hidden;
    `;

    const progressBar = document.createElement("div");
    progressBar.id = "job-progress-bar";
    progressBar.style.cssText = `
        height: 100%;
        width: 0%;
        background: white;
        transition: width 0.3s ease;
    `;
    progress.appendChild(progressBar);

    const closeBtn = document.createElement("button");
    closeBtn.textContent = "×";
    closeBtn.style.cssText = `
        position: absolute;
        top: 10px;
        right: 10px;
        background: none;
        border: none;
        color: white;
        font-size: 24px;
        cursor: pointer;
        padding: 0;
        width: 24px;
        height: 24px;
        line-height: 24px;
        opacity: 0.7;
    `;
    closeBtn.onmouseover = () => closeBtn.style.opacity = "1";
    closeBtn.onmouseout = () => closeBtn.style.opacity = "0.7";
    closeBtn.onclick = () => hideJobStatus();

    container.appendChild(title);
    container.appendChild(status);
    container.appendChild(position);
    container.appendChild(progress);
    container.appendChild(closeBtn);

    document.body.appendChild(container);
    jobStatusElement = container;

    return container;
}

function showJobStatus(status, message, positionInfo = null) {
    if (!jobStatusElement) {
        createJobStatusUI();
    }

    jobStatusElement.style.display = "block";
    document.getElementById("job-status-text").textContent = message;

    if (positionInfo) {
        const posElement = document.getElementById("job-position");
        posElement.textContent = `Position in queue: ${positionInfo}`;
        posElement.style.display = "block";
    } else {
        document.getElementById("job-position").style.display = "none";
    }

    // Update progress bar based on status
    const progressBar = document.getElementById("job-progress-bar");
    switch (status) {
        case "pending":
            progressBar.style.width = "25%";
            break;
        case "running":
            progressBar.style.width = "75%";
            break;
        case "completed":
            progressBar.style.width = "100%";
            setTimeout(() => hideJobStatus(), 3000);
            break;
        case "failed":
            progressBar.style.width = "100%";
            progressBar.style.background = "#ef4444";
            break;
    }
}

function hideJobStatus() {
    if (jobStatusElement) {
        jobStatusElement.style.display = "none";
    }
    if (statusCheckInterval) {
        clearInterval(statusCheckInterval);
        statusCheckInterval = null;
    }
    currentJobId = null;
}

// Submit job to Queue Manager
async function submitToQueueManager(workflow) {
    try {
        const response = await fetch(`${QUEUE_MANAGER_URL}/api/jobs`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                user_id: USER_ID,
                workflow: workflow,
                priority: 2, // Normal priority
                metadata: {
                    submitted_at: new Date().toISOString(),
                    frontend: "comfyui"
                }
            })
        });

        if (!response.ok) {
            throw new Error(`Failed to submit job: ${response.statusText}`);
        }

        const data = await response.json();
        return data;

    } catch (error) {
        console.error("Error submitting to queue manager:", error);
        throw error;
    }
}

// Check job status
async function checkJobStatus(jobId) {
    try {
        const response = await fetch(`${QUEUE_MANAGER_URL}/api/jobs/${jobId}`);

        if (!response.ok) {
            throw new Error(`Failed to get job status: ${response.statusText}`);
        }

        const data = await response.json();
        return data;

    } catch (error) {
        console.error("Error checking job status:", error);
        return null;
    }
}

// Poll job status
function startStatusPolling(jobId) {
    if (statusCheckInterval) {
        clearInterval(statusCheckInterval);
    }

    statusCheckInterval = setInterval(async () => {
        const status = await checkJobStatus(jobId);

        if (!status) {
            return;
        }

        switch (status.status) {
            case "pending":
                showJobStatus("pending", "⏳ Job queued...", status.position_in_queue);
                break;

            case "running":
                showJobStatus("running", "🔄 Processing your workflow...");
                break;

            case "completed":
                showJobStatus("completed", "✅ Job completed!");
                clearInterval(statusCheckInterval);
                statusCheckInterval = null;

                // Refresh to show outputs
                setTimeout(() => {
                    window.location.reload();
                }, 2000);
                break;

            case "failed":
                showJobStatus("failed", `❌ Job failed: ${status.error || "Unknown error"}`);
                clearInterval(statusCheckInterval);
                statusCheckInterval = null;
                break;

            case "cancelled":
                showJobStatus("cancelled", "⚠️ Job cancelled");
                clearInterval(statusCheckInterval);
                statusCheckInterval = null;
                break;
        }
    }, 2000); // Poll every 2 seconds
}

// Intercept queue prompt
app.registerExtension({
    name: "ComfyUI.QueueRedirect",

    async setup() {
        // Inject user ID and queue manager URL into window for access
        window.COMFYUI_USER_ID = USER_ID;
        window.QUEUE_MANAGER_URL = QUEUE_MANAGER_URL;

        console.log(`Queue Redirect initialized for user: ${USER_ID}`);
        console.log(`Queue Manager URL: ${QUEUE_MANAGER_URL}`);
    },

    async beforeRegisterNodeDef(nodeType, nodeData, app) {
        // Extension hook (currently not used)
    },

    async queuePrompt(number, batchCount) {
        // This is called when user clicks "Queue Prompt"
        // We intercept it here and redirect to our Queue Manager

        try {
            // Get the current workflow
            const workflow = app.graph.serialize();

            console.log("Submitting workflow to Queue Manager...");

            // Submit to queue manager
            const result = await submitToQueueManager(workflow);

            console.log("Job submitted:", result);

            // Show status and start polling
            currentJobId = result.id;
            showJobStatus("pending", "📤 Job submitted to queue...", result.position_in_queue);
            startStatusPolling(result.id);

            // Prevent default ComfyUI queue behavior by returning false
            return false;

        } catch (error) {
            console.error("Failed to submit to queue manager:", error);
            alert(`Failed to submit job: ${error.message}\n\nFalling back to local execution...`);

            // Fall back to default behavior
            return true;
        }
    }
});

// Add user info banner
app.registerExtension({
    name: "ComfyUI.UserInfo",

    async setup() {
        const banner = document.createElement("div");
        banner.style.cssText = `
            position: fixed;
            top: 10px;
            left: 50%;
            transform: translateX(-50%);
            background: #1f2937;
            color: white;
            padding: 10px 20px;
            border-radius: 6px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 14px;
            font-weight: 500;
            z-index: 9999;
            box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        `;
        banner.textContent = `👤 ${USER_ID.toUpperCase()} - Workshop Mode`;

        document.body.appendChild(banner);
    }
});

console.log("Queue Redirect extension loaded!");
