# Configuration Guide
## Google API & Service Setup

This guide shows you how to configure Google API access for Gmail, Calendar, Docs, and Sheets integration with your n8n workflows.

---

## 🎯 Overview

To build agents that interact with Google services, you'll need:
1. A Google Cloud project
2. Enabled APIs (Gmail, Calendar, Docs, Sheets)
3. OAuth2 credentials
4. Configured credentials in n8n

**Time Required**: ~15 minutes

---

## Step 1: Create Google Cloud Project

### 1.1 Access Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Sign in with your Google account
3. Accept terms if this is your first time

### 1.2 Create a New Project

1. Click the project dropdown (top left, next to "Google Cloud")
2. Click **"New Project"**
3. Enter project details:
   - **Project Name**: `n8n-Workshop-Agents`
   - **Organization**: Leave as "No organization" (or select your org)
4. Click **"Create"**
5. Wait for project creation (~30 seconds)
6. Select your new project from the dropdown

---

## Step 2: Enable Required APIs

### 2.1 Navigate to APIs & Services

1. Open the hamburger menu (≡) → **"APIs & Services"** → **"Library"**
2. You'll see the API Library with thousands of APIs

### 2.2 Enable Each API

For each API below, follow these steps:
1. Search for the API name
2. Click on it
3. Click **"Enable"**
4. Wait for activation

**APIs to Enable:**

#### ✉️ Gmail API
- **Name**: Gmail API
- **Purpose**: Read, send, and manage emails
- **Search term**: "Gmail API"

#### 📅 Google Calendar API
- **Name**: Google Calendar API
- **Purpose**: Create and manage calendar events
- **Search term**: "Google Calendar API"

#### 📄 Google Docs API
- **Name**: Google Docs API
- **Purpose**: Create and edit documents
- **Search term**: "Google Docs API"

#### 📊 Google Sheets API
- **Name**: Google Sheets API
- **Purpose**: Read and write spreadsheet data
- **Search term**: "Google Sheets API"

---

## Step 3: Create OAuth2 Credentials

### 3.1 Configure OAuth Consent Screen

2. Choose user type:
   - Select **"External"** (for personal/workshop use)
   - Click **"Create"**

3. Fill in App Information:
   - **App name**: `n8n Workshop App`
   - **User support email**: Select your n8n admin email
   - **Developer contact**: Your email
   - Click **"Save and Continue"**

4. Scopes (Step 2):
   - Click **"Add or Remove Scopes"**
{{ ... }}

1. Go to **"APIs & Services"** → **"Credentials"**
2. Click **"+ Create Credentials"** → **"OAuth client ID"**
3. Configure:
   - **Application type**: Web application
   - **Name**: `n8n OAuth Client`
   - **Authorized redirect URIs**: Click **"+ Add URI"**
     - Add: `http://localhost:5678/rest/oauth2-credential/callback`
4. Click **"Create"**

### 3.3 Save Your Credentials
{{ ... }}
2. Log in if needed

### 4.2 Add Google OAuth2 Credentials

1. Click your user icon (bottom left) → **"Settings"** → **"Credentials"**
  1. In n8n, go to **Credentials** (left sidebar)
2. Click **"+ Add Credential"**
3. Search for and select **"Google OAuth2 API"**

4. Fill in the form:
   - **Credential Name**: `Google Workshop Account`
{{ ... }}

## Step 5: Test the Connection

### 5.1 Create a Simple Test Workflow

1. In n8n, create a new workflow"**
2. Add a **"Manual Trigger"** node (already there by default)
3. Click **"+"** → Search for **"Gmail"**
4. Add **"Gmail"** node
5. Configure:
   - **Credential**: Select "Google Workshop Account"
{{ ... }}

---

## Troubleshooting

### "Redirect URI mismatch" error
- Ensure you added   - **Authorized JavaScript origins**: `http://localhost:5678` (n8n default)h2-credential/callback`
- No trailing slash, correct port

### "Access blocked: Authorization Error"
- Check that you added your email as a test user
- Verify all required scopes are enabled
{{ ... }}
### "Invalid credentials"
- Double-check Client ID and Secret (no extra spaces)
- Regenerate credentials if needed

### Connection expires
- Refresh tokens expire after 7 days if app is in testing mode
- Re-authenticate or publish the app (OAuth consent screen)

---

## 📚 Next Steps

Now that you're configured, try these:

1. **[Import Sample Workflows](../workflows/)** - Pre-built examples
2. **Build Your First Agent** - Follow the workshop exercises
3. **[Advanced Topics](./ADVANCED.md)** - Scaling and production tips

**Ready to automate?** Head to the [Sample Workflows](../workflows/) folder!
