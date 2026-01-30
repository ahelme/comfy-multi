# Default Workflow Loader

**ComfyUI Custom Node Extension**

## Purpose

Automatically loads the Flux2 Klein 9B workflow when users first open ComfyUI.

## Behavior

- **First Visit:** Loads `flux2_klein_9b_text_to_image.json` automatically
- **Subsequent Visits:** Loads user's last saved workflow (normal ComfyUI behavior)
- **Session-based:** Only loads default once per browser session

## How It Works

1. JavaScript extension runs on ComfyUI startup
2. Checks browser localStorage for existing workflow
3. If no workflow found, fetches default from `/user_workflows/`
4. Loads default workflow using ComfyUI's API
5. Marks session to prevent repeated auto-loading

## Files

- `__init__.py` - Custom node registration (web-only extension)
- `web/default_workflow_loader.js` - Browser-side auto-load logic

## Available Workflows

Users can load any of the 5 available workflows via ComfyUI's Load menu:
- `flux2_klein_9b_text_to_image.json` ← Default
- `flux2_klein_4b_text_to_image.json`
- `ltx2_text_to_video.json`
- `ltx2_text_to_video_distilled.json`
- `example_workflow.json`

## Technical Details

- Uses ComfyUI's `app.registerExtension()` API
- Fetches workflow from `/user_workflows/` (symlinked to `/workflows`)
- Uses `sessionStorage` to track first-load state
- 1-second delay allows ComfyUI to fully initialize

## Testing

1. Clear browser localStorage: `localStorage.clear()`
2. Reload ComfyUI page
3. Flux2 Klein workflow should load automatically
4. Check browser console for `[DefaultWorkflowLoader]` messages

## Related

- GitHub Issue #15 - Set Flux2 Klein as default workflow
- GitHub Issue #13 - Workflow configuration investigation
