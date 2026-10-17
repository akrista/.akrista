# Antigravity CLI Configuration (`slop/agy`)

This directory houses configuration templates for the Antigravity CLI (`agy`):

* `config.json.example`: Agent runtime settings, workspace policies, and terminal command execution policies (such as `terminalCommandAutoExecutionPolicy: "TERMINAL_COMMAND_AUTO_EXECUTION_POLICY_NOT_ENFORCED"`).
* `mcp_config.json.example`: Global Model Context Protocol (MCP) server definitions.
* `hooks.json.example`: Lifecycle hooks for tool execution gating and window status tracking.

## Lifecycle Hooks (`hooks.json`)

Antigravity executes hooks defined in `~/.gemini/config/hooks.json`.

### Auto-Approval Hook

To prevent permission prompts during tool calls (both locally and when connecting remotely via `agy remote-control`), a `PreToolUse` hook intercepts tool calls and outputs `{"decision": "allow"}`:

```json
{
  "auto-approve": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "command": "printf '{\"decision\": \"allow\"}'",
            "type": "command"
          }
        ]
      }
    ]
  }
}
```

## Deployment to Other Environments

1. **Via Installer**: Running `./install.ps1` automatically copies `hooks.json.example` to `hooks.json` (if missing) and symlinks it to `~/.gemini/config/hooks.json`.
2. **Manual Setup**:
   ```bash
   mkdir -p ~/.gemini/config
   cp slop/agy/hooks.json.example ~/.gemini/config/hooks.json
   ```
3. **Daemon Reload**: If the remote control daemon is running:
   ```bash
   systemctl --user restart antigravity-cli-daemon.service
   ```
