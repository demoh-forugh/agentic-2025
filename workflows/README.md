# n8n Workflow Examples

Ready-to-import, production-quality workflows demonstrating real business use cases with AI automation.

**All workflows are fully functional** - they'll work in your n8n instance after you configure the required credentials.

---

## 📥 Quick Start

### Import a Workflow

1. Open n8n: http://localhost:5678
2. Click **"..."** menu (top right) → **"Import from File"**
3. Select a workflow JSON file
4. Configure credentials (see setup sections below)
5. Click "Execute Workflow" to test

---

## 🎯 Workflow Catalog

### 01 - Hello World with Ollama ⭐
**File**: `01-hello-world.json`
**Use Case**: Basic LLM integration test
**Setup Time**: 2 minutes
**Business Value**: Learn the basics

**What it does:**
- Sends a test prompt to your local LLM
- Formats and displays the AI response
- Perfect for verifying Ollama is working

**Requirements:**
- ✅ Ollama running with any model downloaded

**How to use:**
1. Import workflow
2. Add Ollama credential: http://ollama:11434
3. Click "Execute Workflow"
4. See response in "Format Response" node

---

### 02 - Email Triage Agent ⭐⭐
**File**: `02-gmail-agent.json`
**Use Case**: Customer Service & Support (from GOALS.md)
**Setup Time**: 15 minutes
**Business Value**: 10-20 hours/week saved on email sorting

**What it does:**
- Checks Gmail every 15 minutes for unread emails
- AI analyzes each email for:
  - Category (urgent/important/normal/spam)
  - Priority (1-5)
  - One-sentence summary
  - Suggested action (reply/archive/flag/delete)
- Stars urgent emails automatically
- Logs all analysis to Google Sheets

**Requirements:**
- ✅ Gmail API enabled
- ✅ Google Sheets API enabled
- ✅ Ollama running with a model

**Setup Instructions:**

1. **Enable Google APIs** (see [CONFIGURATION.md](../docs/CONFIGURATION.md))
   - Gmail API
   - Google Sheets API

2. **Create Google Sheet**:
   - Name: "Email Log" (or update workflow)
   - Columns: Timestamp, From, Subject, Category, Priority, Summary, Action

3. **Configure n8n credentials**:
   - Add "Google" OAuth2 credential
   - Add "Ollama API" credential

4. **Activate workflow**:
   - Open workflow
   - Click "Active" toggle (top right)
   - Workflow will run every 15 minutes

**Customization:**
- Change schedule interval (Schedule Trigger node)
- Modify AI categorization logic (Ollama prompt)
- Add auto-reply for specific categories
- Integrate with ticket system

---

### 03 - Smart Calendar Assistant ⭐⭐⭐
**File**: `03-calendar-assistant.json`
**Use Case**: Operations & Productivity - Meeting Assistant (from GOALS.md)
**Setup Time**: 20 minutes
**Business Value**: 5-10 hours/week saved on scheduling

**What it does:**
- Receives meeting requests via webhook
- Fetches your week's calendar events
- AI analyzes schedule and suggests 3 best time slots
- Provides reasoning for each suggestion
- Optionally auto-schedules the meeting
- Returns JSON response with suggestions

**Requirements:**
- ✅ Google Calendar API enabled
- ✅ Ollama running with a model
- ✅ Webhook endpoint (n8n provides this)

**Setup Instructions:**

1. **Enable Google Calendar API** (see [CONFIGURATION.md](../docs/CONFIGURATION.md))

2. **Configure n8n credentials**:
   - Add "Google Calendar OAuth2" credential
   - Add "Ollama API" credential

3. **Get webhook URL**:
   - Import workflow
   - Click on "Webhook - Schedule Request" node
   - Copy "Production URL"

4. **Test with curl**:
```bash
curl -X POST https://your-n8n-instance/webhook/schedule-meeting \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Team Sync Meeting",
    "duration": 60,
    "attendees": "team@example.com",
    "preferences": "Morning preferred, avoid Mondays",
    "auto_schedule": false
  }'
```

**Response:**
```json
{
  "suggested_slots": [
    "2025-10-28T09:00:00Z",
    "2025-10-28T14:00:00Z",
    "2025-10-29T10:00:00Z"
  ],
  "reasoning": "Selected morning slots based on preferences...",
  "top_recommendation": "2025-10-28T09:00:00Z",
  "conflicts": "None"
}
```

**Integration:**
- Add to website contact form
- Connect to Slack bot
- Use in CRM workflows

---

### 04 - AI Document Generator ⭐⭐⭐
**File**: `04-document-processor.json`
**Use Case**: Operations - Report Generation (from GOALS.md)
**Setup Time**: 20 minutes
**Business Value**: 15-25 hours/month saved on reporting

**What it does:**
- Fetches data from Google Sheets
- Aggregates and analyzes the data
- AI generates a comprehensive business report with:
  - Executive Summary
  - Key Findings
  - Data Analysis
  - Trends and Patterns
  - Recommendations
  - Conclusion
- Creates formatted Google Doc
- Returns document link

**Requirements:**
- ✅ Google Sheets API enabled
- ✅ Google Docs API enabled
- ✅ Ollama running with a model

**Setup Instructions:**

1. **Enable Google APIs**:
   - Google Sheets API
   - Google Docs API

2. **Create sample spreadsheet**:
   - Name: "Workshop Data" (or update workflow)
   - Add sample data (sales, customers, metrics, etc.)
   - Example columns: Month, Sales, Customers, Region

3. **Configure n8n credentials**:
   - Add "Google Sheets OAuth2" credential
   - Add "Google Docs OAuth2" credential
   - Add "Ollama API" credential

4. **Run workflow**:
   - Click "Execute Workflow"
   - View generated document link in output

**Customization:**
- Change report format (prompt engineering)
- Add charts and visualizations
- Schedule to run monthly/weekly
- Email report to stakeholders

---

### 05 - Customer Service with Database ⭐⭐⭐ **NEW!**
**File**: `05-customer-service-db.json`
**Use Case**: Customer Service & Support + Database Integration (from GOALS.md)
**Setup Time**: 10 minutes
**Business Value**: Complete ticket management with AI assistance

**What it does:**
- Fetches open tickets from PostgreSQL database
- AI analyzes each ticket for:
  - Sentiment score (-1.0 to 1.0)
  - Category (technical, billing, feature_request, etc.)
  - Suggested priority
  - Key issues identified
  - Professional response template
  - Estimated resolution time
  - Escalation need
- Updates ticket in database with AI analysis
- Saves suggested response to database
- Emails manager for escalated tickets
- Generates summary statistics

**Requirements:**
- ✅ PostgreSQL running (included in docker-compose.yml)
- ✅ Database initialized with init-db.sql
- ✅ Gmail API enabled (for escalations)
- ✅ Ollama running with a model

**Setup Instructions:**

1. **PostgreSQL is already configured** from setup scripts!
   - Database: `workshop_db`
   - User: `workshop`
   - Password: from your `.env` file
   - Tables: `customer_tickets`, `customer_responses`

2. **Configure n8n credentials**:
   - Add "PostgreSQL" credential:
     - Host: `postgres` (Docker network) or `localhost`
     - Port: `5432`
     - Database: `workshop_db`
     - User: `workshop`
     - Password: (from your `.env`)
   - Add "Gmail OAuth2" credential (for escalations)
   - Add "Ollama API" credential

3. **Run workflow**:
   - Click "Execute Workflow"
   - View ticket analysis results
   - Check database for updated tickets

**Database Schema:**
```sql
customer_tickets (
  id, customer_email, subject, message,
  priority, status, category, sentiment_score,
  created_at, updated_at
)

customer_responses (
  id, ticket_id, response_text, response_type, created_at
)
```

**Value Proposition:**
- Automate first-pass ticket analysis
- Generate response templates
- Route urgent tickets to managers
- Track sentiment trends
- Reduce response time by 50-70%

---

### 06 - AI Lead Scoring & CRM ⭐⭐⭐ **NEW!**
**File**: `06-lead-scoring-crm.json`
**Use Case**: Sales & CRM - Lead Qualification (from GOALS.md)
**Setup Time**: 15 minutes
**Business Value**: 20-30 hours/week saved on lead qualification

**What it does:**
- Receives new lead data via webhook
- AI analyzes lead for:
  - Lead score (0-100)
  - Qualification status (hot/warm/cold/disqualified)
  - ICP (Ideal Customer Profile) match score
  - Urgency score (0-10)
  - Key positive indicators
  - Red flags
  - Recommended next steps
  - Suggested messaging angle
- Logs hot leads (≥70 score) to special Google Sheet
- Sends immediate alert to sales team for hot leads
- Logs all leads to master Google Sheet
- Returns JSON response with scoring details

**Requirements:**
- ✅ Google Sheets API enabled
- ✅ Gmail API enabled (for alerts)
- ✅ Ollama running with a model
- ✅ Webhook endpoint

**Setup Instructions:**

1. **Enable Google APIs**:
   - Google Sheets API
   - Gmail API

2. **Create Google Sheets**:
   - Sheet 1: "Hot Leads"
     - Columns: Name, Email, Company, Score, Status, Priority, Key Indicators, Actions, Messaging, Scored At
   - Sheet 2: "All Leads"
     - Columns: Name, Email, Company, Score, Status, ICP Match, Urgency, Scored At

3. **Configure n8n credentials**:
   - Add "Google Sheets OAuth2" credential
   - Add "Gmail OAuth2" credential
   - Add "Ollama API" credential

4. **Get webhook URL** and test:
   - Click "Webhook - New Lead" node
   - Copy "Production URL"

5. **Send test lead**:
```bash
curl -X POST https://your-n8n-instance/webhook/new-lead \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Smith",
    "email": "jane@techcorp.com",
    "company": "TechCorp Inc",
    "job_title": "VP of Engineering",
    "company_size": "500-1000",
    "industry": "Technology",
    "budget_range": "$50k-$100k/year",
    "timeline": "Q1 2026",
    "pain_points": "Manual workflows, scaling issues, data integration problems",
    "source": "conference"
  }'
```

**Response:**
```json
{
  "success": true,
  "lead_score": 85,
  "qualification_status": "hot",
  "assigned_priority": "p1_immediate",
  "is_hot_lead": true,
  "recommended_actions": [
    "Contact within 15 minutes",
    "Offer personalized demo",
    "Highlight automation capabilities"
  ],
  "message": "Lead successfully scored and logged. Sales team has been notified of this hot lead!"
}
```

**Integration Ideas:**
- Website contact form → webhook
- Trade show lead scanner → webhook
- LinkedIn form submissions → webhook
- CRM integration via Zapier/Make

**Value Proposition:**
- Qualify leads 24/7 automatically
- Never miss a hot lead
- Consistent scoring criteria
- Instant sales team alerts
- Track qualification metrics

---

## 🔧 Credential Setup Guide

### Ollama API

**In n8n:**
1. Go to **Settings** → **Credentials**
2. Click **"Add Credential"**
3. Search for **"Ollama"** or **"HTTP Request"**
4. Configure:
   - **Name**: Ollama Local
   - **Host**: http://ollama:11434 (inside Docker) or http://localhost:11434 (outside Docker)
   - **Authentication**: None

**Verify it works:**
```bash
curl http://localhost:11434/api/tags
```

---

### Google OAuth2 (Gmail, Calendar, Sheets, Docs)

**Full setup guide**: See [../docs/CONFIGURATION.md](../docs/CONFIGURATION.md)

**Quick steps:**
1. Create Google Cloud Project
2. Enable APIs:
   - Gmail API
   - Google Calendar API
   - Google Sheets API
   - Google Docs API
3. Create OAuth2 credentials
4. Add credentials in n8n:
   - Settings → Credentials → Add Credential
   - Select "Google"
   - Paste Client ID and Secret
   - Authorize with Google account

---

### PostgreSQL

**In n8n:**
1. Settings → Credentials → Add Credential
2. Search for "PostgreSQL"
3. Configure:
   - **Name**: Workshop PostgreSQL
   - **Host**: postgres (inside Docker) or localhost (outside Docker)
   - **Port**: 5432
   - **Database**: workshop_db
   - **User**: workshop
   - **Password**: (from your `.env` file, default: workshop_password)

**Verify connection:**
```sql
-- Test query
SELECT COUNT(*) FROM customer_tickets;
```

---

## 📊 Business Use Case Mapping

Our workflows cover key business use cases from [GOALS.md](../docs/GOALS.md):

| Workflow | Business Use Case | Time Saved | ROI |
|----------|------------------|------------|-----|
| 02 - Email Triage | Customer Service & Support | 10-20 hrs/week | High |
| 03 - Calendar Assistant | Operations & Productivity | 5-10 hrs/week | Medium |
| 04 - Document Generator | Operations & Productivity | 15-25 hrs/month | High |
| 05 - Customer Service DB | Customer Service & Support | 20-30 hrs/week | Very High |
| 06 - Lead Scoring | Sales & CRM | 20-30 hrs/week | Very High |

**Total potential time savings**: 50-85 hours/week across all workflows!

---

## 🎨 Customization & Extension Ideas

### Easy Modifications
- Change AI model (llama3.2, mistral, etc.)
- Adjust temperature for creativity (0.1-1.0)
- Modify schedule intervals
- Change filter criteria
- Update email recipients

### Intermediate Enhancements
- Add Slack/Discord notifications
- Implement error handling and retries
- Create custom response formats
- Add data validation
- Integrate with other APIs

### Advanced Projects
- Chain multiple workflows together
- Build RAG (Retrieval Augmented Generation) with vector database
- Create multi-agent systems
- Add human-in-the-loop approvals
- Implement A/B testing for AI prompts

---

## 🐛 Troubleshooting

### "Credentials not found" error
**Solution**: Configure credentials in n8n Settings → Credentials. Update credential IDs in workflow nodes.

### Ollama node fails
**Check:**
- Ollama container running: `docker ps | grep ollama`
- Model downloaded: `docker exec -it ollama ollama list`
- Network connectivity: `curl http://ollama:11434/api/tags`

### Google API errors
**Common issues:**
- APIs not enabled in Google Cloud Console
- OAuth tokens expired (re-authenticate)
- Quota limits exceeded (check console)
- Wrong credential scope (must include required APIs)

### "No items to process" error
**Cause**: Previous node returned empty results
**Solution**:
- Add IF condition to check for data
- Review filter conditions
- Check data source has content

### PostgreSQL connection fails
**Check:**
- PostgreSQL container running: `docker ps | grep postgres`
- Correct credentials in n8n
- Database initialized: `docker exec -it postgres psql -U workshop -d workshop_db -c "\dt"`

### Webhook not responding
**Check:**
- Workflow is activated (Active toggle on)
- Correct webhook URL (check node settings)
- Proper JSON format in request
- Check n8n execution log

---

## 💡 Best Practices

### Workflow Design
- ✅ Use descriptive node names
- ✅ Add comments explaining complex logic
- ✅ Test with small datasets first
- ✅ Implement error handling
- ✅ Log execution results

### AI Prompt Engineering
- ✅ Be specific about desired output format
- ✅ Use JSON mode for structured data
- ✅ Provide examples in prompt
- ✅ Set appropriate temperature
- ✅ Test with multiple scenarios

### Production Deployment
- ✅ Use environment variables for secrets
- ✅ Set up monitoring and alerts
- ✅ Implement rate limiting
- ✅ Add data validation
- ✅ Document for your team

---

## 📚 Additional Resources

### n8n Learning
- [Official Documentation](https://docs.n8n.io/)
- [Node Reference](https://docs.n8n.io/integrations/)
- [Community Forum](https://community.n8n.io/)
- [Workflow Templates](https://n8n.io/workflows)

### AI & LLMs
- [Ollama Documentation](https://ollama.ai/docs)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)
- [Model Library](https://ollama.ai/library)

### Workshop Materials
- [Quick Start Guide](../docs/QUICK_START.md)
- [Configuration Guide](../docs/CONFIGURATION.md)
- [Troubleshooting](../docs/TROUBLESHOOTING.md)
- [System Requirements](../docs/SYSTEM_SPECS.md)

---

## 🚀 Next Steps

1. **Start with Hello World** (01) to verify setup
2. **Try Email Triage** (02) for quick wins
3. **Explore Database workflow** (05) for full power
4. **Customize** a workflow for your specific needs
5. **Build** your own workflow from scratch
6. **Share** your creation with the community!

---

## 🤝 Community & Support

**Have questions?**
- Join [n8n Community](https://community.n8n.io/)
- Check [Troubleshooting Guide](../docs/TROUBLESHOOTING.md)
- Review [Workshop Documentation](../docs/)

**Want to contribute?**
- Add new workflows
- Improve existing ones
- Share your use cases
- Help others in discussions

---

**🎉 Happy Automating!**

*These workflows were created for the "Building Agents with n8n" workshop at Go to Agentic Conference 2025.*
