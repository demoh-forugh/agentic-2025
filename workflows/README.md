# N8N Workflow Examples

This directory contains ready-to-import N8N workflows for the workshop.

---

## 📥 How to Import Workflows

### Method 1: Via N8N UI

1. Open N8N in your browser: http://localhost:5678
2. Click **"+ Add workflow"** (or open an existing workflow)
3. Click the **"..." menu** (top right) → **"Import from File"**
4. Select one of the JSON files from this directory
5. Click **"Import"**

### Method 2: Via File System (if using Docker volume mapping)

The workflows are automatically available if you've mapped the `./workflows` directory in your `docker-compose.yml`.

---

## 🎯 Available Workflows

### 01 - Hello World with Ollama
**File**: `01-hello-world.json`  
**Difficulty**: ⭐ Beginner  
**Duration**: 5 minutes

**What it does**:
- Simple introduction to N8N and Ollama integration
- Sends a prompt to your local LLM
- Formats and displays the response

**Setup required**:
- Ollama running with at least one model downloaded

**Try it**:
1. Import the workflow
2. Click "Execute Workflow"
3. See your LLM respond!

---

### 02 - Email Triage Agent
**File**: `02-gmail-agent.json`  
**Difficulty**: ⭐⭐ Intermediate  
**Duration**: 15 minutes

**What it does**:
- Checks for unread emails every 15 minutes
- Uses AI to analyze and categorize each email
- Stars urgent messages
- Logs all analyzed emails to a Google Sheet

**Setup required**:
- Gmail API enabled and configured
- Google Sheets API enabled
- Create a spreadsheet named "Email Log" with these columns:
  - Timestamp
  - From
  - Subject
  - Category
  - Priority
  - Summary
  - Action

**Customization tips**:
- Adjust the schedule trigger interval
- Modify AI prompt to match your categorization needs
- Add additional actions (e.g., auto-reply, create tasks)

---

### 03 - Smart Calendar Assistant
**File**: `03-calendar-assistant.json`  
**Difficulty**: ⭐⭐⭐ Advanced  
**Duration**: 20 minutes

**What it does**:
- Receives meeting requests via webhook
- Analyzes your calendar for the week
- Uses AI to suggest optimal meeting times
- Optionally auto-schedules meetings

**Setup required**:
- Google Calendar API enabled
- Webhook URL accessible (for testing, use N8N's test URL)

**How to test**:
1. Import and activate the workflow
2. Copy the webhook URL from the trigger node
3. Send a POST request:

```bash
curl -X POST http://localhost:5678/webhook/schedule-meeting \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Team Sync",
    "duration": 60,
    "attendees": "team@example.com",
    "preferences": "Morning preferred",
    "auto_schedule": false
  }'
```

**Response**:
- Suggested time slots
- AI reasoning for recommendations
- Conflict warnings

---

### 04 - AI Document Generator
**File**: `04-document-processor.json`  
**Difficulty**: ⭐⭐⭐ Advanced  
**Duration**: 20 minutes

**What it does**:
- Fetches data from a Google Sheet
- Uses AI to generate a professional report
- Creates a formatted Google Doc
- Sends notification when complete (optional)

**Setup required**:
- Google Sheets API enabled
- Google Docs API enabled
- Create a spreadsheet named "Workshop Data" with sample data

**Sample data format**:
| Month | Sales | Customers | Region |
|-------|-------|-----------|--------|
| Jan | 50000 | 120 | East |
| Feb | 55000 | 135 | East |
| Mar | 48000 | 110 | West |

**Customization tips**:
- Modify the AI prompt for different report styles
- Add charts and visualizations
- Connect to different data sources

---

## 🔧 Workflow Configuration

### Setting Up Credentials

Each workflow requires specific credentials. Here's what you'll need:

#### Ollama API
- **Type**: HTTP Request credentials (or Ollama-specific if available)
- **URL**: `http://ollama:11434` (inside Docker) or `http://localhost:11434` (outside)
- **No authentication required**

#### Google Services
- **Type**: OAuth2
- **Setup**: See [CONFIGURATION.md](../docs/CONFIGURATION.md)
- **Services**: Gmail, Calendar, Docs, Sheets

---

## 🎨 Customization Ideas

### Beginner Level
- Change AI model parameters (temperature, max tokens)
- Modify trigger schedules
- Adjust filter criteria (email labels, date ranges)

### Intermediate Level
- Add error handling and retry logic
- Implement notification systems (Slack, Discord, email)
- Create custom response formats

### Advanced Level
- Chain multiple workflows together
- Build RAG (Retrieval Augmented Generation) pipelines
- Implement multi-agent systems
- Add human-in-the-loop approvals

---

## 🐛 Troubleshooting

### Workflow won't execute
- Check that all required credentials are configured
- Verify all nodes have valid inputs
- Look at the execution logs (click on a node after execution)

### Ollama node fails
- Ensure Ollama is running: `docker ps | grep ollama`
- Check model is downloaded: `docker exec -it ollama ollama list`
- Verify network connectivity between N8N and Ollama

### Google API errors
- Confirm APIs are enabled in Google Cloud Console
- Re-authenticate if tokens expired
- Check quota limits in Google Cloud Console

### "No items" error
- Previous node returned empty results
- Add IF condition to check for data before processing
- Review filter conditions

---

## 📚 Learning Resources

### N8N Documentation
- [Official Docs](https://docs.n8n.io/)
- [Node Reference](https://docs.n8n.io/integrations/)
- [Community Forum](https://community.n8n.io/)

### Video Tutorials
- [N8N YouTube Channel](https://www.youtube.com/@n8n-io)
- Search: "N8N + Ollama tutorial"

### Example Workflows
- [N8N Workflow Templates](https://n8n.io/workflows)
- [Community Workflows](https://community.n8n.io/c/workflows/)

---

## 💡 Next Steps

1. **Import all workflows** to see how they work
2. **Run them manually** first to understand the flow
3. **Customize** one workflow to fit your specific needs
4. **Build your own** workflow combining multiple concepts
5. **Share** your creation with the community!

---

## 🤝 Contributing

Have an improvement or new workflow idea?
- Fork the repository
- Add your workflow with documentation
- Submit a pull request

---

**Happy Automating! 🚀**
