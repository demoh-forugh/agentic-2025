# AI Model Strategy - Three-Tier Architecture

## 🏆 Flagship Tier: Maximum Capability

**Mistral-Small 22B** - Professional quality (30-40 tok/s)
- Size: 13 GB | 22B parameters | Q4_K_M quantization
- Use for: Complex business analysis, professional documents, lead scoring
- Response time: 3-7 seconds (quality worth the wait)
- VRAM: ~14 GB when loaded (requires ≥16 GB dedicated GPU memory)

## 🎯 Accurate Tier: Balanced Performance

**Qwen 2.5 14B** - High accuracy (45-55 tok/s)
- Size: 9.0 GB | 14B parameters | Q4_K_M quantization
- Use for: Complex analysis, drafts, reasoning, balanced workflows
- Response time: 2-4 seconds
- VRAM: ~9 GB when loaded (sweet spot for 12 GB GPUs)

## ⚡ Fast Tier: Maximum Speed

**Llama 3.2 3B** - Lightning fast (80-100 tok/s)
- Size: 2.0 GB | 3B parameters | Q4_K_M quantization
- Use for: Quick decisions, categorization, priority scoring
- Response time: 1-2 seconds
- VRAM: ~2.4 GB when loaded (best pick for 8 GB GPUs and below)

---

## 🔬 Specialized Models Available

**Mistral 7B** - Sentiment specialist (60-70 tok/s)
- Size: 4.4 GB | **94% sentiment accuracy** (benchmarked)
- Use for: Customer sentiment scoring, review analysis, tone detection
- VRAM: ~4.7 GB when loaded (comfortable on 8 GB GPUs)

**Mistral-Nemo 12B** - Extended context (45-55 tok/s)
- Size: 7.1 GB | 128K token context window
- Use for: Long document analysis, multi-email threads
- VRAM: ~7.4 GB when loaded (balanced choice for 10–12 GB GPUs)

**Hermes 3 8B** - Function calling (55-65 tok/s)
- Size: 4.7 GB | Optimized for tool use and structured JSON
- VRAM: ~5.0 GB when loaded (safe on ≥8 GB GPUs)

**Llama 3.2 1B** - Ultra-fast (100-130 tok/s)
- Size: 1.3 GB | Maximum speed for binary classification
- VRAM: ~1.5 GB when loaded

---

## Model Routing by Workflow

| Workflow              | Standard Config       | Flagship Config       | Demo Time (Standard) | Demo Time (Flagship) |
|-----------------------|-----------------------|-----------------------|----------------------|----------------------|
| 02 - Gmail Triage     | Llama 3.2 3B          | Llama 3.2 3B          | 8-10s for 5 emails   | 8-10s for 5 emails   |
| 03 - Calendar         | Qwen 2.5 14B          | Mistral-Small 22B     | 12-15s total         | 15-20s total         |
| 04 - Document Gen     | Qwen 2.5 14B          | **Mistral-Small 22B** | 15-25s (streaming)   | 20-30s (streaming)   |
| 05 - Customer Service | Mistral 7B + Llama 3B | Mistral-Small 22B     | 30-40s for 3 tickets | 35-45s for 3 tickets |
| 06 - Lead Scoring     | Qwen 2.5 14B          | **Mistral-Small 22B** | 12-15s per lead      | 17-24s per lead      |

**Bold** = Recommended for flagship capability showcase

---

## Demo Configuration Options

### Option A: Standard (Recommended for Speed)
- **Models:** Qwen 2.5 14B + Llama 3.2 3B
- **VRAM:** 11.4 GB (4.6 GB free for cache)
- **Best For:** Balanced speed and accuracy demos
- **Concurrent:** 8 parallel requests

### Option B: Flagship (Recommended for Quality)
- **Models:** Mistral-Small 22B (single model)
- **VRAM:** 14 GB (2 GB free for cache)
- **Best For:** Professional document generation, complex lead scoring
- **Concurrent:** 4-6 parallel requests
- ⚠️ Use `OLLAMA_MAX_LOADED_MODELS=1`

### Option C: Sentiment Focus
- **Models:** Mistral 7B + Llama 3.2 3B
- **VRAM:** 7.1 GB (8.9 GB free for cache)
- **Best For:** Customer service workflows with sentiment analysis
- **Concurrent:** 8 parallel requests

---

## Quick Stats

✅ **Total Inventory:** 7 models, 41.5 GB disk
✅ **GPU:** NVIDIA RTX PRO 4000 (16GB VRAM)
✅ **Models stay loaded:** Zero cold starts (KEEP_ALIVE=-1)
✅ **Concurrent workflows:** Up to 8 simultaneous (NUM_PARALLEL=8)
✅ **Optimizations:** Flash Attention, Q8_0 KV Cache, 24 CPU threads

---

## Pre-Demo Checklist (5 Minutes Before)

```powershell
# Verify GPU detection
nvidia-smi

# Check loaded models
podman exec ollama ollama list

# Warm up models (Standard Config)
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:latest",
  "prompt": "test", "keep_alive": "15m"
}'

curl http://localhost:11434/api/generate -d '{
  "model": "qwen2.5:14b",
  "prompt": "test", "keep_alive": "15m"
}'

# OR warm up flagship
curl http://localhost:11434/api/generate -d '{
  "model": "mistral-small:22b-instruct-2409-q4_K_M",
  "prompt": "test", "keep_alive": "15m"
}'
```

---

## Model Selection Quick Reference

**Choose Llama 3.2 3B when:**
- Speed is critical (demos need WOW factor)
- Task is simple (categorization, yes/no)
- Processing multiple items quickly

**Choose Qwen 2.5 14B when:**
- Need balanced speed and accuracy
- Sentiment analysis (-1.0 to 1.0 scoring)
- Moderate complexity drafts/analysis

**Choose Mistral-Small 22B when:**
- Professional document quality required
- Complex strategic reasoning needed
- Lead scoring with detailed insights
- Client-facing output

**Choose Mistral 7B when:**
- Sentiment analysis is primary task (94% accuracy)
- Customer review/feedback analysis
- Tone detection critical

---

*Building Agents with n8n - Go to Agentic Conference 2025*
*Three-Tier Model Strategy: Fast • Accurate • Flagship*
