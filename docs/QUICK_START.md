# Quick Start Guide

Get up and running in 15 minutes! ⚡

---

## Prerequisites

### Minimum Requirements
- **OS**: Windows 10/11 with WSL2 or macOS 12.0 (Monterey) and later
- **RAM**: 8GB (16GB+ recommended)
- **Storage**: 20GB free disk space
- **Docker**: Docker Desktop installed and running

**💡 Performance Tips**: 
- **First Request Delay**: The initial request takes longer as the model loads into memory. This is normal and only happens once per session.
- **Keep the Model Warm**: To maintain fast responses, keep your Docker containers running. The model stays loaded in memory as long as the Ollama container is active.
- **Resource Management**: If you have 8GB RAM, use the smaller `llama3.2:1b` (1GB) model for better performance.
- **GPU Acceleration**: While not required, using a GPU will significantly speed up responses. The system works well on CPU too.

---

## 5-Minute Setup

### 1. Clone or Download Workshop Files

```powershell
# If you have git
git clone <workshop-repo-url>
cd open-source-setup

# Or download and extract ZIP file
```

### 2. Run Setup Script

#### Windows
```powershell
# Run automated setup
.\scripts\setup-windows.ps1

# Optional: Enable detailed logging
$env:ENABLE_LOGGING="1"
.\scripts\setup-windows.ps1
```

#### macOS
```bash
# Run automated setup
./scripts/setup-mac.sh

# Optional: Enable detailed logging
ENABLE_LOGGING=1 ./scripts/setup-mac.sh
```

**What the setup script does:**
- ✓ Check prerequisites (Docker, disk space, network)
- ✓ **Detect system specs** (RAM, CPU cores, GPU) and recommend optimal model
- ✓ Detect already-running containers (won't restart unnecessarily)
- ✓ Start Docker containers with health checks
- ✓ Download an LLM model (optional, skips if already present)
- ✓ Provide detailed troubleshooting if anything fails

**Key Features:**
- **Smart Model Recommendations**: Analyzes your RAM, CPU, and GPU to suggest the right model
  - <6GB RAM → `llama3.2:1b` (1GB model)
  - 6-10GB RAM → `llama3.2:1b` or `llama3.2` (depending on GPU)
  - 10GB+ RAM → `llama3.2` or `mistral` (optimal for workshop)
- **Idempotency**: If containers are already running, prompts before restarting
- **Health Checks**: Waits up to 60s for each container to be healthy
- **Pre-flight Validation**: Checks Docker daemon, disk space, and network before starting
- **Actionable Errors**: Every error includes specific commands to fix it

### 3. Verify Installation

#### Windows
```powershell
.\scripts\verify-windows.ps1
```

#### macOS
```bash
./scripts/verify-mac.sh
```

**What the verification script checks:**
- ✓ Docker daemon health
- ✓ All 4 containers running (ollama, n8n, open-webui, postgres)
- ✓ Ports correctly mapped (11434, 5678, 3000, 5432)
- ✓ HTTP endpoints accessible
- ✓ Ollama models available
- ✓ Container resource usage

**Troubleshooting Improvements:**
- **Container Status Differentiation**: Distinguishes between stopped vs missing containers
- **Smart Model Guidance**: Suggests specific models based on your RAM

---

### 4. Manual Setup (Alternative)

If you prefer manual control:

#### Windows
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

#### macOS/Linux
```bash
# 1. Copy configuration
cp configs/docker-compose.yml .
cp configs/.env.example .env

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

## Post-Install: First Steps

### 1. Set Up OpenWebUI (2 minutes)

**Test your LLM is working:**

1. Go to http://localhost:3000
2. Click "**Sign Up**" (data stored locally, no external account needed)
3. Create an account with any email (e.g., `user@example.com`)
4. Select your model from dropdown (e.g., `llama3.2` or `llama3.2:1b`)
5. Type a test message: "What is AI automation?"
6. See your LLM respond! ✅

**Tip:** If you don't see your model in the dropdown, it may still be downloading. Check the setup script output or run:
```bash
docker exec -it ollama ollama list
```

### 2. Set Up n8n (3 minutes)

**Create your workflow automation account:**

1. Go to http://localhost:5678
2. Create your n8n account (first-time setup, local only)
3. Enter your email and password
4. Click "**Get started**"
5. You'll see the workflow canvas - you're ready to build! ✅

### 3. Import Your First Workflow (5 minutes)

**Try the Hello World workflow to test Ollama integration using n8n's built-in import:**

1. In n8n, create a new workflow and name it "Hello World"
2. Click the **"..."** menu button (top right corner) → **"Import from File"**
3. In the file browser, navigate to where you cloned this repository
4. Browse to the **`workflows/`** folder inside your repository
5. Select **`01-hello-world.json`** and click **Open**
6. The workflow will appear on the canvas
7. ✨ **That's it!** Credentials are **automatically pre-configured** - no manual setup needed!
   - **Ollama**: Pre-configured to use `http://ollama:11434`
   - **PostgreSQL**: Pre-configured to connect to `postgres` container with workshop database
   - Just import workflows and they work! 🎉
8. Click **"Execute Workflow"** button in the top toolbar
9. View the output in the **"Format Response"** node - see your LLM respond! 🎉

**Why does it work automatically?**
The docker-compose.yml includes `CREDENTIALS_OVERWRITE_DATA` which pre-configures both Ollama and PostgreSQL credentials with the correct connection details. All containers communicate using service names as hostnames on the shared Docker network (`ai-network`), so:
- Ollama API → `http://ollama:11434`
- PostgreSQL → `postgres:5432` (database: `workshop_db`, user: `workshop`)

**Example paths to find your workflows:**
- **Windows**: `C:\Users\YourName\Documents\demos\workflows\01-hello-world.json`
- **macOS**: `/Users/YourName/Documents/demos/workflows/01-hello-world.json`
- **Linux**: `/home/username/demos/workflows/01-hello-world.json`

**Success!** Your local AI agent stack is working. ✅

### 4. Import More Workflows (Optional)

We've included **6 production-ready workflows** for common business use cases:

| Workflow | Use Case | Credentials Needed |
|----------|----------|-------------------|
| `01-hello-world.json` | Test Ollama integration | ✅ Pre-configured |
| `02-gmail-agent.json` | Email triage & categorization | Google OAuth* |
| `03-calendar-assistant.json` | Smart meeting scheduling | Google OAuth* |
| `04-document-processor.json` | Auto-generate reports | Google OAuth* |
| `05-customer-service-db.json` | Database-powered support | ✅ Pre-configured (PostgreSQL) |
| `06-lead-scoring-crm.json` | AI lead qualification | ✅ Pre-configured (PostgreSQL) |

*Google OAuth credentials required (see [CONFIGURATION.md](./CONFIGURATION.md))
✅ = Works immediately with pre-configured credentials!

**📚 Full Workflow Documentation:** See [workflows/README.md](../workflows/README.md) for detailed setup instructions, business value, and examples for each workflow.

**🔑 Pre-configured Credentials Reference:**
- **Ollama API**: `http://ollama:11434` (local LLM runtime)
- **PostgreSQL**:
  - Host: `postgres`
  - Port: `5432`
  - Database: `workshop_db`
  - User: `workshop`
  - Password: `workshop_password`
  - Sample tables: `customer_tickets`, `customer_responses`, `sales_data`, `processed_reports`

---

## Common Commands

### Manage Services

#### Windows
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

#### macOS/Linux
```bash
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

#### Windows
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

#### macOS/Linux
```bash
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

#### Windows
```powershell
# Get container shell
docker exec -it n8n sh
docker exec -it ollama bash

# View resource usage
docker stats

# Clean up unused resources
docker system prune
```

#### macOS/Linux
```bash
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
5. Configure in n8n

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

#### Windows
```powershell
# Check Docker is running
docker ps

# View error logs
docker-compose logs

# Restart everything
docker-compose down
docker-compose up -d
```

#### macOS/Linux
```bash
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

#### Windows
```powershell
# Check Ollama is running
docker ps | findstr ollama

# Check logs
docker logs ollama

# Restart Ollama
docker-compose restart ollama
```

#### macOS/Linux
```bash
# Check Ollama is running
docker ps | grep ollama

# Check logs
docker logs ollama

# Restart Ollama
docker-compose restart ollama
```

### n8n can't connect to Ollama

**Error:** "Connection refused" or "ECONNREFUSED" when executing n8n workflows

**This should rarely happen** since the Ollama credential is pre-configured automatically. If you see this error:

**Possible Causes:**
1. You manually created a new Ollama credential instead of using the pre-configured one
2. You edited the pre-configured credential and used `localhost:11434`

**Fix:**
1. In n8n, open your workflow
2. Click the Ollama node
3. In "Credential to connect with" dropdown, select **"Ollama Local"** (the pre-configured credential)
4. If you don't see it, go to **Settings** → **Credentials** → **Ollama API**
5. The Base URL should be: **`http://ollama:11434`**
6. If it shows `localhost:11434`, change it to `http://ollama:11434`
7. Click **Save** and try executing the workflow again

**Why `http://ollama:11434` and not `localhost`?** Inside Docker, `localhost` refers to the n8n container itself, not other containers. Use the service name `ollama` to reach the Ollama container on the shared Docker network.

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
   - macOS/Linux: `./scripts/verify-mac.sh`
3. **Check logs**: `docker-compose logs -f`
4. **Ask for help**: Workshop Discord or email
5. **Search community**: [community.n8n.io](https://community.n8n.io/)

---

**You're all set! Time to build some agents! 🚀**
