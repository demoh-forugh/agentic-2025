# Building Agents with n8n - Workshop Materials
## Go to Agentic Conference 2025

**Date:** Monday, October 27, 2025 | 1:00 PM - 2:00 PM (US/Eastern)  
**Workshop Duration:** 1 hour

---

## 🎯 Workshop Overview

Welcome to our hands-on workshop on building AI agents with open-source tools! This session demonstrates how to create powerful automation workflows using n8n, Ollama, and OpenWebUI—all running locally on your machine.

### What You'll Learn

- Install and configure a complete local AI agent stack
- Build workflows with n8n that integrate LLMs, APIs, and business logic
- Connect Google services (Gmail, Calendar, Docs, Sheets) to your agents
- Understand the value proposition of open-source vs. cloud solutions

### Why Open Source?

**Key Benefits:**
- **Cost Control**: Local processing vs. cloud API fees
- **Data Privacy**: Your data stays on your hardware  
- **No Limits**: Unlimited usage without per-token charges
- **Full Control**: Customize and extend without vendor lock-in

For detailed value proposition and cost analysis, see [Workshop Goals](./docs/GOALS.md).

---

## 🛠️ Tech Stack

| Tool | Purpose | URL | Community |
|------|---------|-----|----------|
| **Docker/Podman** | Container platform for easy deployment | [docker.com](https://www.docker.com/) / [podman.io](https://podman.io/) | [Docker Forums](https://forums.docker.com/), [Podman GitHub](https://github.com/containers/podman) |
| **Ollama** | Local LLM runtime for running open models like Llama, Mistral, and more | [ollama.ai](https://ollama.ai/) | [Ollama Discord](https://discord.com/invite/ollama), [GitHub](https://github.com/ollama/ollama) |
| **OpenWebUI** | Beautiful chat interface for interacting with your local LLMs | [openwebui.com](https://openwebui.com/) | [Discord](https://discord.gg/5y7SfRBdYD), [GitHub](https://github.com/open-webui/open-webui) |
| **n8n** | Visual workflow automation platform for building AI agents and workflows | [n8n.io](https://n8n.io/) | [Forum](https://community.n8n.io/), [Discord](https://discord.n8n.io/), [GitHub](https://github.com/n8n-io/n8n) |
| **PostgreSQL** | Open-source database for storing workflow data | [postgresql.org](https://www.postgresql.org/) | [Community](https://www.postgresql.org/community/) |

## 🧩 Key Components Explained

### Ollama
Ollama is an open-source framework that lets you run large language models (LLMs) locally on your laptop or desktop. It handles downloading, loading, and serving AI models through a simple API.

**Key Features:**
- Run 3-70B parameter models on consumer hardware
- Simple API compatible with OpenAI format
- Support for quantized models (smaller, faster)
- Model library with popular open models (Llama, Mistral, etc.)
- GPU acceleration for faster inference

### OpenWebUI
OpenWebUI provides a user-friendly interface for interacting with your local Ollama models, similar to ChatGPT but running entirely on your machine.

**Key Features:**
- Clean, modern chat interface
- Model switching and parameter controls
- Conversation history and organization
- File upload and processing
- Vision model support

### n8n
n8n is a workflow automation platform that connects APIs, databases, and services. In this workshop, we use it to build AI agents by connecting Ollama's language capabilities with external systems.

**Key Features:**
- Visual workflow builder (no-code/low-code)
- 350+ pre-built integrations
- LangChain nodes for AI workflows
- Webhook triggers and scheduling
- Error handling and conditional logic

### How They Work Together

1. **Ollama** serves AI models through its API (port 11434)
2. **n8n** connects to Ollama API to use models in workflows
3. **OpenWebUI** provides a chat interface to the same models
4. **PostgreSQL** stores data for workflows and applications

This architecture gives you both visual interaction (OpenWebUI) and programmable automation (n8n) with the same underlying models, all running locally for privacy and cost control.

---

## 📋 Prerequisites

### Recommended Specifications
- **OS**: Windows 10/11 with WSL2 enabled, or macOS 12.0+ (Monterey)
- **RAM**: 16GB+ (8GB minimum)
- **Storage**: 20GB free disk space
- **CPU**: 4+ cores
- **GPU**: Optional (NVIDIA for Windows, Apple Silicon/Metal for macOS)
- **Internet**: Required for initial setup
- **Skills**: Basic familiarity with command line
- **Account**: Google account for API integration demos

---

## 🚀 Getting Started

### What You'll Get

After setup, you'll have a complete AI agent development environment with:

- **Ollama** running on [http://localhost:11434](http://localhost:11434) - API endpoint for LLM access
- **OpenWebUI** available at [http://localhost:3000](http://localhost:3000) - Chat interface for testing models
- **n8n** accessible at [http://localhost:5678](http://localhost:5678) - Workflow automation platform
- **PostgreSQL** running on port 5432 - Database for your applications

### Quick Start for Experienced Users

```bash
# Clone repository
git clone https://github.com/demoh-forugh/agentic-2025.git
cd agentic-2025

# Windows PowerShell setup
.\scripts\setup-windows.ps1

# OR macOS setup
./scripts/setup-mac.sh

# Verify installation
http://localhost:3000  # OpenWebUI
http://localhost:5678  # n8n
http://localhost:11434 # Ollama API
```

### First-Time Setup (Follow in Order)

**Step 1:** Check if your system meets the requirements
- **[System Specs Summary](./docs/SPECS_SUMMARY.md)** - Quick hardware check (30 seconds)

**Step 2:** Install and run the workshop stack
- **[Quick Start Guide](./docs/QUICK_START.md)** - 15-minute automated setup
- OR **[Installation Guide](./docs/INSTALLATION.md)** - Detailed step-by-step instructions

**Step 3:** Import and test your first workflow
- **[Sample Workflows](./workflows/)** - 6 ready-to-import n8n workflows
- Start with `01-hello-world.json` to test Ollama integration

**Step 4 (Optional):** Enable Google API workflows
- **[Configuration Guide](./docs/CONFIGURATION.md)** - Google OAuth setup for Gmail, Calendar, Docs

### When You Need Help

- **[Troubleshooting Guide](./docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[n8n Credentials Setup](./docs/n8n/CREDENTIALS-SETUP-GUIDE.md)** - Detailed credential configuration reference

### Advanced Topics

- **[System Specs Reference](./docs/SYSTEM_SPECS.md)** - Detailed hardware information
- **[Database Queries](./docs/DATABASE_QUERIES.md)** - PostgreSQL examples for workflows
- **[Advanced Topics](./docs/ADVANCED.md)** - Production deployment and scaling

---

## 📁 Repository Structure

```
agentic-2025/
├── README.md                          # This file
├── docs/
│   ├── GOALS.md                      # Workshop goals and vision
│   ├── QUICK_START.md                # 15-minute quick start
│   ├── INSTALLATION.md               # Installation guide (Windows & macOS)
│   ├── CONFIGURATION.md              # Setup & configuration
│   ├── SYSTEM_SPECS.md               # Detailed system specifications
│   ├── SPECS_SUMMARY.md              # Quick spec comparison
│   ├── TROUBLESHOOTING.md            # Common issues
│   ├── ADVANCED.md                   # Advanced topics
│   ├── DATA_POLICY.md                # Data measurement policy
│   ├── DATABASE_QUERIES.md           # PostgreSQL query examples for n8n
│   └── n8n/
│       ├── CREDENTIALS-SETUP-GUIDE.md # How credential overwrites work (detailed)
│       ├── CREDS-OVERWRITE.md        # Credential overwrite reference
│       └── CONFIG.md                 # n8n configuration reference (vendor docs)
├── workflows/
│   ├── README.md                     # Workflow documentation
│   ├── 01-hello-world.json           # Basic n8n work flow
│   ├── 02-gmail-agent.json           # Email processing agent
│   ├── 03-calendar-assistant.json    # Calendar management
│   ├── 04-document-processor.json    # Google Docs automation
│   ├── 05-customer-service-db.json   # Customer service with PostgreSQL
│   └── 06-lead-scoring-crm.json      # AI lead scoring & CRM
├── configs/
│   ├── docker-compose.yml            # Docker stack definition
│   ├── docker-compose.gpu.yml        # GPU override (Windows)
│   ├── docker-compose.ollama-host.yml # Host Ollama override (macOS)
│   ├── n8n-credentials-overwrite.json # Pre-configured credentials (Ollama, PostgreSQL)
│   └── .env.example                  # Environment variables template
├── scripts/
│   ├── setup-windows.ps1             # Windows automated setup
│   ├── setup-mac.sh                  # macOS automated setup
│   ├── verify-windows.ps1            # Windows verification
│   ├── verify-mac.sh                 # macOS verification
│   ├── measure-cold-warm-windows.ps1 # Windows performance measurement
│   └── measure-cold-warm-mac.sh      # macOS performance measurement
└── examples/
    ├── init-db.sql                   # PostgreSQL sample data
    ├── test-ollama-api.ps1           # API testing script
    └── sample-data.json              # Sample data for workflows
```

---

## 🎓 Workshop Agenda

**Duration**: 1 hour hands-on session  
**Format**: 4 parts (Setup → Build → Integrate → Scale)

For detailed agenda and learning objectives, see [Workshop Goals](./docs/GOALS.md).

---

## 💡 Example Use Cases

- **Email Triage Agent**: Automatically categorize and summarize incoming emails
- **Meeting Scheduler**: AI-powered calendar management with conflict resolution
- **Document Generator**: Create reports from structured data sources
- **Customer Service Automation**: AI ticket analysis with PostgreSQL database integration
- **Lead Scoring & CRM**: Intelligent lead qualification with automatic sales team alerts
- **Custom Chatbot**: Build domain-specific assistants with RAG (Retrieval Augmented Generation)

---

## 🔗 Useful Links & Resources

### n8n Resources
- [n8n Documentation](https://docs.n8n.io/) - Official documentation
- [n8n Academy](https://academy.n8n.io/) - Free tutorials and courses
- [n8n Community Nodes](https://n8n.io/community-nodes/) - Extensions and integrations
- [n8n Templates](https://n8n.io/workflows/) - Ready-to-use workflow templates

### Ollama Resources
- [Ollama Model Library](https://ollama.ai/library) - Browse available models
- [Ollama Documentation](https://github.com/ollama/ollama/blob/main/docs/README.md) - Setup and configuration guides
- [Ollama API Reference](https://github.com/ollama/ollama/blob/main/docs/api.md) - API documentation
- [Ollama Model Files](https://github.com/ollama/ollama/blob/main/docs/modelfile.md) - Create custom models

### OpenWebUI Resources
- [OpenWebUI Documentation](https://docs.openwebui.com/) - Official documentation
- [OpenWebUI Features](https://docs.openwebui.com/features/) - Feature overview
- [OpenWebUI GitHub](https://github.com/open-webui/open-webui) - Source code and issues

### Workshop Resources
- [Go to Agentic Conference](https://www.gotoagentic.ai/) - Conference information

---

## 🤝 Support & Troubleshooting

### During the Workshop
- Raise your hand for in-person assistance
- Use the workshop chat for quick questions
- Reference the [Troubleshooting Guide](./docs/TROUBLESHOOTING.md) for common issues

### Common Issues & Solutions

**Ollama not starting?**
- Check GPU drivers are up to date
- Ensure Docker/Podman has enough resources allocated
- Try `docker logs ollama` or `podman logs ollama` to see errors

**n8n workflow errors?**
- Verify Ollama credentials are correctly configured
- Check model is downloaded (`ollama list`)
- Test API directly with the provided test scripts

**OpenWebUI connection issues?**
- Ensure Ollama is running first
- Check browser console for network errors
- Verify port 3000 is not in use by another application

### After the Workshop
- **GitHub Issues**: File bugs or questions in this repository
- **Email**: workshop-support@example.com

---

## 📝 License & Disclaimer

Workshop materials are provided under Apache License 2.0. Feel free to use, modify, and share! 
(How awful would it be if a workshop on open source didn't share their materials?)

**Friendly Disclaimer:** This software is provided "as is" without warranty of any kind. While we've tested it extensively on our Mac and Windows systems, your mileage may vary. Think of it like a recipe shared by a friend — it worked in their kitchen, but your oven might have different ideas.

We genuinely hope this workshop stack runs smoothly for you and enhances your learning experience. However, we can't guarantee it will perform flawlessly in every environment. Use at your own risk!

---

## 🙏 Acknowledgments

Thank you for attending our workshop! We're excited to help you start your journey with open-source AI agents.

**Happy Building! 🚀**
