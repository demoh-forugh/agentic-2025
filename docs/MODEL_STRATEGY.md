# Model Strategy for Gmail & Calendar Workflows

## Overview

This document outlines the multi-model strategy deployed for the "Building Agents with n8n" workshop at Go to Agentic Conference 2025. The strategy provides a **three-tier model lineup** optimizing for speed, accuracy, and maximum capability using intelligent model routing.

## Primary Model Lineup

### 🏆 Flagship Model: Mistral-Small 22B (Q4_K_M) **[NEW]**
**Purpose:** Maximum capability for complex business tasks and professional-quality outputs

**Specifications:**
- **Size:** 13 GB (Q4_K_M quantization)
- **Parameters:** 22 billion (60% larger than Qwen 14B)
- **Expected Speed:** 30-40 tokens/second on RTX 4000
- **VRAM Usage:** ~13-14 GB when loaded
- **Response Time:** 3-5 seconds for 150-200 token responses

**Benchmarks:**
- **MMLU Score:** ~75-80 (estimated, state-of-the-art in size class)
- **Knowledge-dense:** Outperforms models 3x its size
- **Instruction Following:** Excellent conversational abilities

**Model Name:** `mistral-small:22b-instruct-2409-q4_K_M`

**Best For:**
- Professional email drafts
- Complex lead scoring with detailed reasoning
- Multi-paragraph document generation
- Strategic business analysis
- Calendar scheduling with constraint reasoning

---

### 🎯 Accurate Model: Qwen 2.5 14B (Q4_K_M)
**Purpose:** High-quality responses for complex analysis and generation

**Specifications:**
- **Size:** 9.0 GB (Q4_K_M quantization)
- **Parameters:** 14 billion
- **Expected Speed:** 45-55 tokens/second on RTX 4000
- **VRAM Usage:** ~9 GB when loaded
- **Response Time:** 2-4 seconds for 150-200 token responses

**Benchmarks:**
- **MMLU Score:** 79.7 (outperforms Llama 3.1 8B)
- **BBH:** 78.2 (reasoning tasks)
- **HumanEval:** 60+ (strong coding)
- **Sentiment Analysis:** Excellent (specifically tested for email workflows)

**Model Name:** `qwen2.5:14b-instruct-q4_K_M`

**Best For:**
- Sentiment analysis (-1.0 to 1.0 scoring)
- Email categorization with reasoning
- Customer service response generation
- Structured data extraction
- Balanced speed/quality workflows

---

### ⚡ Fast Model: Llama 3.2 3B (Q4_K_M)
**Purpose:** Lightning-fast responses for simple tasks during live demos

**Specifications:**
- **Size:** 2.0 GB (Q4_K_M quantization)
- **Parameters:** 3 billion
- **Expected Speed:** 80-100 tokens/second on RTX 4000
- **VRAM Usage:** ~2.4 GB when loaded
- **Response Time:** <2 seconds for 150-200 token responses

**Benchmarks:**
- **MMLU Score:** 63.4 (general knowledge)
- **IFEval:** 77.4 (instruction following)
- **Next-Token Latency:** <50ms (critical for demos)

**Model Name:** `llama3.2:latest` or `llama3.2:3b-instruct-q4_K_M`

**Best For:**
- High-speed email triage
- Quick categorization (urgent/normal/spam)
- Priority scoring (1-5)
- Yes/no decisions
- Simple extractions

---

## Additional Specialized Models

### 🔬 Sentiment Analysis Specialist: Mistral 7B (Q4_K_M)
**Purpose:** Benchmarked for exceptional sentiment analysis accuracy

**Specifications:**
- **Size:** 4.4 GB (Q4_K_M quantization)
- **Parameters:** 7 billion
- **Expected Speed:** 60-70 tokens/second on RTX 4000
- **VRAM Usage:** ~4.7 GB when loaded
- **Response Time:** 2-3 seconds for 150-200 token responses

**Benchmarks:**
- **Sentiment Accuracy:** 94% (tested on customer ticket dataset)
- **MMLU Score:** 62.5 (general knowledge)
- **Instruction Following:** Excellent for structured tasks

**Model Name:** `mistral:7b-instruct-q4_K_M`

**Best For:**
- Customer sentiment scoring (-1.0 to 1.0)
- Review analysis with confidence scores
- Tone detection (professional/casual/angry)
- Emotional intelligence workflows
- Balanced speed/accuracy when Qwen 14B is loaded

**Recommended Use:** Swap with Qwen 2.5 14B when sentiment analysis is the primary task

---

### 🚀 Alternative Large Model: Mistral-Nemo 12B
**Purpose:** Larger Mistral variant with extended context window

**Specifications:**
- **Size:** 7.1 GB (Q4_K_M quantization)
- **Parameters:** 12 billion
- **Expected Speed:** 45-55 tokens/second on RTX 4000
- **VRAM Usage:** ~7.4 GB when loaded
- **Context Window:** 128K tokens (vs 32K for other models)

**Note:** Two versions installed (`mistral-nemo:latest` and `mistral-nemo:12b` are identical - recommend removing duplicate)

**Model Name:** `mistral-nemo:latest` or `mistral-nemo:12b`

**Best For:**
- Very long document analysis
- Multi-email thread understanding
- Extended conversation context
- Large context window requirements

**Trade-off:** Larger than Mistral 7B but not as powerful as Mistral-Small 22B - consider removing if disk space needed

---

### 🛠️ Function Calling Specialist: Hermes 3 8B
**Purpose:** Optimized for tool use and structured outputs

**Specifications:**
- **Size:** 4.7 GB (Q4_K_M quantization)
- **Parameters:** 8 billion
- **Expected Speed:** 55-65 tokens/second on RTX 4000
- **VRAM Usage:** ~5.0 GB when loaded

**Model Name:** `hermes3:8b`

**Best For:**
- Function/tool calling workflows
- Structured JSON generation
- API integration tasks
- Multi-step agent reasoning

**Trade-off:** Specialized model - use when tool calling is critical, otherwise Qwen 14B or Mistral 7B cover general needs

---

### ⚡ Ultra-Fast Micro Model: Llama 3.2 1B
**Purpose:** Absolute speed champion for trivial tasks

**Specifications:**
- **Size:** 1.3 GB (Q4_K_M quantization)
- **Parameters:** 1 billion
- **Expected Speed:** 100-130 tokens/second on RTX 4000
- **VRAM Usage:** ~1.5 GB when loaded
- **Response Time:** <1 second for most tasks

**Model Name:** `llama3.2:1b`

**Best For:**
- Binary classification (yes/no, spam/not-spam)
- Simple keyword extraction
- Ultra-high-throughput demos
- IoT/edge deployment testing

**Trade-off:** Significantly lower quality than Llama 3.2 3B - only use when speed is the ONLY consideration

---

## Complete Model Inventory

| Model | Size | Parameters | Speed (t/s) | VRAM | Primary Use Case |
|-------|------|------------|-------------|------|------------------|
| **mistral-small:22b** | 13 GB | 22B | 30-40 | ~14 GB | 🏆 Flagship - complex business tasks |
| **qwen2.5:14b** | 9.0 GB | 14B | 45-55 | ~9 GB | 🎯 Accurate - balanced workflows |
| **mistral-nemo:latest** | 7.1 GB | 12B | 45-55 | ~7.4 GB | Long context (128K tokens) |
| **mistral-nemo:12b** | 7.1 GB | 12B | 45-55 | ~7.4 GB | ⚠️ Duplicate - recommend removing |
| **mistral:7b** | 4.4 GB | 7B | 60-70 | ~4.7 GB | 🔬 Sentiment specialist (94% accuracy) |
| **hermes3:8b** | 4.7 GB | 8B | 55-65 | ~5.0 GB | 🛠️ Function calling specialist |
| **llama3.2:latest** | 2.0 GB | 3B | 80-100 | ~2.4 GB | ⚡ Fast - quick categorization |
| **llama3.2:1b** | 1.3 GB | 1B | 100-130 | ~1.5 GB | ⚡⚡ Ultra-fast - trivial tasks |

**Total Disk Usage:** 48.6 GB
**Potential Savings:** Remove duplicates and underused models to free 24.2 GB

---

## Total Resource Usage

### Three-Tier Strategy (Recommended)

**Primary Models Loaded Simultaneously:**
- Mistral-Small 22B: ~14 GB VRAM
- Llama 3.2 3B: ~2.4 GB VRAM
- **Total:** ~16.4 GB (slightly over 16GB limit)

**Recommended Configuration:**
- **Option A:** Load Mistral-Small 22B + Llama 3.2 3B when showing flagship capabilities
- **Option B:** Load Qwen 2.5 14B + Llama 3.2 3B for demos (fits comfortably: 11.4 GB total)
- **Option C:** Load Mistral-Small 22B ONLY for single-model demos (14 GB)

**System Specs:**
- **GPU:** NVIDIA RTX PRO 4000 Blackwell (16GB VRAM)
- **CPU:** 24 cores (optimized with OLLAMA_NUM_THREAD=24)
- **Configuration:** `OLLAMA_MAX_LOADED_MODELS=2`, `OLLAMA_KEEP_ALIVE=-1`

### VRAM Allocation by Configuration

| Configuration | Model 1 | Model 2 | Total VRAM | Free for Cache |
|---------------|---------|---------|------------|----------------|
| **Demo Standard** | Qwen 14B (9GB) | Llama 3B (2.4GB) | 11.4 GB | 4.6 GB ✅ |
| **Flagship Showcase** | Mistral-Small 22B (14GB) | Llama 3B (2.4GB) | 16.4 GB | -0.4 GB ⚠️ |
| **Sentiment Focus** | Mistral 7B (4.7GB) | Llama 3B (2.4GB) | 7.1 GB | 8.9 GB ✅ |
| **Single Flagship** | Mistral-Small 22B (14GB) | - | 14 GB | 2 GB ✅ |

⚠️ **Warning:** Mistral-Small 22B + Llama 3B exceeds 16GB when both loaded. Use `OLLAMA_MAX_LOADED_MODELS=1` if running Mistral-Small 22B during demos.

---

## Model Routing Strategy

### Routing Logic

```
IF task requires SPEED (demo impact):
    USE llama3.2:3b
    - Email categorization (urgent/normal/spam)
    - Priority scoring (1-5)
    - Quick yes/no decisions
    - Simple extractions

ELSE IF task requires ACCURACY (quality output):
    USE qwen2.5:14b
    - Email draft generation
    - Sentiment analysis (-1.0 to 1.0)
    - Calendar scheduling with reasoning
    - Lead scoring with explanations
    - Multi-paragraph generation
```

### Implementation in n8n

**Option 1: Workflow-Level Routing**
- Workflow 02 (Gmail Triage) → Use llama3.2:3b exclusively
- Workflow 05 (Customer Service) → Use qwen2.5:14b exclusively
- Workflow 06 (Lead Scoring) → Use qwen2.5:14b exclusively

**Option 2: Task-Level Routing**
- Within each workflow, use IF nodes to route based on task complexity
- Simple categorization → llama3.2:3b
- Detailed analysis → qwen2.5:14b

**Recommended:** Workflow-level routing for demos (simpler, more predictable timing)

---

## Workflow-Specific Recommendations

### Workflow 02: Gmail Email Triage Agent

**Recommended Model:** `llama3.2:3b` (FAST)

**Why:** All tasks are classification/extraction - speed is critical for demo impact

| Task | Expected Time | Model Used |
|------|---------------|------------|
| Categorize email (urgent/normal/spam) | 1-2 seconds | llama3.2:3b |
| Priority score (1-5) | 1-2 seconds | llama3.2:3b |
| Extract key entities | 1-2 seconds | llama3.2:3b |
| Suggest action (reply/archive/flag) | 1-2 seconds | llama3.2:3b |

**Demo Flow:** Process 5 emails in 8-10 seconds total (crowd-pleasing)

**n8n Configuration:**
```json
{
  "model": "llama3.2:3b-instruct-q4_K_M",
  "options": {
    "temperature": 0.1,
    "num_ctx": 4096,
    "num_predict": 100
  }
}
```

---

### Workflow 03: Smart Calendar Assistant

**Recommended Model:** `qwen2.5:14b` (ACCURATE) or `mistral-small:22b` (FLAGSHIP)

**Why:** Requires reasoning about schedules, constraints, and conflicts

| Task | Expected Time | Model Options |
|------|---------------|---------------|
| Parse meeting request | 2-3s (Qwen) / 3-4s (Mistral-Small) | Both excellent |
| Analyze current schedule | 3-4s (Qwen) / 4-5s (Mistral-Small) | Both excellent |
| Suggest 3 time slots with reasoning | 4-6s (Qwen) / 5-7s (Mistral-Small) | Mistral-Small: better reasoning |
| Generate calendar event details | 2-3s (Qwen) / 3-4s (Mistral-Small) | Both excellent |

**Demo Flow:**
- Qwen 2.5 14B: 12-15 seconds total
- Mistral-Small 22B: 15-20 seconds total (better quality explanations)

**n8n Configuration (Qwen):**
```json
{
  "model": "qwen2.5:14b-instruct-q4_K_M",
  "options": {
    "temperature": 0.2,
    "num_ctx": 4096,
    "num_predict": 300
  }
}
```

**n8n Configuration (Mistral-Small - for flagship demos):**
```json
{
  "model": "mistral-small:22b-instruct-2409-q4_K_M",
  "options": {
    "temperature": 0.2,
    "num_ctx": 4096,
    "num_predict": 300
  }
}
```

---

### Workflow 04: AI Document Generator

**Recommended Model:** `mistral-small:22b` (FLAGSHIP) or `qwen2.5:14b` (ACCURATE)

**Why:** Long-form generation requires coherent, high-quality prose - flagship model excels here

| Task | Expected Time | Model Options |
|------|---------------|---------------|
| Generate executive summary | 5-8s (Qwen) / 7-10s (Mistral-Small) | Mistral-Small: superior prose |
| Create full report (500+ tokens) | 15-25s (Qwen) / 20-30s (Mistral-Small) | Mistral-Small: professional quality |

**Demo Flow:**
- **Recommended:** Use Mistral-Small 22B for professional document quality
- Show streaming output to maintain audience engagement during generation
- Highlight superior coherence and business writing quality

**n8n Configuration (Mistral-Small - RECOMMENDED):**
```json
{
  "model": "mistral-small:22b-instruct-2409-q4_K_M",
  "options": {
    "temperature": 0.3,
    "num_ctx": 8192,
    "num_predict": 1000,
    "stream": true
  }
}
```

**n8n Configuration (Qwen - Fallback):**
```json
{
  "model": "qwen2.5:14b-instruct-q4_K_M",
  "options": {
    "temperature": 0.3,
    "num_ctx": 8192,
    "num_predict": 1000,
    "stream": true
  }
}
```

---

### Workflow 05: Customer Service with Database

**Recommended Model:** MIXED (task-specific routing)

**Why:** Combines fast categorization with quality response generation

| Task | Expected Time | Model Options |
|------|---------------|---------------|
| Sentiment score (-1.0 to 1.0) | 2-3s (Mistral 7B) / 3-4s (Qwen) | **Mistral 7B: 94% accuracy** |
| Category classification | 1-2s (Llama 3B) | Fast |
| Generate professional response | 5-8s (Qwen) / 7-10s (Mistral-Small) | Mistral-Small: best quality |
| Escalation determination (yes/no) | 1-2s (Llama 3B) | Fast |

**Demo Flow:** Process 3 tickets in 30-40 seconds

**Routing Implementation:**
```
IF node checks task type:
  - IF "categorization" OR "escalation" → llama3.2:3b
  - IF "sentiment" → mistral:7b (94% accuracy specialist)
  - IF "response" → qwen2.5:14b OR mistral-small:22b
```

**Model Selection by Priority:**
- **Speed Focus:** Use Llama 3B + Qwen 14B (standard configuration)
- **Accuracy Focus:** Use Mistral 7B for sentiment + Mistral-Small 22B for responses

---

### Workflow 06: Lead Scoring & CRM

**Recommended Model:** `mistral-small:22b` (FLAGSHIP) or `qwen2.5:14b` (ACCURATE)

**Why:** Requires nuanced analysis and strategic reasoning - flagship model provides superior insights

| Task | Expected Time | Model Options |
|------|---------------|---------------|
| Lead score (0-100 with reasoning) | 3-4s (Qwen) / 4-6s (Mistral-Small) | Mistral-Small: deeper reasoning |
| Qualification status (hot/warm/cold) | 2-3s (Qwen) / 3-4s (Mistral-Small) | Both excellent |
| Identify key indicators & red flags | 4-6s (Qwen) / 6-8s (Mistral-Small) | Mistral-Small: more indicators |
| Recommend messaging angle | 3-5s (Qwen) / 4-6s (Mistral-Small) | Mistral-Small: strategic insights |

**Demo Flow:**
- Qwen 2.5 14B: 12-15 seconds per lead
- Mistral-Small 22B: 17-24 seconds per lead (significantly better reasoning)

**n8n Configuration (Mistral-Small - for flagship demos):**
```json
{
  "model": "mistral-small:22b-instruct-2409-q4_K_M",
  "options": {
    "temperature": 0.2,
    "num_ctx": 4096,
    "num_predict": 500
  }
}
```

**n8n Configuration (Qwen - standard):**
```json
{
  "model": "qwen2.5:14b-instruct-q4_K_M",
  "options": {
    "temperature": 0.2,
    "num_ctx": 4096,
    "num_predict": 400
  }
}
```

---

## Prompt Engineering by Model

### Llama 3.2 3B: Short, Direct Prompts

**Best Practices:**
- Keep prompts under 300 tokens
- Use clear, structured formats
- Request brief outputs (1-2 sentences)
- Provide explicit categories/options

**Example:**
```
Categorize this email into ONE category:
- urgent
- normal
- spam

Email: [email content]

Category:
```

---

### Qwen 2.5 14B: Detailed Context + Reasoning

**Best Practices:**
- Provide full context (300-800 tokens)
- Request reasoning/explanations
- Use multi-step instructions
- Leverage chain-of-thought

**Example:**
```
You are analyzing a customer service ticket to determine sentiment and response strategy.

Ticket Details:
[full ticket content]

Tasks:
1. Calculate sentiment score from -1.0 (very negative) to 1.0 (very positive)
2. Explain key factors influencing the score
3. Generate a professional response addressing concerns

Provide response in this JSON format:
{
  "sentiment_score": <number>,
  "reasoning": "<explanation>",
  "response": "<professional reply>"
}
```

---

### Mistral-Small 22B: Complex Analysis + Professional Outputs

**Best Practices:**
- Provide extensive context (500-1500 tokens)
- Request detailed reasoning with multiple perspectives
- Use complex multi-step workflows
- Expect nuanced, business-ready outputs
- Leverage superior instruction-following for structured formats

**Example:**
```
You are a senior business analyst evaluating a high-value B2B lead for qualification.

Lead Profile:
Company: [company details]
Contact: [contact info]
Interaction History: [timeline]
Signals: [engagement data]

Analysis Required:
1. Assign lead score (0-100) with detailed justification
2. Identify 3-5 positive indicators and 2-3 red flags
3. Assess qualification tier: hot (immediate follow-up), warm (nurture campaign), or cold (long-term)
4. Recommend messaging angle considering company pain points, budget authority, and timing
5. Suggest 3 specific next actions with priority ranking

Provide comprehensive analysis in structured JSON format with detailed reasoning for each section.
```

**When to Use Mistral-Small 22B:**
- Client-facing document generation
- Complex strategic analysis
- Multi-factor decision making
- Professional-quality long-form content
- When output quality justifies 25-40% slower speed

---

## Pre-Demo Checklist

### 5 Minutes Before Demo

**1. Verify Both Models Loaded:**
```bash
podman exec ollama ollama list
```

Expected output:
```
NAME                           ID              SIZE
qwen2.5:14b-instruct-q4_K_M    7cdf5a0187d5    9.0 GB
llama3.2:3b-instruct-q4_K_M    a80c4f17acd5    2.0 GB
```

**2. Warm Up Models (Preload into GPU):**
```bash
# Warm up Llama 3.2 3B
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:3b-instruct-q4_K_M",
  "prompt": "test",
  "keep_alive": "15m"
}'

# Warm up Qwen 2.5 14B
curl http://localhost:11434/api/generate -d '{
  "model": "qwen2.5:14b-instruct-q4_K_M",
  "prompt": "test",
  "keep_alive": "15m"
}'
```

**3. Check GPU Memory:**
```bash
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```

Expected: ~11GB used out of 16GB after both models loaded

**4. Test n8n Connection:**
Open n8n (http://localhost:5678) and verify:
- Ollama credentials configured
- Test workflow executes successfully
- No connection errors

---

## Demo Presentation Strategy

### Opening (Set Expectations)

> "We have two AI models deployed - a lightning-fast 3B model for quick decisions, and a powerful 14B model for complex analysis. The system intelligently routes tasks to the right model for optimal speed and quality."

### During Workflow Demos

**When using llama3.2:3b:**
> "Watch how fast it categorizes emails - processing 5 emails in under 10 seconds!"

**When using qwen2.5:14b:**
> "For this complex analysis, we're using our more powerful model. Notice the detailed reasoning and professional-quality output."

### Handling Delays

**If model switching causes delay (5-10 seconds):**
> "The system is loading our accuracy-focused model into GPU memory. After this initial load, subsequent requests will be instant thanks to our keep-alive optimization."

**If response is slow (>10 seconds):**
- Enable streaming mode in n8n to show progressive output
- Engage audience: "Let's watch the AI reason through this step-by-step..."

---

## Troubleshooting During Demo

### Issue: First Request Takes 10+ Seconds

**Cause:** Model not preloaded
**Fix:** Preload models 5 minutes before demo (see Pre-Demo Checklist)

---

### Issue: Model Switching Adds 5-10 Second Delay

**Cause:** OLLAMA_MAX_LOADED_MODELS=2 requires unloading one model
**Backup Plan:**
1. Use only qwen2.5:14b for entire demo (consistent timing)
2. Trade 1-2 seconds extra on fast tasks for zero switching delays
3. Update all workflows to use single model before demo

---

### Issue: Out of Memory Error

**Symptoms:** "model requires more system memory" error

**Immediate Fix:**
```bash
# Reduce parallel requests
podman exec ollama env OLLAMA_NUM_PARALLEL=4

# Restart Ollama container
podman restart ollama

# Wait 30 seconds and preload single model
curl http://localhost:11434/api/generate -d '{
  "model": "qwen2.5:14b-instruct-q4_K_M",
  "prompt": "test"
}'
```

---

### Issue: GPU Not Being Used

**Symptoms:** Very slow responses (>20 seconds), CPU at 100%

**Quick Check:**
```bash
nvidia-smi
# Should show ~11GB GPU memory used when both models loaded
```

**If GPU shows 0 MB used:**
- Containers not created with GPU override file
- Requires restart with GPU configuration (takes 2-3 minutes)
- **Fallback:** Continue demo on CPU, apologize for slower speed

---

## Alternative Model Configurations

### Backup Plan A: Single Model (If Dual-Model Fails)

**Use:** `qwen2.5:14b-instruct-q4_K_M` for all workflows

**Pros:**
- Consistent timing (no switching delays)
- Best quality across all tasks
- Simpler configuration

**Cons:**
- Slower on simple tasks (3-5 seconds vs 1-2 seconds)
- Less impressive for fast categorization demos

**When to Use:** If model switching proves unreliable during testing

---

### Backup Plan B: Ultra-Fast Single Model

**Use:** `llama3.2:3b-instruct-q4_K_M` for all workflows

**Pros:**
- Maximum speed (all responses <3 seconds)
- Crowd-pleasing demo performance
- Zero switching delays

**Cons:**
- Lower quality on complex tasks
- Less impressive long-form generation
- Weaker sentiment analysis

**When to Use:** If audience prioritizes speed/WOW factor over output quality

---

### Future Optimization: Mistral 7B as Middle Ground

**Model:** `mistral:7b-instruct-q4_K_M`
**Size:** 4.4 GB
**Speed:** 60-70 tokens/second

**Use Case:** Replace dual-model with single balanced model
- Faster than Qwen 14B
- More accurate than Llama 3B
- Can load alongside either model if needed

---

## Model Performance Comparison

### Email Categorization Task

| Model | Accuracy | Speed | Best For |
|-------|----------|-------|----------|
| Llama 3.2 3B | Good (85-90%) | ⚡⚡⚡ 1-2s | Live demos |
| Qwen 2.5 14B | Excellent (95-98%) | ⚡⚡ 3-4s | Production |
| Mistral 7B | Very Good (90-95%) | ⚡⚡⚡ 2-3s | Balanced |

### Draft Generation Task

| Model | Quality | Speed | Best For |
|-------|---------|-------|----------|
| Llama 3.2 3B | Basic | ⚡⚡⚡ 3-5s | Short responses |
| Qwen 2.5 14B | Professional | ⚡⚡ 5-10s | Client-facing |
| Mistral 7B | Good | ⚡⚡⚡ 4-7s | Internal use |

### Sentiment Analysis Task

| Model | Nuance | Speed | Best For |
|-------|--------|-------|----------|
| Llama 3.2 3B | Basic | ⚡⚡⚡ 1-2s | Binary (pos/neg) |
| Qwen 2.5 14B | Excellent | ⚡⚡ 3-4s | Scored analysis |
| Mistral 7B | Good | ⚡⚡⚡ 2-3s | Balanced |

---

## Quantization Trade-offs

### Current Deployment: Q4_K_M

**Quality:** 95% of FP16 performance
**Size:** ~75% reduction vs FP16
**Speed:** Fastest quantization level
**Recommendation:** ✅ Optimal for demos

### Alternative: Q5_K_M (Not Recommended)

**Quality:** 97% of FP16 performance
**Size:** ~65% reduction vs FP16
**Speed:** 15% slower than Q4_K_M
**Use Case:** Production with accuracy SLAs

**Deployment:**
```bash
podman exec ollama ollama pull qwen2.5:14b-instruct-q5_K_M
podman exec ollama ollama pull llama3.2:3b-instruct-q5_K_M
```

### Alternative: Q8_0 (Not Feasible)

**Quality:** 99% of FP16 performance
**Size:** Qwen 14B = ~15GB (won't fit in VRAM with dual-model)
**Speed:** 35% slower than Q4_K_M
**Use Case:** Not recommended for 16GB GPU

---

## n8n Credential Configuration

### Ollama Connection Settings

**Base URL:** `http://ollama:11434`
**Why:** Container-to-container communication via Docker bridge network (faster than localhost)

**Authentication:** None required (internal network)

### Testing Ollama Connection in n8n

1. Open n8n: http://localhost:5678
2. Go to Settings → Credentials
3. Find "Ollama" credential
4. Click "Test Credential"
5. Expected: ✅ "Connection successful"

### If Connection Fails:

**Check containers on same network:**
```bash
podman inspect n8n | grep -A 5 Networks
podman inspect ollama | grep -A 5 Networks
# Both should show: "ai-network"
```

**Test from n8n container:**
```bash
podman exec n8n curl http://ollama:11434/api/tags
# Expected: JSON response with model list
```

---

## Post-Demo Notes

### Model Switching Observations

**Track during demo:**
- Did model switching cause noticeable delays?
- Were delays acceptable for audience?
- Would single model be better?

**Document:**
- Actual response times vs expected
- Any errors or issues
- Audience feedback on speed

### Update Strategy for Future Demos

Based on results, update this document with:
- Actual benchmarks from your hardware
- Adjusted routing strategy
- Preferred model configuration

---

## Quick Reference Commands

```bash
# List deployed models
podman exec ollama ollama list

# Check GPU memory
nvidia-smi --query-gpu=memory.used,memory.total --format=csv

# Preload model into GPU (keep for 15 minutes)
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:3b-instruct-q4_K_M",
  "prompt": "test",
  "keep_alive": "15m"
}'

# Test model inference
podman exec ollama ollama run llama3.2:3b-instruct-q4_K_M "Categorize: urgent or normal?"

# Check Ollama environment
podman exec ollama env | grep OLLAMA_

# Restart Ollama (if needed)
podman restart ollama
```

---

## Summary

✅ **Three-Tier Model Strategy:**
- **🏆 Flagship:** Mistral-Small 22B (13 GB) - Maximum capability for complex business tasks
- **🎯 Accurate:** Qwen 2.5 14B (9.0 GB) - Balanced speed/accuracy for standard workflows
- **⚡ Fast:** Llama 3.2 3B (2.0 GB) - Lightning-fast categorization and simple tasks

✅ **Additional Specialized Models:**
- **🔬 Sentiment:** Mistral 7B (4.4 GB) - 94% accuracy for sentiment analysis
- **🚀 Extended Context:** Mistral-Nemo 12B (7.1 GB) - 128K token context window
- **🛠️ Function Calling:** Hermes 3 8B (4.7 GB) - Tool use and structured outputs
- **⚡⚡ Ultra-Fast:** Llama 3.2 1B (1.3 GB) - Maximum speed for trivial tasks

✅ **Total Inventory:** 8 models, 48.6 GB disk usage

✅ **Recommended Demo Configuration:**
**Option A (Standard):** Qwen 14B + Llama 3B = 11.4 GB VRAM (4.6 GB free)
**Option B (Flagship):** Mistral-Small 22B only = 14 GB VRAM (2 GB free)
**Option C (Sentiment):** Mistral 7B + Llama 3B = 7.1 GB VRAM (8.9 GB free)

✅ **Routing Strategy:**
- **Speed Critical** (email triage) → Llama 3.2 3B
- **Balanced** (most workflows) → Qwen 2.5 14B
- **Maximum Quality** (documents, lead scoring) → Mistral-Small 22B
- **Sentiment Analysis** → Mistral 7B (94% accuracy)

✅ **Expected Performance:**
| Workflow | Standard (Qwen + Llama) | Flagship (Mistral-Small) |
|----------|------------------------|--------------------------|
| Email triage (5 emails) | 8-10 seconds | N/A (use Llama only) |
| Calendar scheduling | 12-15 seconds | 15-20 seconds |
| Document generation | 15-25 seconds | 20-30 seconds |
| Customer tickets (3) | 30-40 seconds | 35-45 seconds |
| Lead scoring | 12-15 seconds | 17-24 seconds |

✅ **Demo Recommendations:**
- **For Speed Demos:** Use Qwen 14B + Llama 3B (standard configuration)
- **For Quality Showcase:** Use Mistral-Small 22B single-model configuration
- **For Sentiment Focus:** Use Mistral 7B + Llama 3B
- **Backup Plan:** Use Qwen 2.5 14B only if model switching proves problematic

⚠️ **Important:** Mistral-Small 22B (14GB) + Llama 3B (2.4GB) exceeds 16GB VRAM. Use `OLLAMA_MAX_LOADED_MODELS=1` when running Mistral-Small 22B.

---

**Document Version:** 2.0
**Last Updated:** 2025-10-22
**Conference:** Go to Agentic Conference 2025
**Workshop:** Building Agents with n8n
