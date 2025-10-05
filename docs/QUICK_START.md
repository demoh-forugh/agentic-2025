# Quick Start Guide

Get up and running in 15 minutes! ⚡

> **✨ NEW in v1.1.0:** Setup scripts now include idempotency (won't restart already-running containers), comprehensive health checks, and improved error messages with actionable troubleshooting!

---

## Prerequisites

### Minimum Requirements
- **OS**: Windows 10/11 with WSL2
- **RAM**: 8GB (16GB+ recommended)
- **Storage**: 20GB free disk space
- **Docker**: Docker Desktop installed and running

### Demo System (What This Was Tested On)
- **OS**: Windows 11 Pro 24H2 (Build 26100)
- **CPU**: AMD Ryzen 9 3900X (12 cores, 24 threads)
- **RAM**: 128GB DDR4 @ 3200MHz
- **GPU**: NVIDIA GeForce RTX 4090 (24GB VRAM)
- **Storage**: 2TB PCIe NVMe SSD
- See [SYSTEM_SPECS.md](./SYSTEM_SPECS.md#performance-metrics-from-demo-system) for measured performance results and methodology.

**💡 Tips**: 
- The first request pays the model load cost; keep the container warm for fast responses
- GPU acceleration improves throughput but is NOT required (CPU-only runs are supported)
- If you have 8GB RAM, start with `llama3.2:1b` (1GB model)

---

## 5-Minute Setup

### 1. Clone or Download Workshop Files

```powershell
# If you have git
git clone <workshop-repo-url>
cd demos

# Or download and extract ZIP file
```

### 2. Run Setup Script

```powershell
# Windows: Run automated setup
.\scripts\setup-windows.ps1

# Optional: Enable detailed logging
$env:ENABLE_LOGGING="1"
.\scripts\setup-windows.ps1
```

```bash
# macOS: Run automated setup
./scripts/setup-mac.sh

# Optional: Enable detailed logging
ENABLE_LOGGING=1 ./scripts/setup-mac.sh
```

**What the setup script does:**
- ✓ Check prerequisites (Docker, disk space, network)
- ✓ Detect already-running containers (won't restart unnecessarily)
- ✓ Start Docker containers with health checks
- ✓ Download an LLM model (optional, skips if already present)
- ✓ Provide detailed troubleshooting if anything fails

**Smart features in v1.1.0:**
- **Idempotency**: If containers are already running, prompts before restarting
- **Health Checks**: Waits up to 60s for each container to be healthy
- **Pre-flight Validation**: Checks Docker daemon, disk space, and network before starting
- **Actionable Errors**: Every error includes specific commands to fix it

### 3. Verify Installation

```powershell
# Windows
.\scripts\verify-windows.ps1
```

```bash
# macOS
./scripts/verify-mac.sh
```

**What the verification script checks:**
- ✓ Docker daemon health
- ✓ All 4 containers running (ollama, n8n, open-webui, postgres)
- ✓ Ports correctly mapped (11434, 5678, 3000, 5432)
- ✓ HTTP endpoints accessible
- ✓ Ollama models available
- ✓ Container resource usage

**Improved in v1.1.0:**
- **Prioritized Troubleshooting**: Errors shown in fix-order (Docker → Containers → Ports → Endpoints)
- **Container Status Differentiation**: Distinguishes between stopped vs missing containers
- **Smart Model Guidance**: Suggests specific models based on your RAM

---

## Manual Setup (Alternative)

If you prefer manual control:

```powershell
# 1. Copy configuration
copy configs\docker-compose.yml .
copy configs\.env.example .env

# 2. Start services
docker-compose up -d

# 3. Download a model
docker exec -it ollama ollama pull llama3.2

# 4. Check status
docker-compose ps
```

---

## Using Host-Installed Ollama (Advanced)

If you have Ollama already installed on your host machine (e.g., macOS with Metal GPU acceleration), you can use it instead of the containerized version:

```bash
# macOS/Linux: Use host Ollama with Metal/CUDA acceleration
docker compose -f configs/docker-compose.yml -f configs/docker-compose.ollama-host.yml up -d open-webui n8n postgres

# This configuration:
# - Points OpenWebUI to http://host.docker.internal:11434
# - Skips starting the ollama container
# - Allows you to use native GPU acceleration on the host
```

**Prerequisites:**
- Ollama installed on host: `https://ollama.com/download`
- Ollama running on default port 11434: `ollama serve`
- At least one model downloaded: `ollama pull llama3.2`

**Benefits:**
- Better GPU performance on macOS (Metal) or Windows (CUDA)
- Easier model management from host
- Reduced Docker resource usage

---

## Access Your Services

Once running, open these in your browser:

| Service | URL | Purpose |
|---------|-----|---------|
| **OpenWebUI** | http://localhost:3000 | Chat with your LLM |
| **n8n** | http://localhost:5678 | Build workflows |
| **Ollama API** | http://localhost:11434 | LLM API endpoint |

---

## First Steps

### 1. Set Up OpenWebUI (2 minutes)

1. Go to http://localhost:3000
2. Click "Sign Up" (stored locally)
3. Create an account with any email
4. Select your model from dropdown (e.g., `llama3.2`)
5. Start chatting!

### 2. Set Up n8n (3 minutes)

1. Go to http://localhost:5678
2. Create your account (first-time setup)
3. You'll see the workflow canvas

### 3. Import Your First Workflow (5 minutes)

1. In n8n, click "**...**" menu (top right) → "**Import from File**"
2. Select `workflows/01-hello-world.json`
3. Click "**Execute Workflow**"
4. See your LLM respond! 🎉

---

## Common Commands

### Manage Services

```powershell
# Start everything
docker-compose up -d

# Stop everything
docker-compose down

# Restart a service
docker-compose restart ollama

# View logs
docker-compose logs -f
docker-compose logs ollama --tail=50

# Check status
docker-compose ps
```

### Manage Ollama Models

```powershell
# List downloaded models
docker exec -it ollama ollama list

# Download a new model
docker exec -it ollama ollama pull mistral

# Remove a model
docker exec -it ollama ollama rm llama3.2

# Run model directly (test)
docker exec -it ollama ollama run llama3.2 "Hello!"
```

### Manage Containers

```powershell
# Get container shell
docker exec -it n8n sh
docker exec -it ollama bash

# View resource usage
docker stats

# Clean up unused resources
docker system prune
```

---
## Next Steps

### Configure Google APIs (15 minutes)

To use Gmail, Calendar, Docs, and Sheets:
1. Follow [CONFIGURATION.md](./CONFIGURATION.md)
2. Set up Google Cloud project
3. Enable APIs
4. Create OAuth credentials
5. Configure in N8N

{{ ... }}

Try these workflows in order:

1. **01-hello-world.json** - Test Ollama integration
2. **02-gmail-agent.json** - Email triage with AI
3. **03-calendar-assistant.json** - Smart scheduling
4. **04-document-processor.json** - Auto-generate reports

See [workflows/README.md](../workflows/README.md) for details.

### Build Your Own Workflow

1. In n8n, click "**+ Add workflow**"
2. Give it a name
3. Start with a trigger:
   - Manual (for testing)
   - Schedule (cron job)
   - Webhook (API endpoint)
4. Add nodes to process data
5. Add Ollama node for AI
6. Test with "**Execute Workflow**"

---

## Troubleshooting

### Services won't start

```powershell
# Check Docker is running
docker ps

# View error logs
docker-compose logs

# Restart everything
docker-compose down
docker-compose up -d
```

### Can't access web interfaces

- **Check firewall**: Ensure ports 3000, 5678, 11434 are allowed
- **Try different browser**: Clear cache or use incognito
- **Check ports**: `netstat -ano | findstr :5678`

### Ollama errors

```powershell
# Check Ollama is running
docker ps | findstr ollama

# Check logs
docker logs ollama

# Restart Ollama
docker-compose restart ollama
```

### Out of memory

- Increase Docker memory limit:
  - Docker Desktop → Settings → Resources
  - Set to at least 8GB
- Use smaller model: `llama3.2:1b` instead of `llama3.2`

For more help: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

## Useful Resources

### Documentation
- [Installation Guide](./INSTALLATION.md) - Detailed setup
- [Configuration Guide](./CONFIGURATION.md) - Google API setup
- [Workflow Examples](../workflows/README.md) - Sample workflows
- [Advanced Topics](./ADVANCED.md) - Production & scaling

### External Links
- [n8n Documentation](https://docs.n8n.io/)
- [Ollama Model Library](https://ollama.ai/library)
- [OpenWebUI GitHub](https://github.com/open-webui/open-webui)

### Support

This is provided as-is. No warranty is expressed or implied. But I hope it works for you!

For community support, visit:
- [n8n Community](https://community.n8n.io/)
- [Ollama Community](https://discord.gg/ollama)
- [OpenWebUI GitHub](https://github.com/open-webui/open-webui)

---

## Cheat Sheet

### n8n Expressions

```javascript
// Current time
{{ $now.toISO() }}

// Access previous node data
{{ $('Node Name').item.json.field }}

// Environment variable
{{ $env.API_KEY }}

// Conditional
{{ $json.status === 'active' ? 'yes' : 'no' }}

// Array operations
{{ $json.items.map(item => item.name) }}
```

### Ollama API

```bash
# List models
curl http://localhost:11434/api/tags

# Generate text
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Hello, world!"
}'

# Chat completion
curl http://localhost:11434/api/chat -d '{
  "model": "llama3.2",
  "messages": [
    {"role": "user", "content": "Hello!"}
  ]
}'
```

### Docker Compose

```powershell
# Recreate containers
docker-compose up -d --force-recreate

# Pull latest images
docker-compose pull

# View container config
docker inspect ollama

# Execute command in container
docker exec -it n8n sh
```

---

## Workshop Checklist

- [ ] Docker Desktop installed and running
- [ ] All containers started (ollama, open-webui, n8n)
- [ ] At least one Ollama model downloaded
- [ ] OpenWebUI account created
- [ ] n8n account created
- [ ] Hello World workflow imported and tested
- [ ] Google Cloud project created (if using Google APIs)
- [ ] Google APIs enabled (Gmail, Calendar, Docs, Sheets)
- [ ] OAuth credentials configured in n8n
- [ ] Sample workflows imported

---

## Need Help?

1. **Check troubleshooting guide**: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. **Run verification script**:
   - Windows: `.\scripts\verify-windows.ps1`
   - macOS: `./scripts/verify-mac.sh`
3. **Check logs**: `docker-compose logs -f`
4. **Ask for help**: Workshop Discord or email
5. **Search community**: [community.n8n.io](https://community.n8n.io/)

---

**You're all set! Time to build some agents! 🚀**
