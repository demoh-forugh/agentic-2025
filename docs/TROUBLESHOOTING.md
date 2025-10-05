# Troubleshooting Guide

Common issues and solutions for the workshop stack.

---

## 🐳 Docker Issues

### Docker Desktop won't start

**Symptoms**: Docker Desktop shows "Starting..." indefinitely or fails to start

**Solutions**:

1. **Check WSL2 installation**:
```powershell
wsl --status
wsl --list --verbose
```
Ensure WSL2 is installed and set as default.

2. **Update WSL2**:
```powershell
wsl --update
```

3. **Enable Virtualization in BIOS**:
- Restart computer
- Enter BIOS/UEFI settings
- Enable Intel VT-x or AMD-V
- Save and exit

4. **Restart Docker Service**:
```powershell
# Stop Docker
Stop-Service docker

# Start Docker
Start-Service docker
```

5. **Reset Docker Desktop**:
- Open Docker Desktop
- Settings → Trouble → Reset to factory defaults

---

### Containers fail to start

**Symptoms**: `docker-compose up -d` fails or containers exit immediately

**Check logs**:
```powershell
# View all container logs
docker-compose logs

# View specific container
docker-compose logs ollama
docker-compose logs n8n
docker-compose logs open-webui
```

**Common causes**:

1. **Port conflicts**:
```powershell
# Check what's using port 5678
netstat -ano | findstr :5678

# Kill process if needed
taskkill /PID <process_id> /F
```

Alternative: Change ports in `docker-compose.yml`:
```yaml
ports:
  - "5679:5678"  # Use 5679 instead of 5678
```

2. **Insufficient resources**:
- Open Docker Desktop
- Settings → Resources
- Increase Memory to at least 8GB
- Increase CPU to at least 2 cores

3. **Volume permission issues**:
```powershell
# Remove old volumes and recreate
docker-compose down -v
docker-compose up -d
```

---

## 🤖 Ollama Issues

### Ollama API not accessible

**Test connection**:
```powershell
# From host machine
curl http://localhost:11434/api/tags

# From inside n8n container
docker exec -it n8n curl http://ollama:11434/api/tags
```

**Solutions**:

1. **Check Ollama is running**:
```powershell
docker ps | findstr ollama
```

2. **Restart Ollama**:
```powershell
docker-compose restart ollama
```

3. **Check network connectivity**:
```powershell
docker network ls
docker network inspect demos_ai-network
```

---

### Model download fails

**Symptoms**: `ollama pull` hangs or fails

**Solutions**:

1. **Check internet connection**:
```powershell
docker exec -it ollama ping -c 3 ollama.ai
```

2. **Check disk space**:
```powershell
docker exec -it ollama df -h
```

3. **Try smaller model first**:
```powershell
# Instead of llama3.2 (4GB), try:
docker exec -it ollama ollama pull llama3.2:1b  # Only 1GB
```

4. **Manual download with progress**:
```powershell
docker exec -it ollama ollama pull llama3.2 --verbose
```

5. **Clear cache and retry**:
```powershell
docker exec -it ollama ollama rm llama3.2
docker exec -it ollama ollama pull llama3.2
```

---

### Model runs slowly or crashes

**Symptoms**: Responses take forever or Ollama container restarts

**Solutions**:

1. **Check memory usage**:
```powershell
docker stats ollama
```

2. **Use smaller model**:
- `llama3.2:1b` - 1GB RAM
- `llama3.2` - 4GB RAM
- `llama3.2:70b` - 40GB RAM (avoid unless you have powerful hardware)

3. **Adjust model parameters in n8n**:
- Lower `num_ctx` (context window)
- Set `num_gpu` to 0 if GPU causing issues
- Reduce `num_thread`

4. **Allocate more memory to Docker**:
- Docker Desktop → Settings → Resources
- Increase Memory Limit

---

## 🌐 OpenWebUI Issues

### Can't access OpenWebUI at localhost:3000

**Solutions**:

1. **Check container status**:
```powershell
docker ps | findstr open-webui
docker-compose logs open-webui
```

2. **Verify port mapping**:
```powershell
netstat -ano | findstr :3000
```

3. **Try different browser**:
- Clear browser cache
- Try incognito/private mode
- Try different browser

4. **Check if port is changed**:
Look at your `docker-compose.yml`:
```yaml
ports:
  - "3000:8080"  # External:Internal
```
The first number is what you use in browser.

---

### OpenWebUI can't connect to Ollama

**Symptoms**: No models appear in dropdown or errors when chatting

**Solutions**:

1. **Check OLLAMA_BASE_URL environment variable**:
```yaml
# In docker-compose.yml
environment:
  - OLLAMA_BASE_URL=http://ollama:11434  # Must be container name
```

2. **Restart OpenWebUI after Ollama is ready**:
```powershell
docker-compose restart open-webui
```

3. **Check from inside container**:
```powershell
docker exec -it open-webui curl http://ollama:11434/api/tags
```

---

## 🔧 n8n Issues

### Can't access n8n at localhost:5678

**Solutions**:

1. **Check container and logs**:
```powershell
docker ps | findstr n8n
docker-compose logs n8n
```

2. **Common startup errors**:

**Error: "Port 5678 is already allocated"**
- Change port in docker-compose.yml
- Or stop conflicting service

**Error: "Permission denied"**
- Check volume permissions
- Run: `docker-compose down -v && docker-compose up -d`

---

### Workflows fail to execute

**1. Ollama node fails**

**Error**: "Connection refused" or "ECONNREFUSED"

**Solution**:
- In Ollama node credentials, use:
  - **Inside Docker**: `http://ollama:11434`
  - **Outside Docker**: `http://localhost:11434`

**2. HTTP Request timeout**

**Solution**:
- Increase timeout in node options
- Check if external service is reachable

**3. Expression error**

**Error**: "Cannot read property 'X' of undefined"

**Solution**:
- Use optional chaining: `$json.data?.property`
- Check if previous node returned data
- Add IF node to validate data exists

---

### Credentials don't work

**Google OAuth2 issues**:

**Error**: "Redirect URI mismatch"
- Must be exactly: `http://localhost:5678/rest/oauth2-credential/callback`
- No trailing slash
- Check port matches n8n port

**Error**: "Access blocked: Authorization Error"
- Add your email as test user in Google Cloud Console
- OAuth Consent Screen → Test Users → Add Users

**Error**: "Invalid credentials"
- Copy Client ID and Secret carefully (no spaces)
- Generate new credentials if needed

**Token expires**:
- Re-authenticate: Credentials → Edit → "Connect my account"
- For production: Publish OAuth app (not just testing mode)

---

## 📧 Google API Issues

### API not enabled

**Error**: "Google Calendar API has not been used in project..."

**Solution**:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. APIs & Services → Library
4. Search for and enable the API

### Quota exceeded

**Error**: "Quota exceeded for quota metric..."

**Solution**:
1. Check current usage:
   - Google Cloud Console → APIs & Services → Dashboard
2. Request quota increase (if needed)
3. For workshop: Reduce frequency of scheduled workflows

### Permission denied

**Error**: "Insufficient Permission: Request had insufficient authentication scopes"

**Solution**:
1. Check scopes in OAuth consent screen
2. Re-authenticate in n8n with new scopes
3. Required scopes:
   - Gmail: `https://www.googleapis.com/auth/gmail.readonly`
   - Calendar: `https://www.googleapis.com/auth/calendar`
   - Docs: `https://www.googleapis.com/auth/documents`
   - Sheets: `https://www.googleapis.com/auth/spreadsheets`

---

## 💾 Storage Issues

### Running out of disk space

**Check Docker disk usage**:
```powershell
docker system df
```

**Clean up**:
```powershell
# Remove unused containers
docker container prune

# Remove unused images
docker image prune -a

# Remove unused volumes (WARNING: This deletes data)
docker volume prune

# Nuclear option: Clean everything
docker system prune -a --volumes
```

**Large Ollama models**:
```powershell
# List models and their sizes
docker exec -it ollama ollama list

# Remove unused models
docker exec -it ollama ollama rm model-name
```

---

## 🚀 Performance Issues

### Everything is slow

**1. Check system resources**:
```powershell
# Docker stats
docker stats

# Windows Task Manager
Ctrl + Shift + Esc
```

**2. Optimize Docker**:
- Docker Desktop → Settings → Resources
- Increase Memory and CPU
- Enable WSL2 integration

**3. Use lighter models**:
- `llama3.2:1b` instead of `llama3.2`
- Reduce context window in model settings

**4. Limit concurrent executions**:
- n8n Settings → Executions
- Reduce "Max executions" running simultaneously

---

## 🔒 Security Warnings

### "Your connection is not private"

**If using HTTPS locally**:

This is normal for self-signed certificates. For workshop:
- Click "Advanced" → "Proceed to localhost (unsafe)"

For production:
- Use proper SSL certificate (Let's Encrypt)
- Configure reverse proxy (nginx, Caddy)

---

## 🆘 Getting Help

### Check Logs

**All services**:
```powershell
docker-compose logs -f
```

**Specific service**:
```powershell
docker-compose logs -f n8n
docker-compose logs -f ollama --tail=50
```

### Restart Everything

```powershell
# Stop
docker-compose down

# Start fresh
docker-compose up -d

# Follow logs
docker-compose logs -f
```

### Complete Reset

**WARNING: This deletes all data**

```powershell
# Stop and remove everything
docker-compose down -v

# Remove all workshop containers
docker rm -f ollama open-webui n8n

# Remove volumes
docker volume rm demos_ollama_data demos_n8n_data demos_open_webui_data

# Start fresh
docker-compose up -d
```

---

## ℹ️ Support Resources

This is provided as-is. No warranty is expressed or implied. But I hope it works for you!

### Community Resources
- [n8n Community](https://community.n8n.io/)
- [Ollama Community](https://discord.gg/ollama)
- [OpenWebUI GitHub](https://github.com/open-webui/open-webui)

### Official Documentation
- [n8n Docs](https://docs.n8n.io/)
- [Ollama Docs](https://ollama.ai/docs)
- [Docker Docs](https://docs.docker.com/)

### Community Forums
- [n8n Community](https://community.n8n.io/)
- [Ollama Discord](https://discord.gg/ollama)
- [Stack Overflow](https://stackoverflow.com/) - Tag: n8n, ollama

---

## 📋 Diagnostic Commands

Run these to gather information for support:

```powershell
# System info
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"

# Docker version
docker --version
docker-compose --version

# Container status
docker ps -a

# Network info
docker network ls
docker network inspect demos_ai-network

# Volume info
docker volume ls
docker volume inspect demos_ollama_data

# Memory usage
docker stats --no-stream

# Port usage
netstat -ano | findstr :5678
netstat -ano | findstr :3000
netstat -ano | findstr :11434
```

---

**Still stuck? Don't hesitate to ask for help during the workshop! 🙋**
