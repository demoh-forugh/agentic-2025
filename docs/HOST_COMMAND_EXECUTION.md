# Host Command Execution from n8n Container

This guide explains how to execute commands on your Windows host machine from n8n running in a Podman container, without requiring administrator privileges.

## Overview

The solution uses **file-based communication** through a shared directory:
1. n8n (in container) writes command requests as JSON files
2. PowerShell script (on host) watches the directory and executes commands
3. Results are written back as JSON response files
4. n8n reads the response and continues workflow

## Architecture

```
┌─────────────────────────────────────┐
│   n8n Container                     │
│                                     │
│   /shared/commands/  ← Write cmd    │
│   /shared/responses/ ← Read result  │
└──────────────┬──────────────────────┘
               │ Volume Mount
               │ C:\Code\agentic-2025\shared
┌──────────────┴──────────────────────┐
│   Windows Host                      │
│                                     │
│   PowerShell Listener               │
│   - Watches commands/               │
│   - Executes PowerShell             │
│   - Writes to responses/            │
└─────────────────────────────────────┘
```

## Setup Instructions

### Step 1: Start the Command Listener on Windows Host

Open a PowerShell window and run:

```powershell
cd C:\Code\agentic-2025
.\scripts\command-listener.ps1
```

You should see:
```
File-based command executor started...
Watching: C:\Code\agentic-2025\shared\commands
Responses: C:\Code\agentic-2025\shared\responses
Press Ctrl+C to stop
```

**Keep this window open** while you want to execute commands from n8n.

### Step 2: Mount Shared Directory in Podman Container

You need to add a volume mount to your n8n container. Update your `docker-compose.yml` or `podman-compose.yml`:

```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
      - C:\Code\agentic-2025\shared:/shared  # Add this line
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      # ... other env vars
```

**For Windows with Podman**, you may need to use forward slashes:

```yaml
volumes:
  - C:/Code/agentic-2025/shared:/shared
```

Restart your n8n container:

```powershell
podman-compose down
podman-compose up -d
```

### Step 3: Test from Command Line

Test the system before using it in n8n:

```powershell
# From Windows host
.\scripts\test-command.ps1 -Command "Get-Date"

# Expected output:
# Command submitted: <guid>
# Waiting for response...
# Response received:
# Command: Get-Date
# Output: Friday, October 11, 2025 10:30:45 AM
```

### Step 4: Use from n8n Workflows

#### Option A: Execute Node with Shell Script

In your n8n workflow, add an **Execute Command** node:

**Node Configuration:**
- **Command:** `bash`
- **Arguments (as array):**
  - `/shared/send-command.sh`
  - `Get-ChildItem C:\Code\agentic-2025 -Name`

**Alternative - inline script:**

**Command:** `bash`
**Arguments:**
```
-c
cd /shared && ./send-command.sh "dir C:\"
```

#### Option B: Write/Read Files Directly

For more control, use **Read/Write Binary File** nodes:

**1. Write Command File:**
- Node: **Write Binary File**
- File Path: `/shared/commands/{{ $json.id }}.json`
- Data (JSON):
```json
{
  "command": "Get-ChildItem C:\Code\agentic-2025 -Name",
  "timestamp": "{{ $now.toISO() }}"
}
```

**2. Wait for Response:**
- Node: **Wait** (500ms)

**3. Read Response File:**
- Node: **Read Binary File**
- File Path: `/shared/responses/{{ $json.id }}.json`

**4. Parse JSON:**
- Node: **Set**
- Expression: `{{ $json.data.toString() }}`
- Parse as JSON

**5. Delete Response File:**
- Node: **Execute Command**
- Command: `rm /shared/responses/{{ $json.id }}.json`

## Command Examples

### List Directory Contents

**PowerShell Command:**
```powershell
Get-ChildItem C:\Code\agentic-2025 -Name
```

**From n8n:**
```bash
./send-command.sh "Get-ChildItem C:\Code\agentic-2025 -Name"
```

### Get System Information

**PowerShell Command:**
```powershell
Get-ComputerInfo | Select-Object CsName, OsVersion, OsTotalVisibleMemorySize
```

### Read File Contents

**PowerShell Command:**
```powershell
Get-Content C:\Code\agentic-2025\README.md -TotalCount 10
```

### Check Running Containers

**PowerShell Command:**
```powershell
podman ps --format "{{.Names}}: {{.Status}}"
```

### Get Environment Variables

**PowerShell Command:**
```powershell
Get-ChildItem Env: | Where-Object Name -like "N8N*"
```

## Security Considerations

This system runs commands with **your user privileges** (no admin). Be aware:

- Any command n8n sends will be executed on your host
- Commands run with your user account permissions
- No authentication/authorization built in
- Recommended for local development only

**Security Recommendations:**

1. **Restrict n8n access** - Use n8n's authentication
2. **Whitelist commands** - Modify listener to only allow specific commands
3. **Read-only operations** - Prefer `Get-*` commands over `Set-*`, `Remove-*`, etc.
4. **Network isolation** - Don't expose n8n to untrusted networks

### Example: Whitelist Commands

Edit `scripts/command-listener.ps1` to add validation:

```powershell
# Add after line 25 (Get-Content $cmdFile...)
$allowedCommands = @(
    "Get-ChildItem",
    "Get-Content",
    "Get-Date",
    "podman ps"
)

$isAllowed = $false
foreach ($allowed in $allowedCommands) {
    if ($command -like "$allowed*") {
        $isAllowed = $true
        break
    }
}

if (-not $isAllowed) {
    $output = "ERROR: Command not in whitelist"
    # ... write error response
    continue
}
```

## Troubleshooting

### "Access is denied" Error

This was the original HttpListener error. The file-based approach avoids this entirely.

### Commands Not Being Processed

**Check:**
1. Is the listener running? Look for the PowerShell window
2. Is the shared directory mounted in the container?
   ```bash
   podman exec -it n8n ls -la /shared
   ```
3. Are command files being created?
   ```powershell
   Get-ChildItem C:\Code\agentic-2025\shared\commands
   ```

### Container Can't Access /shared

**Verify mount in container:**
```bash
podman exec -it n8n bash
ls -la /shared
# Should show: commands/  responses/
```

**Check Podman mount:**
```powershell
podman inspect n8n | Select-String -Pattern "shared"
```

### Listener Stops Responding

**Restart the listener:**
1. Close the PowerShell window (Ctrl+C)
2. Reopen and run: `.\scripts\command-listener.ps1`

### JSON Parse Errors in n8n

The response is a JSON string. Use **JSON Parse** node or expression:
```javascript
{{ JSON.parse($json.data.toString()) }}
```

## Example n8n Workflow

Here's a complete workflow that checks disk space:

```json
{
  "nodes": [
    {
      "name": "Schedule",
      "type": "n8n-nodes-base.cron",
      "position": [250, 300],
      "parameters": {
        "triggerTimes": {
          "item": [
            {
              "hour": 9,
              "minute": 0
            }
          ]
        }
      }
    },
    {
      "name": "Check Disk Space",
      "type": "n8n-nodes-base.executeCommand",
      "position": [450, 300],
      "parameters": {
        "command": "bash",
        "arguments": [
          "/shared/send-command.sh",
          "Get-PSDrive C | Select-Object Used,Free"
        ]
      }
    },
    {
      "name": "Parse Response",
      "type": "n8n-nodes-base.set",
      "position": [650, 300],
      "parameters": {
        "values": {
          "string": [
            {
              "name": "diskInfo",
              "value": "={{ $json.stdout }}"
            }
          ]
        }
      }
    }
  ]
}
```

## Performance

- **Latency:** ~100-500ms per command
- **Throughput:** ~2-10 commands/second
- **Limits:** File system I/O speed

For high-frequency operations, consider batching commands or using a proper API.

## Alternative Approaches

If this solution doesn't meet your needs, consider:

1. **SSH Server** - Install OpenSSH server (requires setup)
2. **PowerShell Remoting** - Enable PSRemoting (requires admin for initial setup)
3. **REST API** - Build a simple web API in PowerShell (requires more code)
4. **Podman host networking** - Use `--network host` (exposes all ports)

## Files Reference

- `scripts/command-listener.ps1` - Windows host listener (scripts/command-listener.ps1:1)
- `scripts/test-command.ps1` - Test script for local validation (scripts/test-command.ps1:1)
- `scripts/send-command.sh` - Helper script for use inside container (scripts/send-command.sh:1)
- `shared/commands/` - Directory where command requests are written
- `shared/responses/` - Directory where command results are written
