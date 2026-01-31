"""
Default Workflow Loader - Auto-loads Flux.2 Klein workflow on startup
"""
import os
import json
import folder_paths

# Path to the default workflow
DEFAULT_WORKFLOW_NAME = "flux2_klein_9b_text_to_image.json"


class DefaultWorkflowLoader:
    """
    Loads the default Flux.2 Klein workflow on ComfyUI startup.
    """

    @classmethod
    def INPUT_TYPES(cls):
        return {}

    RETURN_TYPES = ()
    FUNCTION = "load_default"
    CATEGORY = "utils"
    OUTPUT_NODE = True

    def load_default(self):
        return ()


def load_default_workflow():
    """
    Load the default workflow from the workflows directory.
    This function is called on server startup.
    """
    try:
        # Check if we're in the user workflow directory
        workflows_dir = "/comfyui/user/default/workflows"

        if not os.path.exists(workflows_dir):
            print(f"[DefaultWorkflowLoader] Workflows directory not found: {workflows_dir}")
            return None

        workflow_path = os.path.join(workflows_dir, DEFAULT_WORKFLOW_NAME)

        if not os.path.exists(workflow_path):
            print(f"[DefaultWorkflowLoader] Default workflow not found: {workflow_path}")
            return None

        with open(workflow_path, 'r') as f:
            workflow_data = json.load(f)

        print(f"[DefaultWorkflowLoader] Loaded default workflow: {DEFAULT_WORKFLOW_NAME}")
        return workflow_data

    except Exception as e:
        print(f"[DefaultWorkflowLoader] Error loading default workflow: {e}")
        return None


# Export node mappings
NODE_CLASS_MAPPINGS = {
    "DefaultWorkflowLoader": DefaultWorkflowLoader
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "DefaultWorkflowLoader": "Default Workflow Loader"
}

# Set the default workflow on startup
try:
    import server
    from aiohttp import web

    @server.PromptServer.instance.routes.get("/api/default_workflow")
    async def get_default_workflow(request):
        """
        API endpoint to serve the default workflow.
        The frontend will fetch this on startup to auto-load the workflow.
        """
        workflow_data = load_default_workflow()
        if workflow_data:
            return web.json_response(workflow_data)
        else:
            return web.json_response({"error": "Default workflow not found"}, status=404)

    print("[DefaultWorkflowLoader] Registered /api/default_workflow endpoint")
except Exception as e:
    print(f"[DefaultWorkflowLoader] Could not register API endpoint: {e}")
