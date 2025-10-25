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
   - **User support email**: Select your email
   - **Developer contact**: Your email
   - Click **"Save and Continue"**

4. Scopes (Step 2):
   - Click **"Add or Remove Scopes"**
   - Select these scopes:
     - `https://www.googleapis.com/auth/gmail.readonly`
     - `https://www.googleapis.com/auth/gmail.modify`
     - `https://www.googleapis.com/auth/calendar`
     - `https://www.googleapis.com/auth/documents`
     - `https://www.googleapis.com/auth/spreadsheets`
   - Click **"Update"**
   - Click **"Save and Continue"**

5. Test Users (Step 3):
   - Click **"+ Add Users"**
   - Enter your email address
   - Click **"Save and Continue"**

6. Summary (Step 4):
   - Review your settings
   - Click **"Back to Dashboard"**

### 3.2 Create OAuth2 Credentials

1. Go to **"APIs & Services"** → **"Credentials"**
2. Click **"+ Create Credentials"** → **"OAuth client ID"**
3. Configure:
   - **Application type**: Web application
   - **Name**: `n8n OAuth Client`
   - **Authorized redirect URIs**: Click **"+ Add URI"**
     - Add: `http://localhost:5678/rest/oauth2-credential/callback`
   - **Authorized JavaScript origins**: Click **"+ Add URI"**
     - Add: `http://localhost:5678`
4. Click **"Create"**

### 3.3 Save Your Credentials

**Important:** Copy these immediately - you won't see the secret again!

1. **Client ID**: Copy and save (looks like: `xxxxx.apps.googleusercontent.com`)
2. **Client Secret**: Copy and save (looks like: `GOCSPX-xxxxx`)
3. Click **"OK"**

---

## Step 4: Configure Credentials in n8n

### 4.1 Access n8n

1. Open http://localhost:5678
2. Log in if needed

### 4.2 Add Google OAuth2 Credentials

1. In n8n, go to **Settings** (left sidebar) → **"Credentials"**
2. Click **"+ Add Credential"**
3. Search for and select **"Google OAuth2 API"**

4. Fill in the form:
   - **Credential Name**: `Google Workshop Account`
   - **Client ID**: Paste your Client ID
   - **Client Secret**: Paste your Client Secret
   - **Scopes**: Leave as default
5. Click **"Connect my account"**
6. Sign in with Google
7. Grant all requested permissions
8. You should see "Successfully connected!"

---

## Step 5: Test the Connection

### 5.1 Create a Simple Test Workflow

1. In n8n, create a new workflow
2. Add a **"Manual Trigger"** node (already there by default)
3. Click **"+"** → Search for **"Gmail"**
4. Add **"Gmail"** node
5. Configure:
   - **Credential**: Select "Google Workshop Account"
   - **Resource**: Message
   - **Operation**: Get All
   - **Options**: Max Results = 5
6. Click **"Execute Node"**
7. You should see your recent emails! ✅

---

## Troubleshooting

### "Redirect URI mismatch" error
- Ensure you added `http://localhost:5678/rest/oauth2-credential/callback` exactly
- No trailing slash, correct port
- Check the port matches your n8n instance

### "Access blocked: Authorization Error"
- Check that you added your email as a test user in OAuth Consent Screen
- Verify all required scopes are enabled
- Make sure your Google account is verified

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
