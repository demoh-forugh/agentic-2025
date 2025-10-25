# System Specifications Reference

This document provides detailed hardware specifications for the workshop.

---

## 🔍 Commands to Check Your System Specs

Use these commands to gather current system information on Windows:

### CPU Information
```powershell
powershell "Get-WmiObject Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors | Format-List"
```

### GPU Information
```powershell
powershell "Get-WmiObject Win32_VideoController | Select-Object Name, AdapterRAM, DriverVersion | Format-List"
```

### RAM Information
```powershell
# Total RAM (simple decimal output)
powershell "(Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB"

# Total RAM (formatted with MB)
powershell "systeminfo | findstr /C:'Total Physical Memory'"

# RAM modules details (capacity and speed)
powershell "Get-WmiObject Win32_PhysicalMemory | Select-Object @{Name='Capacity_GB';Expression={`$_.Capacity/1GB}}, Speed | Format-Table"
```

### Operating System Information
```powershell
powershell "Get-WmiObject Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture | Format-List"
```

### Disk Information
```powershell
powershell "Get-WmiObject Win32_LogicalDisk -Filter 'DriveType=3' | Format-Table DeviceID,Size,FreeSpace -AutoSize"
```

### All-in-One System Report
```powershell
# Generate comprehensive system information
systeminfo
```

**Note**: These commands use WMI (Windows Management Instrumentation) which works reliably across different Windows environments, including WSL, Git Bash, and PowerShell. The `wmic` commands were deprecated in Windows 11 and may not work consistently.

---

## 💻 Current Testing System (2025-10-25)

**Updated system used for testing v1.4.0:**

| Component | Specification |
|-----------|--------------|
| **Operating System** | Microsoft Windows 11 Enterprise (Build 26100) |
| **Processor** | Intel Core Ultra 9 285HX (24 cores, 24 threads, Arrow Lake generation) |
| **Memory** | 64,981 MB (~65 GB) DDR5 @ 6400MHz (2x modules) |
| **Storage** | 474 GB total (242 GB free) |
| **Graphics** | NVIDIA RTX PRO 4000 Blackwell Generation Laptop GPU (4GB VRAM) |
| **Graphics (Integrated)** | Intel Graphics (2GB VRAM) |
| **Docker/Podman** | Podman (latest) with GPU support |

**Performance Notes:**
- High-end mobile workstation configuration
- Excellent for AI/ML workloads with NVIDIA RTX PRO GPU
- 65GB RAM allows running entire Docker stack with multiple large models simultaneously
- Recommended configuration: Use GPU-accelerated setup (`docker-compose.podman-gpu.yml`)
- Can comfortably run all three model tiers (fast/accurate/flagship) concurrently

---

## 📋 Quick Reference for Workshop Attendees

### Minimum Configuration (Entry Level)
- **OS:** Windows 10/11 with WSL2 or macOS 12+ (Monterey)
- **CPU:** 4 cores
- **RAM:** 8GB
- **GPU:** None required
- **Storage:** 20GB free space
- **Model:** llama3.2:1b (1GB) or llama3.2:3b (2GB)

### Recommended Configuration (Comfortable)
- **OS:** Windows 11 Pro or macOS 12+
- **CPU:** 6-8 cores
- **RAM:** 16GB
- **GPU:** None required (optional: NVIDIA for acceleration)
- **Storage:** 50GB free space
- **Model:** llama3.2:3b (2GB) or qwen2.5:14b (9GB) with GPU

### Ideal Configuration (Best Experience)
- **OS:** Windows 11 Pro or macOS 12+
- **CPU:** 8+ cores
- **RAM:** 32GB+
- **GPU:** NVIDIA RTX (12GB+ VRAM recommended)
- **Storage:** 100GB+ SSD
- **Models:** All three tiers (fast/accurate/flagship)

### Key Takeaways
- ✅ **GPU is NOT required** - Workshop fully supports CPU-only operation
- ✅ **8GB RAM works** - Use llama3.2:3b (2GB model)
- ✅ **16GB RAM recommended** - Use qwen2.5:14b for best balance
- ✅ **GPU provides 2-5x speedup** - But is completely optional

---

## 🏛️ Historical Demo System (Original Testing - October 2024)

**This system was used for initial development and performance benchmarking:**

| Component | Specification |
|-----------|--------------|
| **Operating System** | Windows 11 Pro 24H2 (Build 26100) |
| **Processor** | AMD Ryzen 9 3900X (12 cores, 24 threads, 3.8GHz base) |
| **Memory** | 128GB DDR4 @ 3200MHz (4x 32GB Micron) |
| **Graphics** | NVIDIA GeForce RTX 4090 (24GB VRAM) |
| **Docker** | Docker Desktop with WSL2 v2.3.24.0 |

### Benchmark Results (llama3.2:3b)
**Measurement**: 2025-10-04 22:07 (US/Eastern)

- **Cold start**: 72.09s (model load from disk)
- **Warm start**: 0.82s (model in memory)
- **Speedup**: 87.91× faster warm vs cold
- **Throughput**: 100.86 tokens/sec
- **GPU utilization**: 8% → 4%, VRAM ~5.8 GiB, power 18-34W

---

## Model Selection Guide

### Three-Tier Model Strategy

| Available RAM | Recommended Model | Size | VRAM (GPU) | Speed (t/s) | Use Case |
|---------------|-------------------|------|-----------|-------------|----------|
| 8GB | llama3.2:3b | 2.0 GB | ~2.4 GB | 80-100 | Fast tier - quick decisions |
| 16GB | qwen2.5:14b | 9.0 GB | ~9 GB | 45-55 | Accurate tier - balanced workflows |
| 32GB+ (16GB GPU) | mistral-small:22b | 13 GB | ~14 GB | 30-40 | Flagship tier - max capability |

### Current Model Lineup

#### ⚡ Fast Tier: Llama 3.2 3B (Q4_K_M)
- **Size**: 2.0 GB
- **Best for**: Email categorization, quick decisions, priority scoring
- **Strengths**: Lightning fast (80-100 t/s), low memory usage
- **VRAM**: ~2.4 GB when loaded
- **Response time**: 1-2 seconds

#### 🎯 Accurate Tier: Qwen 2.5 14B (Q4_K_M)
- **Size**: 9.0 GB
- **Best for**: Complex analysis, drafts, reasoning, balanced workflows
- **Strengths**: High accuracy (45-55 t/s), excellent for business tasks
- **VRAM**: ~9 GB when loaded
- **Response time**: 2-4 seconds

#### 🏆 Flagship Tier: Mistral-Small 22B (Q4_K_M)
- **Size**: 13 GB
- **Best for**: Professional documents, complex lead scoring, strategic analysis
- **Strengths**: Maximum capability (30-40 t/s), superior reasoning
- **VRAM**: ~14 GB when loaded (requires 16GB+ GPU)
- **Response time**: 3-7 seconds

### Specialized Models

#### 🔬 Mistral 7B (Sentiment Specialist)
- **Size**: 4.4 GB | **Accuracy**: 94% sentiment analysis (benchmarked)
- **Best for**: Customer sentiment scoring, review analysis, tone detection

#### 🚀 Mistral-Nemo 12B (Extended Context)
- **Size**: 7.1 GB | **Context**: 128K tokens
- **Best for**: Long document analysis, multi-email threads

**See**: `docs/MODEL_STRATEGY.md` for complete model routing recommendations and workflow-specific guidance

---

## Scaling Considerations

### Running Multiple Models
If you have 32GB+ RAM, you can run multiple models:

```bash
# Download multiple models
docker exec -it ollama ollama pull llama3.2:1b
docker exec -it ollama ollama pull llama3.2
docker exec -it ollama ollama pull mistral

# Switch between them in n8n workflows
```

**Memory requirement**: Sum of model sizes + 2GB overhead

### Production Deployment
For production environments:
- **CPU**: 16+ cores
- **RAM**: 64GB+ (to handle concurrent requests)
- **Storage**: 500GB+ SSD (for multiple models and logs)
- **Network**: 1Gbps+ (if serving external requests)

---

## GPU Acceleration (Optional)

**GPU is NOT required** - The workshop is fully functional on CPU-only systems.

### Enabling GPU Support

**For Podman (Windows with NVIDIA GPU):**
```bash
podman-compose -f configs/docker-compose.yml -f configs/docker-compose.podman-gpu.yml up -d
```

**For Docker (Windows with NVIDIA GPU):**
```bash
docker compose -f configs/docker-compose.yml -f configs/docker-compose.gpu.yml up -d
```

**Prerequisites:**
- NVIDIA GPU with compute capability 5.0+ (GTX 900 series or newer)
- NVIDIA Container Toolkit (Docker) or CDI support (Podman)
- Latest GPU drivers

### GPU Performance Benefits

| Benefit | Impact |
|---------|--------|
| **Inference speed** | 2-5x faster responses |
| **CPU usage** | Lower (can multitask better) |
| **Model size** | Can run larger models (13B, 22B, 70B+) |
| **Concurrency** | Better handling of parallel requests |
| **Memory** | Can keep multiple models loaded |

### When GPU is NOT Needed
- Workshop attendance (CPU works fine)
- Learning and experimentation
- Low-frequency usage (few requests/hour)
- Budget constraints
- Small models (1-4GB)

See `docs/PERFORMANCE_OPTIMIZATION.md` for complete GPU tuning guide with 8 optimization variables.

---

## Cost Analysis

### Hardware Investment

| Configuration | Approximate Cost (USD) | Performance Tier |
|---------------|------------------------|------------------|
| 8GB RAM PC | $400-600 | Entry Level |
| 16GB RAM PC | $600-900 | Recommended |
| 32GB RAM PC | $900-1500 | Ideal |
| 32GB + GPU | $1500-3000+ | Enthusiast/Pro |

### Cloud vs. Local (Monthly)

| Setup | Cost/Month | Pros | Cons |
|-------|------------|------|------|
| **Local (Workshop)** | ~$5-15 (electricity) | Privacy, no usage limits, one-time cost | Upfront investment |
| **Cloud (n8n Cloud)** | $20-50+ | Easy setup, maintained | Recurring cost, usage limits |
| **Cloud (OpenAI API)** | $50-500+ | State-of-art models | Expensive at scale, data privacy |
| **Cloud (VPS + Ollama)** | $50-200 | Flexible, scalable | Ongoing cost, setup complexity |

**Workshop Value Proposition**: 
- Upfront: $600-900 (16GB system)
- Break-even: 12-18 months vs. cloud
- After that: Pure savings + privacy + unlimited use

---

## Compatibility Notes

### Windows Versions
- ✅ **Windows 11 Pro/Home**: Fully tested
- ✅ **Windows 10 Pro (v2004+)**: Supported, WSL2 required
- ⚠️ **Windows 10 Home**: Requires WSL2, Docker Desktop
- ❌ **Windows 7/8**: Not supported

### Alternative Platforms
While this workshop focuses on Windows:
- **macOS**: Fully compatible (use Docker Desktop for Mac)
- **Linux**: Fully compatible (native Docker)
- **Raspberry Pi**: Possible with smaller models (4GB+ RAM)

---

## Questions & Answers

### Q: Can I run this on 8GB RAM?
**A**: Yes, but use llama3.2:1b (1GB model). Expect ~5-8 second responses. Close other applications during the workshop.

### Q: Do I need a GPU?
**A**: No. Our entire demo runs CPU-only. GPU provides 2-10x speedup but is optional.

### Q: Will this work on older hardware?
**A**: If you have 8GB RAM and 4+ CPU cores from the last 5-7 years, yes. Performance will vary.

### Q: How much internet bandwidth do I need?
**A**: Initial setup requires downloading ~5-10GB (Docker images, models). Workshop itself can run offline after setup.

### Q: Can I use cloud services instead?
**A**: Yes, but that defeats the purpose of showing open-source, self-hosted solutions. The workshop focuses on running everything locally.

---

## Additional Resources

- **Ollama Models**: https://ollama.ai/library
- **n8n System Requirements**: https://docs.n8n.io/hosting/installation/
- **Docker Desktop Requirements**: https://docs.docker.com/desktop/

---

**Last Updated**: October 2025  
**Workshop Version**: 1.0  

*This is provided as-is. No warranty is expressed or implied. But I hope it works for you!*
