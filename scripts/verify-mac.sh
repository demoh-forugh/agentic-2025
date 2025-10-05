#!/usr/bin/env bash
# n8n Workshop - Installation Verification Script (macOS)
# Version: 1.1.1
# Last Updated: 2025-10-05
# Workshop: Go to Agentic Conference 2025

set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }

info() { printf "\033[1;36m[info]\033[0m %s\n" "$*"; }
ok() { printf "\033[1;32m[ok]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[error]\033[0m %s\n" "$*"; }

echo "======================================================="
echo "   Installation Verification v1.1.1"
echo "======================================================="
echo ""

all_good=true
critical_failures=()
warnings=()

# Function to track failures
check() {
  local message="$1"
  local success="$2"
  local critical="${3:-false}"

  if [[ "$success" == "true" ]]; then
    ok "$message"
  else
    if [[ "$critical" == "true" ]]; then
      err "$message"
      critical_failures+=("$message")
    else
      warn "$message"
      warnings+=("$message")
    fi
    all_good=false
  fi
}

# Detect Docker Compose command
if have docker-compose; then
  COMPOSE=(docker-compose)
else
  COMPOSE=(docker compose)
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
cd "$ROOT_DIR"

# 1. Check Docker daemon (CRITICAL)
info "Checking Docker..."

if ! have docker; then
  check "Docker is NOT installed" false true
else
  check "Docker is installed: $(docker --version)" true
fi

if ! docker ps >/dev/null 2>&1; then
  check "Docker daemon is NOT running" false true
else
  check "Docker daemon is running" true
fi

# Additional Docker health check
if docker version --format '{{.Server.Version}}' >/dev/null 2>&1; then
  SERVER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
  check "Docker daemon is responsive (v$SERVER_VERSION)" true
else
  check "Docker daemon is not responding properly" false true
fi

# 2. Check containers
echo ""
info "Checking containers..."

running_containers=()
stopped_containers=()
missing_containers=()

for container_name in "${REQUIRED_CONTAINERS[@]}"; do
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container_name}$"; then
    check "Container '$container_name' is running" true
    running_containers+=("$container_name")
  else
    # Check if it exists but is stopped
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${container_name}$"; then
      check "Container '$container_name' exists but is NOT running" false true
      stopped_containers+=("$container_name")
    else
      if [[ "$container_name" == "ollama" ]]; then
        if curl -fsS http://localhost:11434/api/tags >/dev/null 2>&1; then
          check "Container 'ollama' not found, but host Ollama is reachable on http://localhost:11434" true
          continue
        else
          check "Container '$container_name' is NOT found" false true
        fi
      else
        check "Container '$container_name' is NOT found" false true
      fi
      missing_containers+=("$container_name")
    fi
  fi
done

{{ ... }}
# 3. Check ports and verify they're mapped to correct containers
echo ""
info "Checking ports..."

PORT_CHECKS=(
  "11434:Ollama:ollama"
  "3000:OpenWebUI:open-webui"
  "5678:n8n:n8n"
  "5432:PostgreSQL:postgres"
)

for entry in "${PORT_CHECKS[@]}"; do
  port=${entry%%:*}
  remainder=${entry#*:}
  service=${remainder%%:*}
  container=${remainder#*:}

  # Check if port is mapped in container
  if docker port "$container" "$port" >/dev/null 2>&1; then
    mapping=$(docker port "$container" "$port" 2>/dev/null)
    check "Port $port ($service) mapped correctly: $mapping" true
  else
    # Fall back to checking if port is listening
    if [[ "$container" == "ollama" ]] && curl -fsS http://localhost:11434/api/tags >/dev/null 2>&1; then
      check "Port $port ($service) reachable via host Ollama" true
    elif lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
      check "Port $port ($service) is listening (but may not be mapped to container)" false false
    else
      check "Port $port ($service) is NOT listening" false true
    fi
  fi
done

# 4. Check HTTP endpoints
echo ""
info "Checking HTTP endpoints..."

# Check Ollama API
if curl -fsS http://localhost:11434/api/tags >/dev/null 2>&1; then
  check "Ollama API is accessible" true

  # Check for models
  if have jq; then
    model_count=$(curl -fsS http://localhost:11434/api/tags 2>/dev/null | jq -r '.models | length' 2>/dev/null || echo "0")
    if [[ "$model_count" -gt 0 ]]; then
      echo "  -> Models available: $model_count"
      curl -fsS http://localhost:11434/api/tags 2>/dev/null | jq -r '.models[].name' 2>/dev/null | while read -r model; do
        echo "    • $model"
      done
    else
      echo ""
      warn "No models downloaded yet"
      echo "    Recommended models (see README.md):"
      echo "      • llama3.2:1b (1GB) - Fast, for testing"
      echo "      • llama3.2 (4GB) - Recommended for workshop"
      echo "      • mistral (4GB) - Good for coding"
      echo "    Download with: docker exec -it ollama ollama pull llama3.2"
      echo ""
    fi
  fi
else
  check "Ollama API is NOT accessible at http://localhost:11434" false true
fi

# Check n8n
if curl -fsS -o /dev/null -w '%{http_code}' http://localhost:5678 2>/dev/null | grep -qE '^(200|302)$'; then
  check "n8n web interface is accessible" true
else
  check "n8n web interface is NOT accessible at http://localhost:5678" false true
fi

# Check OpenWebUI
if curl -fsS -o /dev/null http://localhost:3000 2>/dev/null; then
  check "OpenWebUI is accessible" true
else
  check "OpenWebUI is NOT accessible at http://localhost:3000" false true
fi

# Check PostgreSQL (port check only, not HTTP)
if docker port postgres 5432 >/dev/null 2>&1; then
  pg_port=$(docker port postgres 5432 2>/dev/null)
  check "PostgreSQL port is mapped: $pg_port" true
else
  check "PostgreSQL port is NOT mapped" false false
fi

# 5. Check Docker network
echo ""
info "Checking Docker network..."

if docker network ls --filter "name=ai-network" --format '{{.Name}}' 2>/dev/null | grep -q '^ai-network$'; then
  check "Docker network 'ai-network' exists" true
else
  check "Docker network 'ai-network' does NOT exist" false false
fi

# 6. Check volumes
echo ""
info "Checking Docker volumes..."

VOLUMES=("ollama_data" "n8n_data" "open_webui_data" "postgres_data")

for volume in "${VOLUMES[@]}"; do
  if docker volume ls --format '{{.Name}}' 2>/dev/null | grep -q "^${volume}\$"; then
    check "Volume '$volume' exists" true
  else
    check "Volume '$volume' does NOT exist" false false
  fi
done

# 7. Check disk space
echo ""
info "Checking disk space..."

docker_df=$(docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}" 2>/dev/null || echo "Could not retrieve disk usage")
echo "$docker_df"

# 8. Container resource usage
echo ""
info "Checking container resource usage..."

docker_stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "Could not retrieve stats")
echo "$docker_stats"

# Summary with prioritized troubleshooting
echo ""
echo "======================================================="

if [[ "$all_good" == "true" ]]; then
  echo "   All checks passed! [OK]"
  echo "======================================================="
  echo ""
  echo "Your workshop environment is ready!"
  echo ""
  echo "[i] Access your services:"
  echo "  • OpenWebUI:  http://localhost:3000  (Chat with LLMs)"
  echo "  • n8n:        http://localhost:5678  (Build workflows)"
  echo "  • Ollama API: http://localhost:11434 (LLM API endpoint)"
  echo ""
  echo "[i] Next steps:"
  echo "  1. Configure Google API credentials (see docs/CONFIGURATION.md)"
  echo "  2. Import sample workflows from ./workflows/"
  echo "  3. Start building your agents!"
  echo ""
else
  echo "   Some checks failed [X]"
  echo "======================================================="
  echo ""

  # Prioritized troubleshooting based on what failed
  if [[ ${#critical_failures[@]} -gt 0 ]]; then
    echo "[!] CRITICAL ISSUES (fix these first):"
    echo ""

    # Priority 1: Docker daemon not running
    if printf '%s\n' "${critical_failures[@]}" | grep -q "Docker daemon"; then
      echo "1. Docker daemon is not running"
      echo "   -> Start Docker Desktop from Applications folder"
      echo "   -> Wait 30-60 seconds for Docker to fully initialize"
      echo "   -> Look for Docker whale icon in menu bar"
      echo "   -> If issues persist, restart your Mac"
      echo ""
    fi

    # Priority 2: Containers not running
    if [[ ${#stopped_containers[@]} -gt 0 ]]; then
      echo "2. Containers exist but are stopped: ${stopped_containers[*]}"
      echo "   -> Start them with: docker start ${stopped_containers[*]}"
      echo "   -> Or restart all services: docker-compose restart"
      echo ""
    fi

    if [[ ${#missing_containers[@]} -gt 0 ]]; then
      echo "2. Containers are missing: ${missing_containers[*]}"
      echo "   -> Run setup script: ./scripts/setup-mac.sh"
      echo "   -> Or manually start: docker-compose up -d"
      echo ""
    fi

    # Priority 3: Ports not accessible
    if printf '%s\n' "${critical_failures[@]}" | grep -q "Port.*NOT"; then
      echo "3. Some services are not accessible on their ports"
      echo "   -> Check for port conflicts:"
      echo "     lsof -iTCP:5678,3000,11434,5432 -sTCP:LISTEN"
      echo "   -> Check container logs:"
      echo "     docker-compose logs [service-name]"
      echo "   -> Restart containers: docker-compose restart"
      echo ""
    fi

    # Priority 4: HTTP endpoints failing
    if printf '%s\n' "${critical_failures[@]}" | grep -q "NOT accessible"; then
      echo "4. HTTP endpoints are not responding"
      echo "   -> Containers may still be initializing (wait 30s and retry)"
      echo "   -> Check container logs for errors:"
      echo "     docker-compose logs -f"
      echo "   -> Verify containers are healthy:"
      echo "     docker ps"
      echo ""
    fi
  fi

  if [[ ${#warnings[@]} -gt 0 ]]; then
    echo "[!] WARNINGS (non-critical):"
    echo ""
    for warning in "${warnings[@]}"; do
      echo "  • $warning"
    done
    echo ""
  fi

  echo "[i] Additional Help:"
  echo "  • Troubleshooting guide: docs/TROUBLESHOOTING.md"
  echo "  • Check logs: docker-compose logs -f"
  echo "  • View container status: docker-compose ps"
  echo "  • Restart services: docker-compose restart"
  echo ""

  exit 1
fi

echo "Need help? Check docs/TROUBLESHOOTING.md or run ./scripts/setup-mac.sh again."
echo ""
