# Mac Testing Checklist

## Pre-Testing Requirements

### System Prerequisites
- macOS 12.0 (Monterey) or later
- 16GB RAM recommended (8GB minimum)
- 20GB free disk space
- Internet connection for Docker image downloads

### Software Installation
- Docker Desktop for Mac (installed and running)
- Terminal app (built-in to macOS)

---

## Testing Sequence

### Phase 1: Documentation Review (5 minutes)

1. **Read QUICK_START.md**
   - Navigate to: `docs/QUICK_START.md`
   - Follow the "Prerequisites (macOS)" section
   - Verify Terminal navigation instructions are clear
   - Confirm all commands are copy-paste ready

2. **Read INSTALLATION.md**
   - Navigate to: `docs/INSTALLATION.md`
   - Follow "Step 1: Install Docker Desktop for Mac"
   - Verify instructions match actual Docker Desktop installer
   - Check if Apple Silicon vs Intel differentiation is clear

### Phase 2: Script Permissions (1 minute)

**Before running scripts, make them executable:**

```bash
# Navigate to repository root
cd ~/Downloads/demos  # Adjust to your actual path

# Make scripts executable (required on macOS)
chmod +x ./scripts/setup-mac.sh ./scripts/verify-mac.sh ./scripts/measure-cold-warm-mac.sh
```

**Common Issue:** "Permission denied" errors occur if this step is skipped. See `docs/TROUBLESHOOTING.md` → "Script Permission Denied (macOS/Linux)" if needed.

### Phase 3: Automated Setup (10-15 minutes)

**Run the setup script:**

```bash
./scripts/setup-mac.sh
```

**What to verify:**
- ✅ Script detects Docker is running
- ✅ Script shows system specs (RAM, CPU, GPU)
- ✅ Script recommends appropriate model
- ✅ All 4 containers start successfully (ollama, n8n, open-webui, postgres)
- ✅ Health checks pass (or timeout with clear error message)
- ✅ Model download prompt appears
- ✅ If errors occur, troubleshooting steps are actionable

**Expected output:**
```
=======================================================
   n8n Workshop Setup Script v1.1.1 (macOS)
=======================================================

[info] Checking Docker...
[OK] Docker is installed
[OK] Docker daemon is running

System Specifications:
  RAM:       16.0 GB total, 12.3 GB available
  CPU:       8 cores
  GPU:       None detected

[info] Starting containers...
[info] Waiting for containers to become healthy (timeout: 60s)...
[OK] Container 'ollama' is healthy
[OK] Container 'n8n' is healthy
[OK] Container 'open-webui' is healthy
[OK] Container 'postgres' is healthy

=======================================================
   Setup Complete! [OK]
=======================================================
```

### Phase 4: Verification (5 minutes)

**Run the verification script:**

```bash
./scripts/verify-mac.sh
```

**What to verify:**
- ✅ Docker daemon check passes
- ✅ All 4 containers are running
- ✅ Ports are mapped correctly (11434, 3000, 5678, 5432)
- ✅ HTTP endpoints are accessible
- ✅ If model downloaded, it appears in model list
- ✅ If errors occur, troubleshooting is prioritized correctly

**Expected output:**
```
=======================================================
   Installation Verification v1.1.1
=======================================================

[info] Checking Docker...
[OK] Docker is installed: Docker version 24.0.6
[OK] Docker daemon is running
[OK] Docker daemon is responsive (v24.0.6)

[info] Checking containers...
[OK] Container 'ollama' is running
[OK] Container 'open-webui' is running
[OK] Container 'n8n' is running
[OK] Container 'postgres' is running

[info] Checking ports...
[OK] Port 11434 (Ollama) mapped correctly: 0.0.0.0:11434
[OK] Port 3000 (OpenWebUI) mapped correctly: 0.0.0.0:3000
[OK] Port 5678 (n8n) mapped correctly: 0.0.0.0:5678
[OK] Port 5432 (PostgreSQL) mapped correctly: 0.0.0.0:5432

[info] Checking HTTP endpoints...
[OK] Ollama API is accessible
[OK] n8n web interface is accessible
[OK] OpenWebUI is accessible
[OK] PostgreSQL port is mapped: 0.0.0.0:5432->5432/tcp

=======================================================
   All checks passed! [OK]
=======================================================

Your workshop environment is ready!
```

### Phase 5: Web Interface Testing (10 minutes)

**Test OpenWebUI:**
1. Open: http://localhost:3000
2. Create account (any email works, e.g., `test@example.com`)
3. Select model from dropdown (e.g., `llama3.2` or `llama3.2:1b`)
4. Send test message: "What is AI automation?"
5. Verify response appears

**Test n8n:**
1. Open: http://localhost:5678
2. Create n8n account (stored locally)
3. Verify workflow canvas appears
4. Click "..." menu → "Import from File"
5. Navigate to repository → `workflows/` folder
6. Import `01-hello-world.json`
7. **Create Ollama Credential:**
   - Click the "Ollama Chat Model" node
   - Click "Credential to connect with" dropdown
   - Select "Create New Credential"
   - **IMPORTANT:** Change Base URL from `http://localhost:11434` to `http://ollama:11434`
   - Click "Save" (should turn green when connection succeeds)
8. Click "Execute Workflow"
9. Verify AI response appears in "Format Response" node

### Phase 6: Performance Measurement (Optional, 5 minutes)

**Run performance benchmark:**

```bash
./scripts/measure-cold-warm-mac.sh
```

**What to verify:**
- ✅ Script checks Ollama API is accessible
- ✅ Script verifies model exists before testing
- ✅ Cold start test completes (may take 1-5 minutes)
- ✅ Warm start tests complete (5 iterations by default)
- ✅ Results saved to `artifacts/performance/` with timestamp
- ✅ Summary shows speedup factor and performance metrics

---

## Common Issues & Fixes

### Issue 1: "Permission denied" when running scripts

**Fix:**
```bash
chmod +x ./scripts/setup-mac.sh ./scripts/verify-mac.sh
```

**Reference:** `docs/TROUBLESHOOTING.md` → "Script Permission Denied (macOS/Linux)"

### Issue 2: Docker Desktop not running

**Symptoms:** Setup script fails with "Docker daemon is NOT running"

**Fix:**
1. Open Docker Desktop from Applications folder
2. Wait 30-60 seconds for initialization
3. Look for Docker whale icon in menu bar (should be solid, not animated)
4. Run setup script again

**Reference:** `docs/TROUBLESHOOTING.md` → "Docker Desktop won't start (macOS)"

### Issue 3: Port 3000, 5678, or 11434 already in use

**Symptoms:** Containers fail to start with "address already in use" error

**Fix:**
```bash
# Check what's using the port
lsof -iTCP:3000 -sTCP:LISTEN
lsof -iTCP:5678 -sTCP:LISTEN
lsof -iTCP:11434 -sTCP:LISTEN

# Stop conflicting process or edit docker-compose.yml to use different ports
```

**Reference:** `docs/TROUBLESHOOTING.md` → "Port conflicts"

### Issue 4: Ollama credential shows localhost:11434 instead of ollama:11434

**Symptoms:** After creating Ollama credential in n8n, Base URL is pre-filled with `localhost:11434`

**This is expected behavior** - users must manually change it to `http://ollama:11434` (Docker container hostname).

**Reference:** `docs/INSTALLATION.md` → "Import Your First Workflow" step 7

### Issue 5: Model download takes forever or fails

**Symptoms:** Setup script hangs during model download, or Ollama container crashes

**Fix:**
1. Use smaller model: `llama3.2:1b` (1GB) instead of `llama3.2` (4GB)
2. Check internet connection
3. Verify sufficient disk space: `docker system df`
4. Increase Docker memory: Docker Desktop → Settings → Resources

**Reference:** `docs/TROUBLESHOOTING.md` → "Model download fails"

---

## Testing Checklist Summary

- [ ] Documentation is clear and easy to follow
- [ ] Script permissions issue is documented and fixable
- [ ] Setup script completes without errors
- [ ] Verification script passes all checks
- [ ] OpenWebUI loads and responds to prompts
- [ ] n8n loads and workflow import works
- [ ] Ollama credential creation works (with manual Base URL change)
- [ ] Workflow execution produces AI responses
- [ ] Performance measurement script runs successfully
- [ ] Troubleshooting guide addresses actual issues encountered

---

## Reporting Issues

If you encounter issues during testing, please document:

1. **macOS version**: `sw_vers`
2. **Docker version**: `docker --version`
3. **System specs**: RAM, CPU, disk space
4. **Exact error message** from script output
5. **What step failed** (setup, verification, web interface, workflow)
6. **Whether troubleshooting steps helped** or not

This feedback will help improve the Mac setup experience!

---

**Last Updated:** 2025-10-05
**Version:** 1.1.1
**Target Conference:** Go to Agentic Conference 2025
