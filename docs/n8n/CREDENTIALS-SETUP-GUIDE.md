# n8n Credentials Setup Guide

## Workshop Implementation

This guide documents how credential overwrites are configured for the "Building Agents with n8n" workshop.

## ⚠️ Critical Understanding

**CREDENTIALS_OVERWRITE_DATA does NOT automatically create credentials.**

### What It Actually Does
- ✅ Pre-fills credential field values when users create new credentials
- ✅ Makes overwritten fields read-only (users can't change them)
- ✅ Simplifies OAuth flows ("click to connect" without entering secrets)

### What It Doesn't Do
- ❌ Does not automatically create credential entries in n8n
- ❌ Does not automatically assign credentials to imported workflows
- ❌ Workflows with credential references will still prompt for credential selection

### User Experience
1. User imports a workflow → n8n prompts to create/select credentials
2. User clicks "Create New Credential" → baseUrl and connection details are pre-filled
3. User saves credential → workflow can now use it
4. Future workflows automatically see the created credential

---

## Credential Type Reference

### Ollama API

**Credential Type:** `ollamaApi`
**Source:** [n8n/packages/@n8n/nodes-langchain/credentials/OllamaApi.credentials.ts](https://github.com/n8n-io/n8n/blob/master/packages/@n8n/nodes-langchain/credentials/OllamaApi.credentials.ts)

**Properties:**
| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `baseUrl` | string | Yes | `http://localhost:11434` | Base URL of Ollama instance |
| `apiKey` | string | No | `""` | Bearer token for authenticated proxies (e.g., Open WebUI) |

**Workshop Configuration:**
```json
{
  "ollamaApi": {
    "baseUrl": "http://ollama:11434"
  }
}
```

**Why `http://ollama:11434`?**
- Docker Compose service name is `ollama`
- Containers communicate using service names as hostnames on shared bridge network (`ai-network`)
- Using `localhost:11434` would fail because localhost refers to the n8n container itself

### PostgreSQL

**Credential Type:** `postgres`
**Source:** [n8n/packages/nodes-base/credentials/Postgres.credentials.ts](https://github.com/n8n-io/n8n/blob/master/packages/nodes-base/credentials/Postgres.credentials.ts)

**Properties:**
| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `host` | string | `localhost` | Database host |
| `database` | string | `postgres` | Database name |
| `user` | string | `postgres` | Database user |
| `password` | string | `""` | Database password |
| `port` | number | `5432` | Database port |
| `ssl` | string | `disable` | SSL mode: `disable`, `allow`, `require` |

**Workshop Configuration:**
```json
{
  "postgres": {
    "host": "postgres",
    "port": 5432,
    "database": "workshop_db",
    "user": "workshop",
    "password": "workshop_password",
    "ssl": "disable"
  }
}
```

---

## Implementation Methods

### Method 1: File-Based (✅ Recommended - Workshop Uses This)

**Create credentials file:** `configs/n8n-credentials-overwrite.json`
```json
{
  "ollamaApi": {
    "baseUrl": "http://ollama:11434"
  },
  "postgres": {
    "host": "postgres",
    "port": 5432,
    "database": "workshop_db",
    "user": "workshop",
    "password": "workshop_password",
    "ssl": "disable"
  }
}
```

**Configure docker-compose.yml:**
```yaml
n8n:
  environment:
    - CREDENTIALS_OVERWRITE_DATA_FILE=/data/credentials-overwrite.json
  volumes:
    - ./configs/n8n-credentials-overwrite.json:/data/credentials-overwrite.json:ro
```

**Benefits:**
- ✅ No JSON escaping issues in YAML
- ✅ Easier to read, edit, and maintain
- ✅ Can be version controlled separately
- ✅ Works reliably across all Docker Compose versions
- ✅ Clear separation of configuration from orchestration

### Method 2: Inline Environment Variable (❌ Not Recommended)

```yaml
environment:
  - CREDENTIALS_OVERWRITE_DATA={"ollamaApi":{"baseUrl":"http://ollama:11434"},"postgres":{"host":"postgres","port":5432,"database":"workshop_db","user":"workshop","password":"workshop_password","ssl":"disable"}}
```

**Issues:**
- ❌ YAML quoting/escaping can be problematic
- ❌ Hard to read and maintain
- ❌ May behave differently across shells/environments
- ❌ Difficult to debug when it doesn't work

### Method 3: API Endpoint (Enterprise Use Case)

```yaml
environment:
  - CREDENTIALS_OVERWRITE_ENDPOINT=https://api.example.com/credentials
```

**Use Cases:**
- Dynamic credential management
- Integration with secrets management systems (Vault, AWS Secrets Manager)
- Enterprise deployments with centralized credential control

---

## Workflow JSON Configuration

### Problem: Hardcoded Credential References

Workflows exported from n8n include credential references:

```json
{
  "credentials": {
    "ollamaApi": {
      "id": "MKTYlo9FdK8dPDik",
      "name": "Ollama Local"
    }
  }
}
```

**Issue:** When users import workflows, these credential IDs don't exist in their n8n instance.

### Solution: Remove Credential References

**Workshop workflows do NOT include credential references:**

```json
{
  "name": "Ollama Chat Model",
  "type": "@n8n/n8n-nodes-langchain.lmChatOllama",
  "parameters": {
    "model": "llama3.2:1b"
  }
}
```

**Why:**
- ✅ n8n prompts users to select/create credentials on first execution
- ✅ CREDENTIALS_OVERWRITE_DATA pre-fills the correct values
- ✅ Users save once, all workflows use the same credential
- ✅ No confusion about missing credential IDs

---

## Testing Credential Overwrites

### Verify Configuration is Active

1. Start n8n with docker-compose
2. Access n8n at http://localhost:5678
3. Create a new workflow
4. Add an Ollama Chat Model node
5. Click "Credential to connect with" → "Create New Credential"
6. **Expected:** Base URL field shows `http://ollama:11434` and is read-only
7. Save the credential

### Troubleshooting

#### Credential fields show default values (localhost:11434)

**Possible causes:**
1. Environment variable not set correctly
2. JSON file path incorrect or file not mounted
3. JSON syntax error in credentials file
4. n8n container needs restart after config changes

**Solutions:**
```bash
# Check environment variables inside container
docker exec -it n8n env | grep CREDENTIALS

# Verify file is mounted
docker exec -it n8n ls -la /data/credentials-overwrite.json

# Validate JSON syntax
docker exec -it n8n cat /data/credentials-overwrite.json | jq .

# Restart n8n
docker-compose restart n8n
```

#### Workflow asks for credentials after import

**This is expected behavior!** CREDENTIALS_OVERWRITE_DATA doesn't create credentials automatically.

**Solution:** Users need to create credentials once:
1. Import workflow
2. Click node showing credential warning
3. Click "Create New Credential"
4. Values are pre-filled → just click Save
5. All future workflows will see this credential

---

## Security Considerations

### Environment Variable Exposure

⚠️ **Warning:** Environment variables are visible to n8n users who have access to workflows.

**Mitigations:**
- Use `CREDENTIALS_OVERWRITE_ENDPOINT` for sensitive production credentials
- Limit n8n user access appropriately
- For workshops/local setups, environment variables are acceptable

### Workshop Context

- Workshop runs locally on users' machines
- Database password is `workshop_password` (non-sensitive demo data)
- Ollama has no authentication (local service)
- Users have full control of their Docker environment
- **Conclusion:** File-based credential overwrites are appropriate for this use case

---

## Best Practices

### Do's ✅
- Use `CREDENTIALS_OVERWRITE_DATA_FILE` for static configurations
- Remove credential references from shared workflow JSON files
- Document the one-time credential creation step for users
- Use Docker service names (`ollama`, `postgres`) not `localhost`
- Test credential overwrites work before workshop

### Don'ts ❌
- Don't use inline `CREDENTIALS_OVERWRITE_DATA` in production
- Don't hardcode credential IDs in workflow JSON files
- Don't expect credentials to be automatically created
- Don't use `localhost` for services in Docker Compose networks
- Don't forget to mount the credentials JSON file as a volume

---

## References

- [n8n Credentials Environment Variables](https://docs.n8n.io/hosting/configuration/environment-variables/credentials/)
- [n8n OllamaApi Credentials Source](https://github.com/n8n-io/n8n/blob/master/packages/@n8n/nodes-langchain/credentials/OllamaApi.credentials.ts)
- [n8n Postgres Credentials Source](https://github.com/n8n-io/n8n/blob/master/packages/nodes-base/credentials/Postgres.credentials.ts)
- [n8n Self-Hosted AI Starter Kit](https://github.com/n8n-io/self-hosted-ai-starter-kit)
- [Docker Compose Environment Variables](https://docs.docker.com/compose/how-tos/environment-variables/)
