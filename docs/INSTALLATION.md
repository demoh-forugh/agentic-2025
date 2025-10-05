# Installation Guide
## Building Agents with n8n Workshop

This guide walks you through installing all required components for the workshop on Windows.

---

## 📋 System Requirements

### Recommended Specifications
- **OS**: Windows 10/11 (64-bit) with WSL2 or macOS 12.0 (Monterey) and later
- **RAM**: 16GB+ (8GB minimum)
- **Storage**: 20GB+ free space
- **CPU**: 4+ cores
- **GPU**: Optional (NVIDIA GPU for faster inference)
- **Internet**: Required for initial setup and model downloads

### 🎯 Smart Model Recommendations

**The setup script automatically detects your system specifications** (RAM, CPU, GPU) and recommends the optimal model:

| Your System | Recommended Model | Size | Reason |
|------------|-------------------|------|---------|
| < 6GB RAM | `llama3.2:1b` | 1GB | Limited memory - small model only |
| 6-10GB RAM (no GPU) | `llama3.2:1b` | 1GB | Moderate RAM - CPU inference |
| 6-10GB RAM (with GPU) | `llama3.2:1b` or `llama3.2` | 1-4GB | GPU accelerates larger models |
| 10GB+ RAM (no GPU) | `llama3.2` | 4GB | Good RAM for mid-size model |
| 10GB+ RAM (with GPU) | `llama3.2` or `mistral` | 4GB | Optimal for workshop ✅ |

**During setup, you'll see:**
```
System Specifications:
  RAM:       16.0 GB total, 12.3 GB available
  CPU:       8 cores
  GPU:       NVIDIA GeForce RTX 3060

Recommended Model: llama3.2 or mistral
```

The setup script will highlight the recommended model in green and set it as the default choice.

---

## Windows Installation

### Step 1: Install Docker Desktop

1. Visit [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
2. Download the installer for Windows
3. Run the installer and follow the prompts
4. **Enable WSL2** when prompted (required for Docker)
5. Restart your computer after installation
6. **Launch Docker Desktop** from the Start Menu
7. **Log in or skip login** when prompted
8. Wait for Docker to fully start (whale icon in system tray shows "Engine running")

### Step 2: Run Automated Setup

Open PowerShell in your repository directory and run:

```powershell
# Run the automated setup script
.\scripts\setup-windows.ps1

# Optional: Enable detailed logging
$env:ENABLE_LOGGING="1"
.\scripts\setup-windows.ps1
```

**The setup script will:**
- ✓ Detect your system specs (RAM, CPU, GPU)
- ✓ Recommend the optimal model for your hardware
- ✓ Check Docker is running
- ✓ Start all containers (ollama, n8n, open-webui, postgres)
- ✓ Wait for containers to be healthy
- ✓ Optionally download a model
- ✓ Provide troubleshooting if anything fails

### Step 3: Verify Installation

```powershell
.\scripts\verify-windows.ps1
```

This checks that all services are running and accessible.

---

## Installation Complete! 🎉

You now have a complete local AI agent stack running!

### Post-Install: First Steps

#### 1. Test OpenWebUI (2 minutes)

Verify your LLM is working:

1. Open http://localhost:3000
2. Create a local account (any email, e.g., `user@example.com`)
3. Select your model from the dropdown (e.g., `llama3.2` or `llama3.2:1b`)
4. Type: "What is AI automation?"
5. See your LLM respond! ✅

**Tip:** If your model isn't in the dropdown, check if it's still downloading:
```bash
docker exec -it ollama ollama list
```

#### 2. Set Up n8n (3 minutes)

Create your workflow automation account:

1. Open http://localhost:5678
2. Create your n8n account (stored locally)
3. Enter email and password
4. Click "Get started"
5. You'll see the workflow canvas ✅

#### 3. Import Your First Workflow (5 minutes)

Test Ollama integration with the Hello World workflow using n8n's built-in import feature:

1. In n8n, create a new workflow and name it "Hello World"
2. Click the **"..."** menu button (top right corner) → **"Import from File"**
3. In the file browser, navigate to where you cloned this repository
4. Browse to the `workflows/` folder
5. Select **`01-hello-world.json`** and click **Open**
6. The workflow will load on the canvas
7. **Create Ollama Credential (One-Time Setup):**
   - You'll see the "Ollama Chat Model" node has a credential warning
   - Click the node, then click **"Credential to connect with"** dropdown
   - Select **"Create New Credential"**
   - The **Base URL is automatically pre-filled** with `http://ollama:11434` (read-only)
   - Click **"Save"** - done! ✅
8. Click **"Execute Workflow"** button in the top toolbar
9. View the output in the **"Format Response"** node - see AI output! 🎉

**Why is credential setup so easy?**
The docker-compose.yml uses `CREDENTIALS_OVERWRITE_DATA_FILE` to automatically pre-fill credential connection details:
- **Ollama API**: Base URL `http://ollama:11434` (not localhost!)
- **PostgreSQL**: Host `postgres`, Port `5432`, Database `workshop_db`, User `workshop`

Docker service discovery allows containers to communicate using service names as hostnames on the shared `ai-network`.

**Important:** You only create each credential type once. After that, all workflows automatically use the same credentials!

**Example path to workflows:**
- Windows: `C:\Users\YourName\Documents\demos\workflows\01-hello-world.json`
- macOS: `/Users/YourName/Documents/demos/workflows/01-hello-world.json`
- Linux: `/home/username/demos/workflows/01-hello-world.json`

#### 4. Explore More Workflows

We've included **6 production-ready workflows** for real business use cases:

| Workflow | Description | Setup Needed |
|----------|-------------|--------------|
| `01-hello-world.json` | Test Ollama integration | ✅ Ollama credential (one-time) |
| `02-gmail-agent.json` | Email triage & auto-categorization | Ollama + Google OAuth* |
| `03-calendar-assistant.json` | Smart meeting scheduling | Ollama + Google OAuth* |
| `04-document-processor.json` | Auto-generate reports from data | Ollama + Google OAuth* |
| `05-customer-service-db.json` | Database-powered customer support | Ollama + PostgreSQL credentials |
| `06-lead-scoring-crm.json` | AI lead qualification & scoring | Ollama + PostgreSQL credentials |

*Google API credentials required - see [CONFIGURATION.md](./CONFIGURATION.md)

**When you import workflows:** n8n will prompt you to create credentials. All connection details (URLs, hosts, ports, passwords) are automatically pre-filled - you just click "Save"!

**📚 Full Workflow Documentation:** [workflows/README.md](../workflows/README.md)

### Next Steps

1. **[Configure Google APIs](./CONFIGURATION.md)** - Enable Gmail, Calendar, Docs, Sheets workflows (15 min)
2. **[Import Sample Workflows](../workflows/README.md)** - Try all 6 pre-built workflows
3. **[Build Your Own](https://docs.n8n.io/)** - Create custom AI automation workflows

---

## 🔧 Optional: Install n8n CLI Tools

For advanced users who want to manage workflows via CLI:

```powershell
# Install Node.js from https://nodejs.org/
# Then install n8n globally
npm install -g n8n
```

---

## 🍎 macOS Installation

This section covers installing and running the workshop stack on macOS using Docker Desktop for Mac and the provided helper scripts.

### Prerequisites (macOS)

- **OS**: macOS 12+ (Monterey) recommended
- **RAM**: 16GB+ (8GB minimum)
- **Storage**: 20GB free disk space
- **Docker**: Docker Desktop for Mac (see installation below)
- **Command line tools**: `bash`, `curl` (pre-installed on macOS)
- **Optional**: `jq` for JSON parsing (install via Homebrew: `brew install jq`)

### Step 1: Install Docker Desktop for Mac

1. Visit [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
2. Click **"Download for Mac"**
   - **For Apple Silicon (M1/M2/M3)**: Download the Apple Silicon version
   - **For Intel Macs**: Download the Intel version
3. Open the downloaded `.dmg` file
4. Drag the Docker icon to your Applications folder
5. Open Docker from Applications (or Spotlight: `Cmd + Space`, type "Docker")
6. **First-time setup**:
   - Docker may ask for system permissions - click "OK"
   - Accept the Docker Desktop Service Agreement
   - You may skip the optional Docker account sign-in (click "Continue without signing in")
7. **Wait for initialization**: Look for the Docker icon in your menu bar (top right)
   - When Docker is ready, the icon will be solid (not animated)
   - You'll see "Docker Desktop is running" when you click the icon
8. **Verify Docker is working**:
   ```bash
   # Open Terminal (Cmd + Space, type "Terminal")
   docker --version
   docker ps
   ```
   If both commands work, Docker is ready! ✅

**Tip for Apple Silicon Macs**: Docker Desktop automatically enables Rosetta emulation for x86 containers. This is normal and required for some Docker images.

### Step 2: Run Automated Setup

Open Terminal and navigate to where you cloned/downloaded this repository:

```bash
# Navigate to the repository
cd ~/Downloads/demos  # Adjust path to where you downloaded the workshop files

# FIRST TIME ONLY: Make scripts executable
chmod +x ./scripts/setup-mac.sh ./scripts/verify-mac.sh

# Run the automated setup script
./scripts/setup-mac.sh
```

**What the setup script does:**
- ✓ Detects your system specs (RAM, CPU, GPU)
- ✓ Recommends the optimal model for your hardware
- ✓ Checks if Docker is running
- ✓ Starts all containers (ollama, n8n, open-webui, postgres) with health checks
- ✓ Optionally downloads an LLM model
- ✓ Provides troubleshooting if anything fails

**Optional: Enable detailed logging**
```bash
ENABLE_LOGGING=1 ./scripts/setup-mac.sh
```

### Step 3: Verify Installation

```bash
./scripts/verify-mac.sh
```

This checks that all services are running and accessible.

**Optional: Measure Performance**
```bash
# Measure cold start vs warm performance
./scripts/measure-cold-warm-mac.sh

# Custom model and runs:
MODEL="llama3.2:1b" WARM_RUNS=5 ./scripts/measure-cold-warm-mac.sh
```

### Manual Setup (Alternative on macOS)

```bash
# 1) Copy configuration into repo root (if not already present)
cp configs/docker-compose.yml ./docker-compose.yml
cp configs/.env.example ./.env

# 2) Start services
docker compose up -d    # or: docker-compose up -d

# 3) Pull a model inside the Ollama container (optional)
docker exec -it ollama ollama pull llama3.2

# 4) Verify
curl http://localhost:11434/api/tags       # Ollama API
curl http://localhost:5678/healthz         # n8n
open http://localhost:3000/                # OpenWebUI (opens default browser)

# 5) Create Ollama credential inside n8n (first run)
#    - Open http://localhost:5678 and import any workflow using the Ollama node
#    - Click the "Ollama Chat Model" node warning → "Credential to connect with" → "Create New Credential"
#    - Change Base URL from http://localhost:11434 to http://ollama:11434 (Docker container hostname)
#    - Click "Save"; the credential test should go green when the connection succeeds
```

### Access URLs (same as Windows)

- **OpenWebUI**: http://localhost:3000
- **n8n**: http://localhost:5678
- **Ollama API**: http://localhost:11434

## 📊 Resource Usage

### Expected Resource Consumption

- **Ollama (with llama3.2 4GB model)**: ~4-6GB RAM
- **Ollama (with llama3.2:1b 1GB model)**: ~1-2GB RAM
- **OpenWebUI**: ~200-300MB RAM
- **n8n**: ~300-500MB RAM
- **Docker overhead**: ~500MB RAM

**Total Expected**: 
- With 4GB model: ~5-7GB RAM in active use
- With 1GB model: ~2-4GB RAM in active use

**To measure on your own system:**
```powershell
# Start containers
docker-compose up -d

# Monitor resources while running inference
docker stats --no-stream
nvidia-smi
```

**Placeholder for actual data:**
- **Ollama (idle)**: [MEASURE NEEDED]
- **Ollama (active inference with GPU)**: [MEASURE NEEDED]
- **Ollama (active inference CPU-only)**: [MEASURE NEEDED]
- **OpenWebUI**: [MEASURE NEEDED]
- **n8n**: [MEASURE NEEDED]
- **Docker Desktop overhead**: [MEASURE NEEDED]
- **GPU usage during inference**: [MEASURE NEEDED]
- **CPU usage during inference**: [MEASURE NEEDED]

---

## 🛟 Troubleshooting

### Docker Desktop won't start
- Ensure WSL2 is installed and updated
- Check if virtualization is enabled in BIOS
- Restart Docker Desktop service

### Docker shows "500 Internal Server Error"
This error typically means Docker Desktop is installed but not fully running or not logged in:

1. **Open Docker Desktop** from the Windows Start Menu
2. **Log in or skip login** when prompted (Docker Desktop requires this step)
3. **Wait for initialization** (30-60 seconds)
4. **Verify status**: Look for the Docker whale icon in system tray showing "Engine running"
5. **Run the setup script again** after Docker Desktop is fully started

### First-time setup appears to stall during "Pulling"
This is **normal behavior**! Docker performs two phases:

1. **Download phase**: Downloads ~4-5 GB of Docker images (5-15 minutes)
2. **Verification/Extraction phase**: After download completes, Docker verifies and extracts images (1-3 minutes)
   - Status will still show "Pulling" during verification
   - Progress bars may appear complete but verification continues
   - **Be patient** - this is a necessary security step

### Containers won't start
```powershell
# Check logs
docker-compose logs

# Restart services
docker-compose restart
```

### Port conflicts
If ports 3000, 5678, or 11434 are already in use:
1. Edit `docker-compose.yml`
2. Change port mappings (e.g., `3000:3000` → `3001:3000`)
3. Restart: `docker-compose down && docker-compose up -d`

### Models won't download
- Check internet connection
- Ensure Docker has network access
- Try a smaller model first

### n8n can't connect to Ollama

**Error:** "Connection refused" or "ECONNREFUSED" when executing n8n workflows

**This should rarely happen** since Ollama credentials are pre-configured automatically via `CREDENTIALS_OVERWRITE_DATA`. If you see this error:

**Possible Causes:**
1. You manually created a new Ollama credential instead of using the pre-configured one
2. You edited the credential and changed the URL to `localhost:11434`

**Fix:**
1. In n8n, open your workflow and click the Ollama node
2. In "Credential to connect with" dropdown, select **"Ollama Local"** (pre-configured)
3. If that doesn't exist, go to **Settings** → **Credentials** → **Ollama API**
4. Verify Base URL is: **`http://ollama:11434`** (not `localhost:11434`)
5. Click **Save** and retry the workflow

**Technical Explanation:** Docker containers use service names (defined in docker-compose.yml) as hostnames. The Ollama service is named `ollama`, so n8n must use `http://ollama:11434` to reach it on the shared `ai-network`.

For more issues, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

**Ready to build your first agent?** Continue to the [Configuration Guide](./CONFIGURATION.md)!
