"""
Queue Redirect Custom Node
Redirects ComfyUI queue submissions to external Queue Manager

TODO: This is a placeholder implementation.
The actual queue redirection happens via JavaScript in the WEB_DIRECTORY.
Future enhancement: Add server-side node for explicit queue submission control.
"""

NODE_CLASS_MAPPINGS = {}
NODE_DISPLAY_NAME_MAPPINGS = {}

WEB_DIRECTORY = "./js"

__all__ = ['NODE_CLASS_MAPPINGS', 'NODE_DISPLAY_NAME_MAPPINGS', 'WEB_DIRECTORY']
