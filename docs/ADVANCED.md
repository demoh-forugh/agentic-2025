# Advanced Topics

Going beyond the basics - production, scaling, and advanced patterns.

---

## 🚀 Production Deployment

### Using PostgreSQL for n8n

For production workloads, use PostgreSQL instead of SQLite for better performance and reliability.

**1. Update docker-compose.yml**:

Uncomment the PostgreSQL service and update n8n configuration:

```yaml
services:
  postgres:
    image: postgres:15-alpine
    container_name: n8n-postgres
    environment:
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-change_this_password}
      - POSTGRES_DB=n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - ai-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n"]
      interval: 10s
      timeout: 5s
      retries: 5

  n8n:
    # ... existing config ...
    environment:
      # Add these:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD:-change_this_password}
    depends_on:
      postgres:
        condition: service_healthy
```

**Benefits**:
- Better concurrent execution handling
- Reliable workflow execution history
- Easier backups and recovery
- Better performance at scale

---

## 🔐 Security Best Practices

### 1. Enable Authentication

**Basic Auth** (simple):

```yaml
n8n:
  environment:
    - n8n_BASIC_AUTH_ACTIVE=true
    - n8n_BASIC_AUTH_USER=admin
    - n8n_BASIC_AUTH_PASSWORD=${n8n_PASSWORD}
```

**JWT Auth** (advanced):

```yaml
n8n:
  environment:
    - n8n_JWT_AUTH_ACTIVE=true
    - n8n_JWT_AUTH_HEADER=Authorization
    - n8n_JWT_AUTH_HEADER_VALUE_PREFIX=Bearer
```

### 2. Use Environment Variables for Secrets

Never hardcode credentials in workflows!

```yaml
# .env file
OPENAI_API_KEY=sk-xxxxx
GMAIL_CLIENT_ID=xxxxx.apps.googleusercontent.com
GMAIL_CLIENT_SECRET=GOCSPX-xxxxx
```

Reference in n8n:
```javascript
// In n8n expression
={{ $env.OPENAI_API_KEY }}
```

### 3. Secure Webhooks

```yaml
n8n:
  environment:
    - WEBHOOK_URL=https://your-domain.com/
    - n8n_PAYLOAD_SIZE_MAX=16  # MB
```

Add API key validation in webhook workflows:

```javascript
// In IF node
$json.headers.authorization === 'Bearer your-secret-token'
```

### 4. Network Security

Use Docker networks to isolate services:

```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No internet access

services:
  n8n:
    networks:
      - frontend
      - backend
  
  postgres:
    networks:
      - backend  # Only accessible from n8n
```

---

## 📈 Scaling and Performance

### 1. Queue Mode for High Throughput

Enable queue mode for handling many concurrent workflows:

```yaml
n8n:
  environment:
    - EXECUTIONS_MODE=queue
    - QUEUE_BULL_REDIS_HOST=redis
    - QUEUE_BULL_REDIS_PORT=6379
    
services:
  redis:
    image: redis:7-alpine
    networks:
      - ai-network
```

### 2. Horizontal Scaling

Run multiple n8n worker instances:

```yaml
n8n-main:
  # Main instance (handles UI and scheduling)
  environment:
    - n8n_PROCESS_MODE=main

n8n-worker-1:
  # Worker instance 1
  environment:
    - n8n_PROCESS_MODE=worker
    - n8n_PORT=5679  # Different port

n8n-worker-2:
  # Worker instance 2
  environment:
    - n8n_PROCESS_MODE=worker
    - n8n_PORT=5680
```

### 3. Optimize Ollama Performance

**GPU Acceleration and Performance Tuning:**

This setup includes comprehensive GPU optimization. GPU configuration is handled automatically by setup scripts.

**Windows/Podman:**
```bash
# Use GPU override file
podman-compose -f configs/docker-compose.yml -f configs/docker-compose.podman-gpu.yml up -d
```

**Docker:**
```bash
docker compose -f configs/docker-compose.yml -f configs/docker-compose.gpu.yml up -d
```

**Included Optimizations:**
- `OLLAMA_KEEP_ALIVE=-1` - Models stay loaded indefinitely (zero cold starts)
- `OLLAMA_NUM_PARALLEL=2` - Concurrent request handling (adjust per GPU)
- `OLLAMA_MAX_LOADED_MODELS=1` - Load one model at a time for 8-16GB GPUs
- `OLLAMA_FLASH_ATTENTION=1` - Optimized attention mechanism
- `OLLAMA_KV_CACHE_TYPE=q8_0` - 50% memory reduction for KV cache

**Model Parameter Tuning** (in n8n Ollama nodes):
```json
{
  "num_ctx": 4096,      // Context window (2048-8192)
  "num_predict": 512,   // Max output tokens
  "temperature": 0.7,   // Creativity (0-1)
  "repeat_penalty": 1.1 // Avoid repetition
}
```

**Expected Performance** (RTX PRO 4000 16GB):
- **Cold start**: 0s (models stay loaded)
- **Average response**: 1-4 seconds depending on model
- **Concurrent requests**: Up to 8 parallel (with NUM_PARALLEL=8)
- **GPU utilization**: 80-95% during inference

**See**: `docs/PERFORMANCE_OPTIMIZATION.md` for complete tuning guide with:
- All 8 environment variables explained
- Model selection and quantization guide
- Troubleshooting GPU detection issues
- Performance benchmarks and verification scripts
- n8n integration best practices

### 4. Caching Strategies

Implement caching to reduce API calls and LLM inference:

```javascript
// In n8n Function node
const cacheKey = `result_${$json.input_hash}`;
const cached = await $storage.get(cacheKey);

if (cached) {
  return cached;
}

// Process and cache result
const result = await processData($json);
await $storage.set(cacheKey, result, 3600); // Cache for 1 hour

return result;
```

---

## 🤖 Advanced Agent Patterns

### 1. Multi-Agent Orchestration

Create specialized agents that work together:

```
User Request
    ↓
[Router Agent] ← Decides which specialist to use
    ↓
    ├─→ [Research Agent] ← Gathers information
    ├─→ [Analysis Agent] ← Processes data
    ├─→ [Writing Agent]  ← Creates output
    └─→ [Review Agent]   ← Quality check
         ↓
    Final Output
```

**Implementation in n8n**:
- Use Switch node for routing
- Separate workflows for each agent
- Use HTTP Request nodes to call sub-workflows
- Implement error handling and fallbacks

### 2. Retrieval Augmented Generation (RAG)

Enhance LLM responses with your own data:

**Architecture**:
```
Document Store (Vector DB)
    ↓
User Query → Embedding → Similarity Search
    ↓
Relevant Context + Query → LLM → Response
```

**n8n Implementation**:

1. **Embed documents**:
```javascript
// Use embedding API (OpenAI, Cohere, etc.)
const embedding = await getEmbedding($json.text);
// Store in vector database (Pinecone, Weaviate, etc.)
```

2. **Search and augment**:
```javascript
// Get relevant context
const context = await searchVectorDB($json.query);

// Build augmented prompt
const prompt = `Context: ${context}\n\nQuestion: ${$json.query}\n\nAnswer:`;

// Send to LLM
```

### 3. Agentic Workflows with Tools

Give your agent access to tools:

```javascript
const tools = {
  web_search: async (query) => { /* ... */ },
  calculator: async (expr) => { /* ... */ },
  database_query: async (sql) => { /* ... */ }
};

// Agent loop
while (!taskComplete) {
  const response = await llm.generate(prompt);
  
  if (response.tool_call) {
    const result = await tools[response.tool](response.args);
    prompt += `\nTool result: ${result}`;
  } else {
    return response.answer;
  }
}
```

### 4. Long-Running Agents with Memory

Implement persistent memory for agents:

**Short-term memory** (conversation):
```javascript
const conversationHistory = [];

conversationHistory.push({
  role: 'user',
  content: $json.message
});

const response = await llm.chat(conversationHistory);

conversationHistory.push({
  role: 'assistant',
  content: response
});
```

**Long-term memory** (knowledge base):
- Store important facts in database
- Retrieve relevant memories before each interaction
- Update memories based on new information

---

## 🔌 Custom Integrations

### 1. Create Custom n8n Nodes

**Directory structure**:
```
custom-nodes/
├── package.json
└── nodes/
    └── MyCustomNode/
        ├── MyCustomNode.node.ts
        └── MyCustomNode.node.json
```

**Basic node template**:
```typescript
import { INodeType, INodeTypeDescription } from 'n8n-workflow';

export class MyCustomNode implements INodeType {
  description: INodeTypeDescription = {
    displayName: 'My Custom Node',
    name: 'myCustomNode',
    group: ['transform'],
    version: 1,
    description: 'Does something custom',
    defaults: {
      name: 'My Custom Node',
    },
    inputs: ['main'],
    outputs: ['main'],
    properties: [
      {
        displayName: 'Parameter',
        name: 'parameter',
        type: 'string',
        default: '',
        required: true,
      },
    ],
  };

  async execute(this: IExecuteFunctions) {
    // Your logic here
  }
}
```

### 2. Integrate with External APIs

**Best practices**:

```javascript
// Use retry logic
const maxRetries = 3;
for (let i = 0; i < maxRetries; i++) {
  try {
    const response = await fetch(url, options);
    return response;
  } catch (error) {
    if (i === maxRetries - 1) throw error;
    await sleep(1000 * Math.pow(2, i)); // Exponential backoff
  }
}

// Rate limiting
const rateLimiter = {
  calls: 0,
  resetTime: Date.now() + 60000,
  
  async checkLimit() {
    if (Date.now() > this.resetTime) {
      this.calls = 0;
      this.resetTime = Date.now() + 60000;
    }
    
    if (this.calls >= 100) { // 100 calls per minute
      await sleep(this.resetTime - Date.now());
    }
    
    this.calls++;
  }
};
```

---

## 📊 Monitoring and Observability

### 1. Enable n8n Metrics

```yaml
n8n:
  environment:
    - n8n_METRICS=true
    - n8n_METRICS_PREFIX=n8n_
```

Access at: `http://localhost:5678/metrics`

### 2. Integrate with Prometheus & Grafana

```yaml
prometheus:
  image: prom/prometheus:latest
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
  ports:
    - "9090:9090"

grafana:
  image: grafana/grafana:latest
  ports:
    - "3001:3000"
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=admin
```

**prometheus.yml**:
```yaml
scrape_configs:
  - job_name: 'n8n'
    static_configs:
      - targets: ['n8n:5678']
```

### 3. Logging Best Practices

```javascript
// In n8n workflows, use consistent logging
const logger = {
  info: (msg, data) => console.log(JSON.stringify({
    level: 'info',
    message: msg,
    data,
    timestamp: new Date().toISOString()
  })),
  error: (msg, error) => console.error(JSON.stringify({
    level: 'error',
    message: msg,
    error: error.message,
    stack: error.stack,
    timestamp: new Date().toISOString()
  }))
};
```

### 4. Health Checks

Create a monitoring workflow:

```javascript
// Check all services health
const services = [
  { name: 'Ollama', url: 'http://ollama:11434/api/tags' },
  { name: 'Database', url: 'postgres://...' },
];

const results = await Promise.all(
  services.map(async (service) => {
    try {
      const response = await fetch(service.url);
      return { ...service, status: 'UP', code: response.status };
    } catch (error) {
      return { ...service, status: 'DOWN', error: error.message };
    }
  })
);

// Alert if any service is down
const downServices = results.filter(r => r.status === 'DOWN');
if (downServices.length > 0) {
  await sendAlert(`Services down: ${downServices.map(s => s.name).join(', ')}`);
}
```

---

## 🌐 Deployment Options

### 1. Docker Swarm

```bash
docker swarm init
docker stack deploy -c docker-compose.yml n8n-stack
```

### 2. Kubernetes

See: [n8n Kubernetes deployment guide](https://docs.n8n.io/hosting/installation/docker/#kubernetes)

### 3. Cloud Platforms

- **AWS**: ECS, EKS, or EC2
- **Google Cloud**: GKE or Compute Engine
- **Azure**: AKS or Container Instances
- **DigitalOcean**: Kubernetes or Droplets

### 4. Reverse Proxy (Nginx)

```nginx
server {
    listen 80;
    server_name n8n.yourdomain.com;

    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

---

## 🎓 Learning Resources

### Books
- "Building LLM Applications" by Hannes Hapke
- "Designing Data-Intensive Applications" by Martin Kleppmann

### Courses
- [n8n Academy](https://docs.n8n.io/courses/)
- [LangChain Documentation](https://python.langchain.com/)

### Community
- [n8n Community Forum](https://community.n8n.io/)
- [Ollama Discord](https://discord.gg/ollama)
- [r/LocalLLaMA](https://reddit.com/r/LocalLLaMA)

---

## 💡 Pro Tips

1. **Version control your workflows**: Export workflows as JSON and commit to git
2. **Test in isolation**: Use manual triggers for testing before enabling schedules
3. **Monitor costs**: Even with local LLMs, track electricity and compute costs
4. **Document your agents**: Include descriptions in nodes and workflows
5. **Plan for failure**: Implement error handling, retries, and fallbacks
6. **Optimize prompts**: Good prompts are 10x more important than model size
7. **Start simple**: Build MVP workflows first, then add complexity

---

**Ready to build production-grade AI agents? Let's go! 🚀**
