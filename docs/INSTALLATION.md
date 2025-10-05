# Installation Guide
## Building Agents with n8n Workshop

This guide walks you through installing all required components for the workshop on Windows.

---

## 📋 System Requirements

### Recommended Specifications
- **OS**: Windows 10/11 (64-bit) with WSL2
- **RAM**: 16GB+ (8GB minimum)
- **Storage**: 20GB+ free space
- **CPU**: 4+ cores
- **GPU**: Optional (NVIDIA GPU for faster inference)
- **Internet**: Required for initial setup and model downloads

### Demo System Specifications
*This workshop was developed and tested on:*
- **OS**: Windows 11 Pro 24H2 (Build 26100)
- **CPU**: AMD Ryzen 9 3900X (12 cores, 24 threads, 3.8GHz base)
- **RAM**: 128GB DDR4 @ 3200MHz (4x 32GB Micron)
- **GPU**: NVIDIA GeForce RTX 4090 (24GB VRAM)
- **Storage**: 2TB PCIe NVMe SSD + 250GB Samsung 970 EVO Plus
- **Docker**: Docker Desktop (latest)
- **WSL2**: v2.3.24.0 (Kernel 5.15.153.1-2)

**Performance Expectations:**
- Performance metrics: [TO BE MEASURED]
- GPU acceleration expected to provide speedup over CPU-only

**Note**: This demo system has GPU acceleration, but the workshop fully supports CPU-only setups. GPU is NOT required.

---

## Step## 10) Install n8nDocker Desktop

### Download and Install

1. Visit [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
2. Download the installer
{{ ... }}
.\scripts\verify-windows.ps1
```

---

## 2) Install n8n in Complete!

You now have a complete local AI agent stack running!

### Next Steps

{{ ... }}
2. **[Sample Workflows](../workflows/)** - Import pre-built workflows into N8N
3. **Test Your Setup** - Try the hello-world workflow

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
- **Docker**: Docker Desktop for Mac installed and running
- **Command line tools**: `bash`, `curl`
- **Optional**: `jq` for JSON parsing (install via Homebrew: `brew install jq`)

### Quick Start (Scripts)

```bash
# From the repository root

# 1) Make scripts executable (first time only)
chmod +x ./scripts/setup-mac.sh \
         ./scripts/verify-mac.sh \
         ./scripts/measure-cold-warm.sh

# 2) Setup: start Docker services and prepare environment
./scripts/setup-mac.sh

# 3) Verify: check services are reachable
./scripts/verify-mac.sh

# 4) Measure: collect cold vs warm performance
#    JSON will be saved under artifacts/performance/
./scripts/measure-cold-warm-mac.sh

# Optional environment overrides:
MODEL="llama3.2:3b" WARM_RUNS=5 ./scripts/measure-cold-warm-mac.sh
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
```

### Access URLs (same as Windows)

- **OpenWebUI**: http://localhost:3000
- **N8N**: http://localhost:5678
- **Ollama API**: http://localhost:11434

## 📊 Resource Usage

### Expected Resource Consumption

- **Ollama (with llama3.2 4GB model)**: ~4-6GB RAM
- **Ollama (with llama3.2:1b 1GB model)**: ~1-2GB RAM
- **OpenWebUI**: ~200-300MB RAM
- **N8N**: ~300-500MB RAM
- **Docker overhead**: ~500MB RAM

**Total Expected**: 
- With 4GB model: ~5-7GB RAM in active use
- With 1GB model: ~2-4GB RAM in active use

### Actual Demo System Measurements
See [SYSTEM_SPECS.md](./SYSTEM_SPECS.md#performance-metrics-from-demo-system) for the workshop's measured performance results and methodology.

The steps below show how to measure on your own system to compare against the central results.

**To collect real measurements:**
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
- **N8N**: [MEASURE NEEDED]
- **Docker Desktop overhead**: [MEASURE NEEDED]
- **GPU usage during inference**: [MEASURE NEEDED]
- **CPU usage during inference**: [MEASURE NEEDED]

---

## 🛟 Troubleshooting

### Docker Desktop won't start
- Ensure WSL2 is installed and updated
- Check if virtualization is enabled in BIOS
- Restart Docker Desktop service

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

For more issues, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

**Ready to build your first agent?** Continue to the [Configuration Guide](./CONFIGURATION.md)!
