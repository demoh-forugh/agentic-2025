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

| Tool | Purpose |
|------|---------|
| **Docker** | Container platform for easy deployment |
| **Ollama** | Local LLM runtime (run models like Llama, Mistral, etc.) |
| **OpenWebUI** | Beautiful chat interface for LLMs |
| **N8N** | Visual workflow automation and agent orchestration |

---

## 📋 Prerequisites

### Recommended Specifications
- **OS**: Windows 10/11 with WSL2 enabled
- **RAM**: 16GB+ (8GB minimum)
- **Storage**: 20GB free disk space
- **CPU**: 4+ cores
- **GPU**: Optional (NVIDIA for acceleration)
- **Internet**: Required for initial setup
- **Skills**: Basic familiarity with command line
- **Account**: Google account for API integration demos

---

## 🚀 Quick Start

> **✨ NEW:** All setup scripts upgraded to v1.1.1 with improved error handling, health checks, and idempotency! Character encoding fixes ensure clean output on all platforms. See [archive/testing-v1.1.1](./archive/testing-v1.1.1/) for complete testing documentation.

1. **[Quick Start Guide](./docs/QUICK_START.md)** - Get running in 15 minutes
2. **[Installation Guide](./docs/INSTALLATION.md)** - Step-by-step setup instructions
3. **[Configuration Guide](./docs/CONFIGURATION.md)** - Google API and service setup
4. **[Sample Workflows](./workflows/)** - Ready-to-import n8n workflows
5. **[System Specs Reference](./docs/SYSTEM_SPECS.md)** - Detailed hardware information
6. **[Specs Summary](./docs/SPECS_SUMMARY.md)** - Quick spec comparison
7. **[Troubleshooting](./docs/TROUBLESHOOTING.md)** - Common issues and solutions

---

## 📁 Repository Structure

```
demos/
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
│   └── DATA_POLICY.md                # Data measurement policy
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

## 🔗 Useful Links

- [N8N Documentation](https://docs.n8n.io/)
- [Ollama Model Library](https://ollama.ai/library)
- [OpenWebUI GitHub](https://github.com/open-webui/open-webui)
- [Go to Agentic Conference](https://www.gotoagentic.ai/)

---

## 🤝 Support

- **Workshop Discord**: [Join here](#)
- **Issues**: File bugs or questions in this repository
- **Email**: dehmohforugh@gmail.com

---

## 📝 License

Workshop materials are provided under MIT License. Feel free to use, modify, and share!

---

## 🙏 Acknowledgments

Thank you for attending our workshop! We're excited to help you start your journey with open-source AI agents.

**Happy Building! 🚀**
