# Testing Plan: Workshop Scripts v1.1.0
**Date:** 2025-10-05
**Version:** 1.1.0
**Scope:** All 7 workshop scripts (Windows + macOS)

---

## Overview

This document provides a comprehensive testing plan for validating all workshop scripts before the Go to Agentic Conference 2025. All scripts have been upgraded to v1.1.0 with critical QA improvements.

---

## Test Environment Requirements

### Windows Test System
- **OS:** Windows 10/11 (64-bit)
- **RAM:** 8GB minimum, 16GB+ recommended
- **Disk:** 30GB free space
- **Software:**
  - Docker Desktop for Windows (latest)
  - WSL2 enabled and updated
  - PowerShell 5.1+ or PowerShell Core 7+
- **Network:** Internet connection for model downloads

### macOS Test System
- **OS:** macOS 12+ (Monterey or later)
- **RAM:** 8GB minimum, 16GB+ recommended
- **Disk:** 30GB free space
- **Software:**
  - Docker Desktop for Mac (latest)
  - Homebrew (for installing jq)
  - bash 4.0+ (pre-installed)
- **Network:** Internet connection for model downloads
- **Optional:** `jq` installed (`brew install jq`)

---

## Testing Matrix

| Test Scenario | Windows | macOS | Priority |
|--------------|---------|-------|----------|
| **Fresh Install** | ✓ | ✓ | CRITICAL |
| **Idempotency (Re-run)** | ✓ | ✓ | CRITICAL |
| **Model Already Downloaded** | ✓ | ✓ | HIGH |
| **Containers Already Running** | ✓ | ✓ | HIGH |
| **Docker Not Running** | ✓ | ✓ | HIGH |
| **Ollama Not Accessible** | ✓ | ✓ | HIGH |
| **Model Doesn't Exist** | ✓ | ✓ | HIGH |
| **Port Conflicts** | ✓ | ✓ | MEDIUM |
| **Low Disk Space** | ✓ | ✓ | MEDIUM |
| **No Internet Connection** | ✓ | ✓ | MEDIUM |
| **macOS: USE_HOST_OLLAMA** | - | ✓ | LOW |
| **Logging Enabled** | ✓ | ✓ | LOW |

---

## Test Procedures

### CRITICAL Test 1: Fresh Install Flow

**Objective:** Verify end-to-end setup on a clean system

**Windows:**
```powershell
# Prerequisites
# - Docker Desktop installed and running
# - No existing containers from this workshop

# Step 1: Run setup
.\scripts\setup-windows.ps1

# Expected Results:
# ✓ All prerequisite checks pass
# ✓ docker-compose.yml and .env copied to repo root
# ✓ Containers start successfully (ollama, n8n, open-webui, postgres)
# ✓ Health checks pass within 60s
# ✓ Interactive model download prompt appears
# ✓ End summary shows: containers started, model count, next steps

# Step 2: Verify installation
.\scripts\verify-windows.ps1

# Expected Results:
# ✓ All checks pass (Docker, containers, ports, HTTP endpoints, network, volumes)
# ✓ Model list displayed if models were downloaded
# ✓ "All checks passed!" message
# ✓ Next steps displayed

# Step 3: Measure performance
.\scripts\measure-cold-warm-windows.ps1 -Model "llama3.2:1b"

# Expected Results:
# ✓ Pre-flight checks pass (Ollama API, model exists, disk space)
# ✓ Cold start test completes (may take 1-5 minutes)
# ✓ Warm start tests complete (5 runs by default)
# ✓ Results saved to artifacts/performance/
# ✓ Capability summary displayed

# Step 4: Access services
# Open http://localhost:3000 (OpenWebUI)
# Open http://localhost:5678 (N8N)
# Verify both load successfully
```

**macOS:**
```bash
# Prerequisites
# - Docker Desktop installed and running
# - No existing containers from this workshop
# - jq installed (brew install jq)

# Step 1: Run setup
./scripts/setup-mac.sh

# Expected Results:
# ✓ All prerequisite checks pass
# ✓ docker-compose.yml and .env copied
# ✓ Containers start successfully
# ✓ Health checks pass within 60s
# ✓ End summary displayed

# Step 2: Verify installation
./scripts/verify-mac.sh

# Expected Results:
# ✓ All checks pass
# ✓ "All checks passed!" message

# Step 3: Measure performance (with optional model download)
PULL_MODEL=1 MODEL="llama3.2:1b" ./scripts/measure-cold-warm-mac.sh

# Expected Results:
# ✓ Model downloads if not present
# ✓ Pre-flight checks pass
# ✓ Cold and warm tests complete
# ✓ Results saved to artifacts/performance/

# Step 4: Access services
# Open http://localhost:3000
# Open http://localhost:5678
```

**Pass Criteria:**
- [ ] All scripts complete without errors
- [ ] All services accessible via web browser
- [ ] Model(s) downloaded successfully
- [ ] Performance results generated
- [ ] No manual intervention required

---

### CRITICAL Test 2: Idempotency

**Objective:** Verify scripts don't restart running containers

**Windows:**
```powershell
# Prerequisites: Fresh install completed (Test 1)

# Step 1: Re-run setup script
.\scripts\setup-windows.ps1

# Expected Results:
# ✓ Detects running containers
# ✓ Prompts: "Restart containers? (y/N)"
# ✓ If N: "Using existing containers (no changes made)"
# ✓ If Y: Containers restart gracefully
# ✓ Model download prompt shows existing models
# ✓ When selecting same model: "Model already downloaded. Skipping."

# Step 2: Verify no downtime
# Keep http://localhost:3000 open in browser during test
# Page should remain accessible (if answered "N")

# Step 3: Check docker-compose.yml and .env
ls

# Expected Results:
# ✓ Files exist and not duplicated
# ✓ Message: "docker-compose.yml already exists (skipping)"
# ✓ Message: ".env file already exists (skipping)"
```

**macOS:**
```bash
# Prerequisites: Fresh install completed

# Step 1: Re-run setup
./scripts/setup-mac.sh

# Expected Results:
# ✓ Detects running containers
# ✓ Prompts for restart (default: N)
# ✓ Existing config files skipped

# Step 2: Re-run with model pull
PULL_MODEL=1 MODEL="llama3.2:1b" ./scripts/setup-mac.sh

# Expected Results:
# ✓ Detects existing model
# ✓ Message: "Model 'llama3.2:1b' already exists. Skipping download."
```

**Pass Criteria:**
- [ ] No unnecessary container restarts
- [ ] Config files not re-copied
- [ ] Models not re-downloaded
- [ ] User prompted for confirmation
- [ ] Services remain accessible (if no restart)

---

### HIGH Test 3: Error Handling - Docker Not Running

**Objective:** Verify clear error messages when Docker is unavailable

**Windows:**
```powershell
# Step 1: Stop Docker Desktop
# Right-click Docker icon → Quit Docker Desktop

# Step 2: Run setup script
.\scripts\setup-windows.ps1

# Expected Results:
# ✓ Error: "Docker daemon is not running!"
# ✓ Troubleshooting steps displayed:
#   - Start Docker Desktop from Windows Start Menu
#   - Wait 30-60 seconds
#   - Look for Docker icon in system tray
#   - If WSL2 errors, run: wsl --update
#   - Retry script
# ✓ Script exits with code 1

# Step 3: Run verify script (Docker still stopped)
.\scripts\verify-windows.ps1

# Expected Results:
# ✓ First check fails: "Docker daemon is NOT running"
# ✓ Prioritized troubleshooting appears
# ✓ Priority 1: "Docker daemon is not running"
# ✓ Clear instructions to start Docker
```

**macOS:**
```bash
# Step 1: Quit Docker Desktop
# Click Docker icon → Quit Docker Desktop

# Step 2: Run setup
./scripts/setup-mac.sh

# Expected Results:
# ✓ Error: "Docker daemon is not running."
# ✓ Troubleshooting steps displayed
# ✓ Script exits with code 1

# Step 3: Run verify
./scripts/verify-mac.sh

# Expected Results:
# ✓ "Docker daemon is NOT running" (critical error)
# ✓ Prioritized troubleshooting displayed
```

**Pass Criteria:**
- [ ] Error detected immediately
- [ ] Clear, actionable instructions provided
- [ ] No cryptic error messages
- [ ] Script exits gracefully
- [ ] User knows exactly what to do next

---

### HIGH Test 4: Error Handling - Model Doesn't Exist

**Objective:** Verify helpful error when requesting non-existent model

**Windows:**
```powershell
# Prerequisites: Ollama running with at least one model

# Step 1: Run measurement with fake model
.\scripts\measure-cold-warm-windows.ps1 -Model "fake-model-12345"

# Expected Results:
# ✓ Pre-flight check fails: "Model 'fake-model-12345' not found"
# ✓ Lists available models:
#   • llama3.2:1b
#   • llama3.2
#   (etc.)
# ✓ Shows download command:
#   docker exec -it ollama ollama pull fake-model-12345
# ✓ Shows alternative:
#   .\scripts\measure-cold-warm-windows.ps1 -Model 'llama3.2'
# ✓ Script exits with code 1
```

**macOS:**
```bash
# Step 1: Run with non-existent model
MODEL="nonexistent" ./scripts/measure-cold-warm-mac.sh

# Expected Results:
# ✓ Pre-flight check fails
# ✓ Available models listed
# ✓ Download command provided
# ✓ Alternative invocation shown
```

**Pass Criteria:**
- [ ] Error caught in pre-flight (not mid-test)
- [ ] Available models listed
- [ ] Clear instructions to download or use different model
- [ ] No confusing stack traces

---

### HIGH Test 5: Port Conflicts

**Objective:** Verify detection and guidance for port conflicts

**Setup:**
```powershell
# Windows: Start a process on port 5678
python -m http.server 5678

# macOS:
python3 -m http.server 5678
```

**Test:**
```powershell
# Windows
.\scripts\setup-windows.ps1

# Expected Results:
# ✓ docker-compose up fails
# ✓ Error message includes:
#   "Check for port conflicts:"
#   netstat -ano | findstr ":5678 :3000 :11434 :5432"
# ✓ Suggests checking logs
# ✓ Suggests restarting Docker
```

```bash
# macOS
./scripts/setup-mac.sh

# Expected Results:
# ✓ Error includes port conflict check:
#   lsof -iTCP:5678,3000,11434,5432 -sTCP:LISTEN
```

**Cleanup:**
```
# Kill the Python server (Ctrl+C)
```

**Pass Criteria:**
- [ ] Port conflict suggested as possible cause
- [ ] Platform-specific command provided
- [ ] Clear next steps

---

### MEDIUM Test 6: Low Disk Space Warning

**Objective:** Verify disk space warnings appear

**Note:** This test requires actually low disk space OR mocking (modify script temporarily)

**Expected Behavior:**
- Measurement scripts check disk space
- If < 5GB free: Warning displayed
- Script continues (warning, not error)

---

### MEDIUM Test 7: No Internet Connection

**Objective:** Model download fails gracefully

**Setup:**
```
# Disable network adapter temporarily
# OR disconnect from Wi-Fi
```

**Test:**
```powershell
# Windows
.\scripts\setup-windows.ps1
# Choose to download model when prompted

# Expected Results:
# ✓ Model download fails
# ✓ Error message:
#   "Troubleshooting:"
#   • Check internet connection
#   • Verify Ollama container running
#   • Check Ollama logs
#   • Retry manually: docker exec -it ollama ollama pull ...
# ✓ Message: "You can continue and download models later."
# ✓ Script completes (doesn't crash)
```

**Pass Criteria:**
- [ ] Download failure handled gracefully
- [ ] Troubleshooting steps include internet check
- [ ] Script doesn't crash
- [ ] User can continue without model

---

### LOW Test 8: Logging Enabled

**Objective:** Verify optional logging works

**Windows:**
```powershell
$env:ENABLE_LOGGING="1"
.\scripts\setup-windows.ps1

# Expected Results:
# ✓ Message at start: "Logging enabled. Transcript will be saved to: setup-YYYYMMDD-HHMMSS.log"
# ✓ All output visible in console
# ✓ Message at end: "Log saved to: setup-YYYYMMDD-HHMMSS.log"
# ✓ Log file exists in current directory
# ✓ Log file contains all console output
```

**macOS:**
```bash
ENABLE_LOGGING=1 ./scripts/setup-mac.sh

# Expected Results:
# ✓ Message: "Logging enabled. Output will be saved to: setup-YYYYMMDD-HHMMSS.log"
# ✓ Log file created
# ✓ Log contains all output
```

**Pass Criteria:**
- [ ] Logging opt-in (not forced)
- [ ] Log file created with timestamp
- [ ] All output captured
- [ ] Log path displayed to user

---

### LOW Test 9: macOS Host Ollama (Metal Acceleration)

**Objective:** Verify USE_HOST_OLLAMA=1 works on macOS

**Prerequisites:**
- macOS with Apple Silicon (M1/M2/M3)
- Ollama installed on host: `brew install ollama`
- Ollama service running: `ollama serve` (in background)

**Test:**
```bash
USE_HOST_OLLAMA=1 ./scripts/setup-mac.sh

# Expected Results:
# ✓ Message: "Host Ollama detected and USE_HOST_OLLAMA=1"
# ✓ Message: "Using host Ollama via configs/docker-compose.ollama-host.yml"
# ✓ Message: "Starting OpenWebUI, n8n, and postgres (no ollama container)"
# ✓ Only 3 containers started (no ollama container)
# ✓ OpenWebUI connects to host Ollama at host.docker.internal:11434
# ✓ Summary shows: "using host Ollama"

# Verify OpenWebUI can talk to host Ollama
curl http://localhost:11434/api/tags  # Should work
docker ps  # Should NOT show ollama container
```

**Pass Criteria:**
- [ ] No ollama container started
- [ ] OpenWebUI connects to host Ollama
- [ ] Model list accessible from host
- [ ] Summary reflects host configuration

---

## Regression Testing

### Before Each Test Run
1. ✓ Stop all containers: `docker-compose down`
2. ✓ Remove volumes (if testing fresh install): `docker volume prune`
3. ✓ Delete artifacts: `rm -rf artifacts/performance/*`
4. ✓ Delete logs: `rm -f setup-*.log verify-*.log`
5. ✓ Delete docker-compose.yml and .env from repo root (if testing file copy)

### After Each Test Run
1. ✓ Check for leftover processes
2. ✓ Verify no port conflicts remain
3. ✓ Document any unexpected behavior
4. ✓ Save screenshots of errors (if any)

---

## Success Criteria Summary

### All Tests Must Pass
- ✓ **Fresh install**: Complete end-to-end flow works
- ✓ **Idempotency**: Re-running doesn't restart containers
- ✓ **Error handling**: Clear, actionable error messages
- ✓ **Docker not running**: Detected and explained
- ✓ **Model missing**: Lists available models
- ✓ **Port conflicts**: Suggests troubleshooting command

### Acceptable Warnings
- ⚠ Low disk space (warning, not error)
- ⚠ jq not installed on macOS (for verify script, degrades gracefully)
- ⚠ Container health timeout (warns, but continues)

### Unacceptable Failures
- ✗ Script crashes without explanation
- ✗ Cryptic PowerShell/Bash error messages
- ✗ No troubleshooting guidance
- ✗ Data loss (containers restarted without warning)
- ✗ Silent failures (script reports success when it failed)

---

## Testing Timeline

### Day 1: Windows Testing (4 hours)
- Fresh install flow (1 hour)
- Idempotency tests (30 min)
- Error handling tests (1.5 hours)
- Edge cases (1 hour)

### Day 2: macOS Testing (4 hours)
- Fresh install flow (1 hour)
- Idempotency tests (30 min)
- Error handling tests (1 hour)
- USE_HOST_OLLAMA test (30 min)
- Edge cases (1 hour)

### Day 3: Cross-Platform Verification (2 hours)
- Verify parity between Windows and macOS
- Test logging feature on both
- Final regression run

### Day 4: Workshop Dry Run (1 hour)
- Simulate workshop attendee experience
- Time each step
- Document any friction points

**Total Estimated Time:** 11 hours

---

## Bug Reporting Template

When a test fails, document using this format:

```markdown
## Bug Report

**Script:** setup-windows.ps1
**Test:** Fresh Install Flow
**OS:** Windows 11 Pro 24H2
**Docker Version:** 4.25.0

**Steps to Reproduce:**
1. ...
2. ...

**Expected Result:**
...

**Actual Result:**
...

**Error Message:**
```
[paste error]
```

**Screenshots:**
[attach if applicable]

**Workaround:**
[if found]

**Severity:** Critical / High / Medium / Low
```

---

## Post-Testing Checklist

Before workshop:
- [ ] All CRITICAL tests pass on Windows
- [ ] All CRITICAL tests pass on macOS
- [ ] All HIGH tests pass on both platforms
- [ ] Documentation updated with any caveats
- [ ] Known issues documented in TROUBLESHOOTING.md
- [ ] Scripts uploaded to repository
- [ ] Workshop dry run completed successfully
- [ ] Rollback plan prepared (if needed)

---

## Rollback Plan

If critical bugs are found close to workshop date:

**Option 1: Revert to v1.0.0**
- Remove v1.1.0 scripts
- Use original simple versions
- Accept lower error handling quality

**Option 2: Hotfix**
- Fix critical bugs only
- Skip nice-to-have features
- Release as v1.1.1

**Option 3: Documentation Workaround**
- Document known issues prominently
- Provide manual workarounds
- Have support staff ready

---

## Contact for Testing Issues

**Developer:** Senior Developer (implementation lead)
**QA Lead:** Senior QA Specialist
**Workshop Lead:** dehmohforugh@gmail.com

---

**Last Updated:** 2025-10-05
**Testing Status:** NOT STARTED
**Target Completion:** 4 days before workshop
