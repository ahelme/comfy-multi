/**
 * Default Workflow Loader Extension
 * Auto-loads Flux2 Klein workflow on first visit
 */

import { app } from "/scripts/app.js";

const DEFAULT_WORKFLOW = "flux2_klein_9b_text_to_image.json";
const STORAGE_KEY = "default_workflow_loaded";

app.registerExtension({
    name: "ComfyMulti.DefaultWorkflowLoader",

    async setup() {
        console.log("[DefaultWorkflowLoader] Extension loaded");

        // Check if default workflow has already been loaded in this session
        const alreadyLoaded = sessionStorage.getItem(STORAGE_KEY);
        if (alreadyLoaded) {
            console.log("[DefaultWorkflowLoader] Default workflow already loaded this session");
            return;
        }

        // Wait a bit for ComfyUI to initialize
        setTimeout(async () => {
            try {
                // Check if user has any workflow loaded (from localStorage or previous session)
                const hasExistingWorkflow = localStorage.getItem("workflow");

                if (!hasExistingWorkflow) {
                    console.log("[DefaultWorkflowLoader] No existing workflow found, loading default:", DEFAULT_WORKFLOW);

                    // Load the default workflow
                    const response = await fetch(`/user_workflows/${DEFAULT_WORKFLOW}`);
                    if (response.ok) {
                        const workflowData = await response.json();
                        await app.loadGraphData(workflowData);
                        console.log("[DefaultWorkflowLoader] Successfully loaded default workflow");

                        // Mark as loaded in this session
                        sessionStorage.setItem(STORAGE_KEY, "true");
                    } else {
                        console.warn("[DefaultWorkflowLoader] Failed to fetch default workflow:", response.status);
                    }
                } else {
                    console.log("[DefaultWorkflowLoader] Existing workflow found, skipping default load");
                    sessionStorage.setItem(STORAGE_KEY, "true");
                }
            } catch (error) {
                console.error("[DefaultWorkflowLoader] Error loading default workflow:", error);
            }
        }, 1000); // Wait 1 second for ComfyUI to initialize
    }
});
