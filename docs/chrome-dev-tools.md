# Chrome Dev Tools - MCP Server - Guide

## Tools
[](https://github.com/ChromeDevTools/chrome-devtools-mcp#tools)
If you run into any issues, checkout our [troubleshooting guide](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/troubleshooting.md).

- **Input automation** (8 tools)
	- [`click`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#click)
	- [`drag`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#drag)
	- [`fill`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#fill)
	- [`fill_form`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#fill_form)
	- [`handle_dialog`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#handle_dialog)
	- [`hover`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#hover)
	- [`press_key`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#press_key)
	- [`upload_file`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#upload_file)

- **Navigation automation** (6 tools)
	- [`close_page`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#close_page)
	- [`list_pages`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#list_pages)
	- [`navigate_page`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#navigate_page)
	- [`new_page`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#new_page)
	- [`select_page`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#select_page)
	- [`wait_for`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#wait_for)

- **Emulation** (2 tools)
	- [`emulate`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#emulate)
	- [`resize_page`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#resize_page)

- **Performance** (3 tools)
	- [`performance_analyze_insight`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#performance_analyze_insight)
	- [`performance_start_trace`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#performance_start_trace)
	- [`performance_stop_trace`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#performance_stop_trace)

- **Network** (2 tools)
	- [`get_network_request`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#get_network_request)
	- [`list_network_requests`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#list_network_requests)

- **Debugging** (5 tools)
	- [`evaluate_script`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#evaluate_script)
	- [`get_console_message`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#get_console_message)
	- [`list_console_messages`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#list_console_messages)
	- [`take_screenshot`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#take_screenshot)
	- [`take_snapshot`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md#take_snapshot)

## Configuration
[](https://github.com/ChromeDevTools/chrome-devtools-mcp#configuration)
The Chrome DevTools MCP server supports the following configuration option:
- **`--autoConnect`/ `--auto-connect`** If specified, automatically connects to a browser (Chrome 144+) running in the user data directory identified by the channel param. Requires the remoted debugging server to be started in the Chrome instance via chrome://inspect/#remote-debugging.
	- **Type:** boolean
	- **Default:** `false`
- **`--browserUrl`/ `--browser-url`, `-u`** Connect to a running, debuggable Chrome instance (e.g. `http://127.0.0.1:9222`). For more details see: [https://github.com/ChromeDevTools/chrome-devtools-mcp#connecting-to-a-running-chrome-instance](https://github.com/ChromeDevTools/chrome-devtools-mcp#connecting-to-a-running-chrome-instance).
	- **Type:** string
- **`--wsEndpoint`/ `--ws-endpoint`, `-w`** WebSocket endpoint to connect to a running Chrome instance (e.g., ws://127.0.0.1:9222/devtools/browser/). Alternative to --browserUrl.
	- **Type:** string
- **`--wsHeaders`/ `--ws-headers`** Custom headers for WebSocket connection in JSON format (e.g., '{"Authorization":"Bearer token"}'). Only works with --wsEndpoint.
	- **Type:** string
- **`--headless`** Whether to run in headless (no UI) mode.
	- **Type:** boolean
	- **Default:** `false`
- **`--executablePath`/ `--executable-path`, `-e`** Path to custom Chrome executable.
	- **Type:** string
- **`--isolated`** If specified, creates a temporary user-data-dir that is automatically cleaned up after the browser is closed. Defaults to false.
	- **Type:** boolean
- **`--userDataDir`/ `--user-data-dir`** Path to the user data directory for Chrome. Default is $HOME/.cache/chrome-devtools-mcp/chrome-profile$CHANNEL\_SUFFIX\_IF\_NON\_STABLE
	- **Type:** string
- **`--channel`** Specify a different Chrome channel that should be used. The default is the stable channel version.
	- **Type:** string
	- **Choices:** `stable`, `canary`, `beta`, `dev`
- **`--logFile`/ `--log-file`** Path to a file to write debug logs to. Set the env variable `DEBUG` to `*` to enable verbose logs. Useful for submitting bug reports.
	- **Type:** string
- **`--viewport`** Initial viewport size for the Chrome instances started by the server. For example, `1280x720`. In headless mode, max size is 3840x2160px.
	- **Type:** string
- **`--proxyServer`/ `--proxy-server`** Proxy server configuration for Chrome passed as --proxy-server when launching the browser. See [https://www.chromium.org/developers/design-documents/network-settings/](https://www.chromium.org/developers/design-documents/network-settings/) for details.
	- **Type:** string
- **`--acceptInsecureCerts`/ `--accept-insecure-certs`** If enabled, ignores errors relative to self-signed and expired certificates. Use with caution.
	- **Type:** boolean
- **`--chromeArg`/ `--chrome-arg`** Additional arguments for Chrome. Only applies when Chrome is launched by chrome-devtools-mcp.
	- **Type:** array
- **`--ignoreDefaultChromeArg`/ `--ignore-default-chrome-arg`** Explicitly disable default arguments for Chrome. Only applies when Chrome is launched by chrome-devtools-mcp.
	- **Type:** array
- **`--categoryEmulation`/ `--category-emulation`** Set to false to exclude tools related to emulation.
	- **Type:** boolean
	- **Default:** `true`
- **`--categoryPerformance`/ `--category-performance`** Set to false to exclude tools related to performance.
	- **Type:** boolean
	- **Default:** `true`
- **`--categoryNetwork`/ `--category-network`** Set to false to exclude tools related to network.
	- **Type:** boolean
	- **Default:** `true`
- **`--usageStatistics`/ `--usage-statistics`** Set to false to opt-out of usage statistics collection. Google collects usage data to improve the tool, handled under the Google Privacy Policy ([https://policies.google.com/privacy](https://policies.google.com/privacy)). This is independent from Chrome browser metrics. Disabled if CHROME\_DEVTOOLS\_MCP\_NO\_USAGE\_STATISTICS or CI env variables are set.
	- **Type:** boolean
	- **Default:** `true`

Pass them via the `args` property in the JSON configuration. For example:

```	{
	  "mcpServers": {
	    "chrome-devtools": {
	      "command": "npx",
	      "args": [
	        "chrome-devtools-mcp@latest",
	        "--channel=canary",
	        "--headless=true",
	        "--isolated=true"
	      ]
	    }
	  }
	}
```
### Connecting via WebSocket with custom headers
[](https://github.com/ChromeDevTools/chrome-devtools-mcp#connecting-via-websocket-with-custom-headers)

You can connect directly to a Chrome WebSocket endpoint and include custom headers (e.g., for authentication):

```
	{
	  "mcpServers": {
	    "chrome-devtools": {
	      "command": "npx",
	      "args": [
	        "chrome-devtools-mcp@latest",
	        "--wsEndpoint=ws://127.0.0.1:9222/devtools/browser/<id>",
	        "--wsHeaders={\"Authorization\":\"Bearer YOUR_TOKEN\"}"
	      ]
	    }
	  }
	}
```
To get the WebSocket endpoint from a running Chrome instance, visit `http://127.0.0.1:9222/json/version` and look for the `webSocketDebuggerUrl` field.

You can also run `npx chrome-devtools-mcp@latest --help` to see all available configuration options.

## Concepts
[](https://github.com/ChromeDevTools/chrome-devtools-mcp#concepts)

### User data directory
[](https://github.com/ChromeDevTools/chrome-devtools-mcp#user-data-directory)
`chrome-devtools-mcp` starts a Chrome's stable channel instance using the following user data directory:
- Linux / macOS: `$HOME/.cache/chrome-devtools-mcp/chrome-profile-$CHANNEL`
The user data directory is not cleared between runs and shared across all instances of `chrome-devtools-mcp`. Set the `isolated` option to `true` to use a temporary user data dir instead which will be cleared automatically after the browser is closed.

### Connecting to a running Chrome instance
[](https://github.com/ChromeDevTools/chrome-devtools-mcp#connecting-to-a-running-chrome-instance)
By default, the Chrome DevTools MCP server will start a new Chrome instance with a dedicated profile. This might not be ideal in all situations:
- If you would like to maintain the same application state when alternating between manual site testing and agent-driven testing.
- When the MCP needs to sign into a website. Some accounts may prevent sign-in when the browser is controlled via WebDriver (the default launch mechanism for the Chrome DevTools MCP server).
- If you're running your LLM inside a sandboxed environment, but you would like to connect to a Chrome instance that runs outside the sandbox.

In these cases, start Chrome first and let the Chrome DevTools MCP server connect to it. There are two ways to do so:
- **Automatic connection (available in Chrome 144)**: best for sharing state between manual and agent-driven testing.
- **Manual connection via remote debugging port**: best when running inside a sandboxed environment.

#### Automatically connecting to a running Chrome instance
[](https://github.com/ChromeDevTools/chrome-devtools-mcp#automatically-connecting-to-a-running-chrome-instance)

**Step 1:** Set up remote debugging in Chrome
In Chrome (\>= M144), do the following to set up remote debugging:
1. Navigate to `chrome://inspect/#remote-debugging` to enable remote debugging.
2. Follow the dialog UI to allow or disallow incoming debugging connections.

**Step 2:** Configure Chrome DevTools MCP server to automatically connect to a running Chrome Instance
To connect the `chrome-devtools-mcp` server to the running Chrome instance, use `--autoConnect` command line argument for the MCP server.
The following code snippet is an example configuration for gemini-cli:
```
	{
	  "mcpServers": {
	    "chrome-devtools": {
	      "command": "npx",
	      "args": ["chrome-devtools-mcp@latest", "--autoConnect", "--channel=beta"]
	    }
	  }
	}
```
Note: you have to specify `--channel=beta` until Chrome M144 has reached the stable channel.

**Step 3:** Test your setup
Make sure your browser is running. Open gemini-cli and run the following prompt:
	Check the performance of https://developers.chrome.com
Note
The `autoConnect` option requires the user to start Chrome. If the user has multiple active profiles, the MCP server will connect to the default profile (as determined by Chrome). The MCP server has access to all open windows for the selected profile.
The Chrome DevTools MCP server will try to connect to your running Chrome instance. It shows a dialog asking for user permission.
Clicking **Allow** results in the Chrome DevTools MCP server opening [developers.chrome.com](http://developers.chrome.com/) and taking a performance trace.

#### Manual connection using port forwarding
[](https://github.com/ChromeDevTools/chrome-devtools-mcp#manual-connection-using-port-forwarding)
You can connect to a running Chrome instance by using the `--browser-url` option. This is useful if you are running the MCP server in a sandboxed environment that does not allow starting a new Chrome instance.
Here is a step-by-step guide on how to connect to a running Chrome instance:

**Step 1: Configure the MCP client**
Add the `--browser-url` option to your MCP client configuration. The value of this option should be the URL of the running Chrome instance. `http://127.0.0.1:9222` is a common default.

```
	{
	  "mcpServers": {
	    "chrome-devtools": {
	      "command": "npx",
	      "args": [
	        "chrome-devtools-mcp@latest",
	        "--browser-url=http://127.0.0.1:9222"
	      ]
	    }
	  }
	}
```
**Step 2: Start the Chrome browser**

Warning

Enabling the remote debugging port opens up a debugging port on the running browser instance. Any application on your machine can connect to this port and control the browser. Make sure that you are not browsing any sensitive websites while the debugging port is open.
Start the Chrome browser with the remote debugging port enabled. Make sure to close any running Chrome instances before starting a new one with the debugging port enabled. The port number you choose must be the same as the one you specified in the `--browser-url` option in your MCP client configuration.
For security reasons, [Chrome requires you to use a non-default user data directory](https://developer.chrome.com/blog/remote-debugging-port) when enabling the remote debugging port. You can specify a custom directory using the `--user-data-dir` flag. This ensures that your regular browsing profile and data are not exposed to the debugging session.

**Linux**
	/usr/bin/google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-profile-stable

**Step 3: Test your setup**
After configuring the MCP client and starting the Chrome browser, you can test your setup by running a simple prompt in your MCP client:
	Check the performance of https://developers.chrome.com
Your MCP client should connect to the running Chrome instance and receive a performance report.
If you hit VM-to-host port forwarding issues, see the “Remote debugging between virtual machine (VM) and host fails” section in [`docs/troubleshooting.md`](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/troubleshooting.md#remote-debugging-between-virtual-machine-vm-and-host-fails).
For more details on remote debugging, see the [Chrome DevTools documentation](https://developer.chrome.com/docs/devtools/remote-debugging/).

