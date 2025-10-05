#!/usr/bin/env bash
# n8n Workshop - Automated Setup Script (macOS)
# Version: 1.1.1
# Last Updated: 2025-10-05
# Workshop: Go to Agentic Conference 2025

set -euo pipefail

# Optional logging (set ENABLE_LOGGING=1 to enable)
if [[ "${ENABLE_LOGGING:-0}" == "1" ]]; then
  LOG_FILE="setup-$(date +%Y%m%d-%H%M%S).log"
  exec > >(tee -a "$LOG_FILE") 2>&1
  echo "Logging enabled. Output will be saved to: $LOG_FILE"
  echo ""
fi

have() { command -v "$1" >/dev/null 2>&1; }

info() { printf "\033[1;36m[info]\033[0m %s\n" "$*"; }
ok() { printf "\033[1;32m[ok]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[error]\033[0m %s\n" "$*"; }

echo "═══════════════════════════════════════════════════════"
echo "   n8n Workshop - Automated Setup Script v1.1.1"
echo "   Go to Agentic Conference 2025"
echo "═══════════════════════════════════════════════════════"
echo ""

# Check Docker CLI exists
if ! have docker; then
  err "Docker not found."
  echo ""
  echo "Installation instructions:"
  echo "  1. Download Docker Desktop for Mac:"
  echo "     https://www.docker.com/products/docker-desktop/"
  echo "  2. Install the downloaded .dmg file"
  echo "  3. Start Docker Desktop from Applications"
  echo "  4. Wait for Docker to initialize (whale icon in menu bar)"
  echo "  5. Re-run this script"
  echo ""
  exit 1
fi

ok "Docker is installed: $(docker --version)"

# Check Docker daemon is running
if ! docker ps >/dev/null 2>&1; then
  err "Docker daemon is not running."
  echo ""
  echo "Troubleshooting steps:"
  echo "  1. Start Docker Desktop from Applications folder"
  echo "  2. Wait 30-60 seconds for Docker to fully initialize"
  echo "  3. Look for Docker whale icon in menu bar (should not show errors)"
  echo "  4. If issues persist, restart your Mac"
  echo "  5. Re-run this script"
  echo ""
  exit 1
fi

ok "Docker daemon is running"

# Additional daemon health check
if ! docker info >/dev/null 2>&1; then
  warn "Docker daemon is slow to respond. Waiting 10 seconds..."
  sleep 10
  if ! docker info >/dev/null 2>&1; then
    err "Docker daemon not fully initialized. Please wait and retry."
    exit 1
  fi
fi

SERVER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")
ok "Docker daemon is responsive (version: $SERVER_VERSION)"

# Detect Docker Compose command
if have docker-compose; then
  COMPOSE=(docker-compose)
  ok "Docker Compose is available: $(docker-compose --version)"
else
  COMPOSE=(docker compose)
  ok "Docker Compose V2 is available"
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
cd "$ROOT_DIR"

info "Working directory: $ROOT_DIR"
echo ""
echo "═══════════════════════════════════════════════════════"
echo ""

# Copy configs if not present in repo root
if [[ ! -f docker-compose.yml && -f configs/docker-compose.yml ]]; then
  info "Copying configs/docker-compose.yml to repo root..."
  cp configs/docker-compose.yml ./docker-compose.yml
  ok "docker-compose.yml copied"
elif [[ -f docker-compose.yml ]]; then
  ok "docker-compose.yml already exists (skipping)"
else
  err "docker-compose.yml not found in configs!"
  echo ""
  echo "Are you running this script from the repository root?"
  echo "Current directory: $(pwd)"
  echo ""
  exit 1
fi

if [[ ! -f .env && -f configs/.env.example ]]; then
  info "Copying configs/.env.example to .env (edit as needed)..."
  cp configs/.env.example ./.env
  ok ".env file created. Edit for Google API credentials if needed."
elif [[ -f .env ]]; then
  ok ".env file already exists (skipping)"
else
  warn "No .env.example found. Continuing without environment file."
fi

echo ""

compose_args=(-f docker-compose.yml)

# Optional: if using host-installed Ollama (Metal acceleration), point UI to host
if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]] && have ollama; then
  info "Host Ollama detected and USE_HOST_OLLAMA=1."
  if [[ -f configs/docker-compose.ollama-host.yml ]]; then
    info "Using host Ollama via configs/docker-compose.ollama-host.yml"
    compose_args+=( -f configs/docker-compose.ollama-host.yml )
    info "Starting OpenWebUI, n8n, and postgres (no ollama container)"
  else
    warn "configs/docker-compose.ollama-host.yml not found. Proceeding with standard setup."
  fi
else
  info "Using containerized Ollama (default)"
fi

# Check if containers are already running (idempotency)
echo ""
info "Checking for existing containers..."

REQUIRED_CONTAINERS=("ollama" "n8n" "open-webui" "postgres")
EXISTING_CONTAINERS=()

for container_name in "${REQUIRED_CONTAINERS[@]}"; do
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^$container_name\$"; then
    EXISTING_CONTAINERS+=("$container_name")
  fi
done

if [[ ${#EXISTING_CONTAINERS[@]} -gt 0 ]]; then
  ok "Found running containers: ${EXISTING_CONTAINERS[*]}"
  echo ""
  echo "Containers are already running. Options:"
  echo "  • Continue to use existing containers (recommended)"
  echo "  • Restart containers to apply configuration changes"
  echo ""
  read -p "Restart containers? (y/N): " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "Restarting containers..."
    if "${COMPOSE[@]}" "${compose_args[@]}" restart; then
      ok "Containers restarted successfully"
    else
      err "Failed to restart containers"
      echo ""
      echo "Troubleshooting steps:"
      echo "  1. Check logs: docker-compose logs -f"
      echo "  2. Stop and start manually:"
      echo "     docker-compose down"
      echo "     docker-compose up -d"
      echo ""
      exit 1
    fi
  else
    ok "Using existing containers (no changes made)"
  fi
else
  # Start containers
  info "Starting services with Docker Compose"
  echo ""

  if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]] && have ollama; then
    if "${COMPOSE[@]}" "${compose_args[@]}" up -d open-webui n8n postgres; then
      ok "Containers started successfully"
    else
      err "Failed to start containers"
      echo ""
      echo "Troubleshooting steps:"
      echo "  1. Check logs: docker-compose logs -f"
      echo "  2. Check for port conflicts:"
      echo "     lsof -iTCP:5678,3000,5432 -sTCP:LISTEN"
      echo "  3. Restart Docker Desktop and retry"
      echo "  4. Check disk space: docker system df"
      echo ""
      exit 1
    fi
  else
    if "${COMPOSE[@]}" "${compose_args[@]}" up -d; then
      ok "Containers started successfully"
    else
      err "Failed to start containers"
      echo ""
      echo "Troubleshooting steps:"
      echo "  1. Check logs: docker-compose logs -f"
      echo "  2. Check for port conflicts:"
      echo "     lsof -iTCP:5678,3000,11434,5432 -sTCP:LISTEN"
      echo "  3. Restart Docker Desktop and retry"
      echo "  4. Check disk space: docker system df"
      echo ""
      exit 1
    fi
  fi

  # Wait for container health
  echo ""
  info "Waiting for services to be ready (max 60s per service)..."

  for container_name in "${REQUIRED_CONTAINERS[@]}"; do
    # Skip ollama if using host
    if [[ "$container_name" == "ollama" && "${USE_HOST_OLLAMA:-0}" == "1" ]]; then
      continue
    fi

    # Check if container exists
    if ! docker ps --format '{{.Names}}' | grep -q "^$container_name\$"; then
      warn "Container '$container_name' not found (may not be started)"
      continue
    fi

    printf "  Waiting for %s to be healthy..." "$container_name"
    elapsed=0
    max_wait=60

    while [ $elapsed -lt $max_wait ]; do
      health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "")
      if [[ "$health" == "healthy" ]]; then
        echo " ✓"
        break
      fi

      # Check if container is running (some containers don't have healthchecks)
      running=$(docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null || echo "false")
      if [[ "$running" == "true" && -z "$health" ]]; then
        echo " ✓ (running)"
        break
      fi

      sleep 2
      elapsed=$((elapsed + 2))

      # Progress indicator every 10 seconds
      if [ $((elapsed % 10)) -eq 0 ]; then
        printf "."
      fi
    done

    if [ $elapsed -ge $max_wait ]; then
      echo " ✗ (timeout)"
      warn "Container '$container_name' did not become healthy within ${max_wait}s"
      warn "It may still be initializing. Check with: docker-compose ps"
    fi
  done
fi

# Check container status
echo ""
info "Container Status:"
"${COMPOSE[@]}" ps

echo ""
echo "═══════════════════════════════════════════════════════"
echo ""

# Optional: pull a model when PULL_MODEL=1
if [[ "${PULL_MODEL:-0}" == "1" ]]; then
  MODEL_TO_PULL="${MODEL:-llama3.2}"

  info "Checking for existing Ollama models..."

  # Determine ollama command (container or host)
  if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]] && have ollama; then
    OLLAMA_CMD=(ollama)
  else
    if docker ps --format '{{.Names}}' | grep -q '^ollama$'; then
      OLLAMA_CMD=(docker exec ollama ollama)
    else
      warn "Ollama container not running. Skipping model download."
      OLLAMA_CMD=()
    fi
  fi

  if [[ ${#OLLAMA_CMD[@]} -gt 0 ]]; then
    EXISTING_MODELS=$("${OLLAMA_CMD[@]}" list 2>/dev/null || echo "")

    if echo "$EXISTING_MODELS" | grep -q "$MODEL_TO_PULL"; then
      ok "Model '$MODEL_TO_PULL' already exists. Skipping download."
    else
      echo ""
      echo "Downloading model: $MODEL_TO_PULL"
      echo "This may take 2-10 minutes depending on your internet connection..."
      echo ""

      if "${OLLAMA_CMD[@]}" pull "$MODEL_TO_PULL"; then
        ok "Model '$MODEL_TO_PULL' downloaded successfully"
      else
        err "Model pull failed"
        echo ""
        echo "Troubleshooting:"
        echo "  • Check internet connection"
        echo "  • Verify Ollama is running:"
        if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]]; then
          echo "    ollama list"
        else
          echo "    docker ps | grep ollama"
        fi
        echo "  • Try downloading manually:"
        if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]]; then
          echo "    ollama pull $MODEL_TO_PULL"
        else
          echo "    docker exec -it ollama ollama pull $MODEL_TO_PULL"
        fi
        echo ""
        warn "You can continue and download models later."
      fi
    fi
  fi
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "   Setup Summary"
echo "═══════════════════════════════════════════════════════"
echo ""

# Summary of what was accomplished
echo "✅ Completed:"
echo "   • Docker verified and running"
echo "   • Configuration files prepared (.env, docker-compose.yml)"

if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]]; then
  echo "   • Containers started: n8n, open-webui, postgres (using host Ollama)"
else
  echo "   • Containers started: ollama, n8n, open-webui, postgres"
fi

# Count models
MODEL_COUNT=0
if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]] && have ollama; then
  MODEL_COUNT=$(ollama list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
elif docker ps --format '{{.Names}}' | grep -q '^ollama$'; then
  MODEL_COUNT=$(docker exec ollama ollama list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
fi

if [[ $MODEL_COUNT -gt 0 ]]; then
  echo "   • Ollama models installed: $MODEL_COUNT"
else
  echo "   • Ollama models: none (download later)"
fi

echo ""
echo "🔗 Access Your Services:"
echo "   • OpenWebUI:  http://localhost:3000  (Chat with LLMs)"
echo "   • N8N:        http://localhost:5678  (Build workflows)"

if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]]; then
  echo "   • Ollama API: http://localhost:11434 (Host Ollama)"
else
  echo "   • Ollama API: http://localhost:11434 (LLM API endpoint)"
fi

echo ""
echo "📋 Next Steps:"
echo "   1. Verify installation: ./scripts/verify-mac.sh"
echo "   2. Open OpenWebUI (http://localhost:3000) and create an account"
echo "   3. Open N8N (http://localhost:5678) and set up credentials"
echo "   4. Import sample workflows from ./workflows/"
echo ""
echo "📄 Documentation:"
echo "   • Quick Start:     docs/QUICK_START.md"
echo "   • Configuration:   docs/CONFIGURATION.md"
echo "   • Troubleshooting: docs/TROUBLESHOOTING.md"
echo "   • Workflows:       workflows/README.md"
echo ""
echo "Happy building! 🚀"
echo ""

if [[ "${ENABLE_LOGGING:-0}" == "1" ]]; then
  echo "Log saved to: $LOG_FILE"
fi
