#!/usr/bin/env bash
# n8n Workshop - Automated Setup Script (macOS)
# Version: 1.4.0
# Last Updated: 2025-10-21
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

# Color and formatting functions
info() { printf "\033[1;36m[ℹ️  INFO]\033[0m %s\n" "$*"; }
ok() { printf "\033[1;32m[✓ OK]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[⚠️  WARN]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[✗ ERROR]\033[0m %s\n" "$*"; }
step() { printf "\033[1;35m[→]\033[0m \033[1m%s\033[0m\n" "$*"; }
success() { printf "\033[1;32m%s\033[0m\n" "$*"; }
highlight() { printf "\033[1;33m%s\033[0m" "$*"; }
bold() { printf "\033[1m%s\033[0m" "$*"; }
dim() { printf "\033[2m%s\033[0m" "$*"; }

# Separator functions
separator() { printf "\033[1;34m%s\033[0m\n" "═══════════════════════════════════════════════════════"; }
line() { printf "\033[0;90m%s\033[0m\n" "───────────────────────────────────────────────────────"; }

# Function to detect system specifications
detect_system_specs() {
  TOTAL_RAM=0
  AVAILABLE_RAM=0
  CPU_CORES=0
  HAS_GPU=false
  GPU_NAME="None"
  RECOMMENDED_MODEL=""
  RECOMMENDED_CHOICE=1

  # Detect RAM (macOS)
  if have sysctl; then
    TOTAL_RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
    if [[ "$TOTAL_RAM_BYTES" -gt 0 ]]; then
      TOTAL_RAM=$(echo "scale=1; $TOTAL_RAM_BYTES / 1024 / 1024 / 1024" | bc)
    fi

    # Available RAM (free + inactive)
    VM_STAT=$(vm_stat 2>/dev/null)
    if [[ -n "$VM_STAT" ]]; then
      PAGE_SIZE=$(vm_stat | grep "page size" | awk '{print $8}' || echo "4096")
      FREE_PAGES=$(echo "$VM_STAT" | grep "Pages free" | awk '{print $3}' | tr -d '.')
      INACTIVE_PAGES=$(echo "$VM_STAT" | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
      AVAILABLE_RAM=$(echo "scale=1; ($FREE_PAGES + $INACTIVE_PAGES) * $PAGE_SIZE / 1024 / 1024 / 1024" | bc)
    fi
  fi

  # Detect CPU cores
  if have sysctl; then
    CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo "0")
  fi

  # Detect GPU (macOS - Apple Silicon or NVIDIA)
  if have system_profiler; then
    GPU_INFO=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | awk -F': ' '{print $2}')
    if [[ -n "$GPU_INFO" ]]; then
      GPU_NAME="$GPU_INFO"
      # Check if it's Apple Silicon GPU or dedicated NVIDIA
      if [[ "$GPU_INFO" =~ "Apple" ]] || [[ "$GPU_INFO" =~ "NVIDIA" ]] || [[ "$GPU_INFO" =~ "AMD" ]]; then
        HAS_GPU=true
      fi
    fi
  fi

  # Recommend model based on specs
  if [[ $(echo "$TOTAL_RAM < 6" | bc -l) -eq 1 ]]; then
    RECOMMENDED_MODEL="llama3.2:1b"
    RECOMMENDED_CHOICE=1
  elif [[ $(echo "$TOTAL_RAM < 10" | bc -l) -eq 1 ]]; then
    if [[ "$HAS_GPU" == true ]]; then
      RECOMMENDED_MODEL="llama3.2:1b or llama3.2"
      RECOMMENDED_CHOICE=2
    else
      RECOMMENDED_MODEL="llama3.2:1b"
      RECOMMENDED_CHOICE=1
    fi
  else
    # 10GB+ RAM
    if [[ "$HAS_GPU" == true ]]; then
      RECOMMENDED_MODEL="llama3.2 or mistral"
      RECOMMENDED_CHOICE=2
    else
      RECOMMENDED_MODEL="llama3.2"
      RECOMMENDED_CHOICE=2
    fi
  fi
}

echo ""
separator
printf "\033[1;36m   🚀 n8n Workshop - Automated Setup Script v1.4.0\033[0m\n"
printf "\033[1;37m   Go to Agentic Conference 2025\033[0m\n"
separator
echo ""

# Check Docker CLI exists
step "Checking Docker installation..."
if ! have docker; then
  err "Docker not found."
  echo ""
  printf "\033[1;33m📦 Installation instructions:\033[0m\n"
  echo ""
  printf "  \033[1m1.\033[0m Download Docker Desktop for Mac:\n"
  printf "     \033[4;36mhttps://www.docker.com/products/docker-desktop/\033[0m\n"
  printf "  \033[1m2.\033[0m Install the downloaded .dmg file\n"
  printf "  \033[1m3.\033[0m Start Docker Desktop from Applications\n"
  printf "  \033[1m4.\033[0m Wait for Docker to initialize (🐳 whale icon in menu bar)\n"
  printf "  \033[1m5.\033[0m Re-run this script\n"
  echo ""
  exit 1
fi

ok "Docker is installed: $(docker --version)"

# Check Docker daemon is running
step "Checking Docker daemon..."
if ! docker ps >/dev/null 2>&1; then
  err "Docker daemon is not running."
  echo ""
  printf "\033[1;33m🔧 Troubleshooting steps:\033[0m\n"
  echo ""
  printf "  \033[1m1.\033[0m Start Docker Desktop from Applications folder\n"
  printf "  \033[1m2.\033[0m Wait 30-60 seconds for Docker to fully initialize\n"
  printf "  \033[1m3.\033[0m Look for 🐳 Docker whale icon in menu bar (should not show errors)\n"
  printf "  \033[1m4.\033[0m If issues persist, restart your Mac\n"
  printf "  \033[1m5.\033[0m Re-run this script\n"
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
separator
echo ""

# Detect system specifications
step "Detecting system specifications..."
detect_system_specs

echo ""
printf "\033[1;36m  💻 System Specifications:\033[0m\n"
if [[ $(echo "$TOTAL_RAM > 0" | bc -l) -eq 1 ]]; then
  printf "    \033[1;33m🧠 RAM:\033[0m       ${TOTAL_RAM} GB total$(if [[ $(echo "$AVAILABLE_RAM > 0" | bc -l) -eq 1 ]]; then echo ", ${AVAILABLE_RAM} GB available"; fi)\n"
else
  printf "    \033[1;33m🧠 RAM:\033[0m       Unable to detect\n"
fi

if [[ $CPU_CORES -gt 0 ]]; then
  printf "    \033[1;35m⚡ CPU:\033[0m       $CPU_CORES cores\n"
else
  printf "    \033[1;35m⚡ CPU:\033[0m       Unable to detect\n"
fi

if [[ "$HAS_GPU" == true ]]; then
  printf "    \033[1;36m🎮 GPU:\033[0m       $GPU_NAME\n"
else
  printf "    \033[1;36m🎮 GPU:\033[0m       None detected (CPU-only mode)\n"
fi

echo ""
printf "  \033[1;32m✨ Recommended Model:\033[0m \033[1m$RECOMMENDED_MODEL\033[0m\n"
echo ""
separator
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

# GPU detection and configuration (for Docker on Mac with NVIDIA/AMD GPUs)
# Note: For Apple Silicon Metal acceleration, use USE_HOST_OLLAMA=1 instead
if [[ "${USE_HOST_OLLAMA:-0}" != "1" ]]; then
  gpu_override_path="configs/docker-compose.gpu.yml"

  if [[ "$HAS_GPU" == true ]] && [[ -f "$gpu_override_path" ]]; then
    # Only add GPU support for non-Apple GPUs (NVIDIA/AMD) in containerized setup
    if [[ ! "$GPU_NAME" =~ "Apple" ]]; then
      info "Detected compatible GPU ($GPU_NAME). Enabling GPU acceleration."
      compose_args+=( -f "$gpu_override_path" )
    fi
  fi
fi

# Optional: if using host-installed Ollama (Metal acceleration), point UI to host
if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]] && have ollama; then
  info "Host Ollama detected and USE_HOST_OLLAMA=1."
  if [[ -f configs/docker-compose.ollama-host.yml ]]; then
    info "Using host Ollama via configs/docker-compose.ollama-host.yml"
    compose_args+=( -f configs/docker-compose.ollama-host.yml )
    info "Starting OpenWebUI, n8n, and postgres (no ollama container)"
    info "Metal GPU acceleration via host Ollama (recommended for Apple Silicon)"
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
    info "Recreating containers with updated configuration..."
    echo "  >> Stopping and removing existing containers..."
    # Use down + up instead of restart to properly apply device configurations like GPU
    if "${COMPOSE[@]}" "${compose_args[@]}" down; then
      ok "Containers stopped"
    fi

    echo "  >> Starting containers with configuration..."
    if "${COMPOSE[@]}" "${compose_args[@]}" up --detach; then
      ok "Containers recreated successfully!"
    else
      err "Failed to recreate containers"
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
  # Start containers - First pull images explicitly
  step "Preparing to download Docker images"
  echo ""

  # Logout from Docker Hub to avoid unverified email issues with public images
  if docker info 2>/dev/null | grep -q "Username:"; then
    info "Logging out from Docker Hub to pull public images without authentication..."
    docker logout >/dev/null 2>&1 || true
    ok "Using unauthenticated access for public images"
    echo ""
  fi

  printf "\033[1;33m⚠️  IMPORTANT:\033[0m First-time setup will download Docker images\n"
  echo ""
  printf "   \033[1;36m📦 Total download size:\033[0m ~4-5 GB (ollama, n8n, open-webui, postgres)\n"
  printf "   \033[1;35m⏱️  Download time:\033[0m      5-15 minutes depending on your internet speed\n"
  printf "   \033[1;33m🔄 Verification:\033[0m        After download, Docker will verify/extract (1-3 min)\n"
  printf "   \033[1;32m✓  This is normal:\033[0m      Please be patient!\n"
  echo ""

  # Define images to pull based on configuration
  if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]] && have ollama; then
    IMAGES_TO_PULL=(
      "ghcr.io/open-webui/open-webui:main"
      "n8nio/n8n:latest"
      "postgres:15-alpine"
    )
    info "Pulling 3 images (using host Ollama)..."
  else
    IMAGES_TO_PULL=(
      "ollama/ollama:latest"
      "ghcr.io/open-webui/open-webui:main"
      "n8nio/n8n:latest"
      "postgres:15-alpine"
    )
    info "Pulling 4 images..."
  fi

  echo ""
  PULL_SUCCESS=0
  PULL_FAILED=()

  for image in "${IMAGES_TO_PULL[@]}"; do
    image_name=$(echo "$image" | cut -d':' -f1 | awk -F'/' '{print $NF}')

    # Check if image already exists locally
    if docker image inspect "$image" >/dev/null 2>&1; then
      ok "Image '\033[1;36m$image_name\033[0m' already exists locally (skipping download)"
      ((PULL_SUCCESS++))
      continue
    fi

    printf "\033[1;35m[→]\033[0m Pulling image: \033[1;36m$image\033[0m\n"
    printf "   \033[2mThis may take 2-10 minutes depending on image size and connection speed...\033[0m\n"
    echo ""

    # Pull with progress output
    if docker pull "$image"; then
      echo ""
      success "✓ Successfully pulled: $image_name"
      ((PULL_SUCCESS++))
    else
      echo ""
      err "Failed to pull: $image_name"
      PULL_FAILED+=("$image")
    fi
    echo ""
  done

  # Summary of pull results
  separator
  echo ""
  if [[ ${#PULL_FAILED[@]} -gt 0 ]]; then
    err "Image pull failed for ${#PULL_FAILED[@]} image(s):"
    for failed_image in "${PULL_FAILED[@]}"; do
      printf "   \033[1;31m✗\033[0m $failed_image\n"
    done
    echo ""
    printf "\033[1;33m🔧 Troubleshooting steps:\033[0m\n"
    echo ""
    printf "  \033[1m1.\033[0m Check your internet connection\n"
    printf "  \033[1m2.\033[0m Check Docker Hub status: \033[4;36mhttps://status.docker.com\033[0m\n"
    printf "  \033[1m3.\033[0m Try pulling manually: \033[2mdocker pull <image-name>\033[0m\n"
    printf "  \033[1m4.\033[0m Check disk space: \033[2mdocker system df\033[0m\n"
    printf "  \033[1m5.\033[0m Restart Docker Desktop and retry this script\n"
    echo ""
    exit 1
  else
    success "✓ All images pulled successfully ($PULL_SUCCESS/${#IMAGES_TO_PULL[@]})"
    echo ""
  fi

  # Now start containers
  info "Starting services with Docker Compose"
  echo ""

  if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]] && have ollama; then
    if "${COMPOSE[@]}" "${compose_args[@]}" up --detach open-webui n8n postgres 2>&1 | grep -E '^\[|^✔|Container|Network|Volume|Creating|Starting' || true; then
      echo ""
      ok "Containers started successfully"
      echo "   Containers are running in the background"
      echo "   To view logs: docker-compose logs -f"
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
    if "${COMPOSE[@]}" "${compose_args[@]}" up --detach 2>&1 | grep -E '^\[|^✔|Container|Network|Volume|Creating|Starting' || true; then
      echo ""
      ok "Containers started successfully"
      echo "   Containers are running in the background"
      echo "   To view logs: docker-compose logs -f"
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
        echo " [OK]"
        break
      fi

      # Check if container is running (some containers don't have healthchecks)
      running=$(docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null || echo "false")
      if [[ "$running" == "true" && -z "$health" ]]; then
        echo " [OK] (running)"
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
      echo " [X] (timeout)"
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
echo "======================================================="
echo ""

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

# Interactive model download (default) or automated via PULL_MODEL env var
if [[ ${#OLLAMA_CMD[@]} -gt 0 ]]; then
  # Check if running in automated mode
  if [[ "${PULL_MODEL:-}" == "1" ]]; then
    # Automated mode - use MODEL env var
    MODEL_TO_PULL="${MODEL:-llama3.2}"
    info "Checking for existing Ollama models..."
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
        warn "You can continue and download models later."
      fi
    fi
  else
    # Interactive mode - prompt user
    printf "\033[1;33m🤖 Would you like to download an Ollama model?\033[0m (Y/n) [default: Yes]\n"
    read -r download_choice

    if [[ "$download_choice" == "" || "$download_choice" =~ ^[Yy]$ ]]; then
      echo ""
      step "Checking for existing Ollama models..."
      EXISTING_MODELS=$("${OLLAMA_CMD[@]}" list 2>/dev/null || echo "")

      if [[ -n "$EXISTING_MODELS" ]]; then
        echo ""
        printf "\033[1;36m📦 Currently installed models:\033[0m\n"
        echo ""
        # Format the table with proper indentation
        echo "$EXISTING_MODELS" | while IFS= read -r line; do
          if [[ "$line" =~ ^NAME || "$line" =~ ^[A-Za-z] ]]; then
            printf "   \033[0;37m%s\033[0m\n" "$line"
          fi
        done
        echo ""
      fi

      printf "\033[1;35m  → Select a model to download:\033[0m\n"
      printf "     \033[2mBased on your system (${TOTAL_RAM}GB RAM, $CPU_CORES cores$(if [[ "$HAS_GPU" == true ]]; then echo ", GPU"; fi))\033[0m\n"
      echo ""

      # Highlight recommended model
      if [[ $RECOMMENDED_CHOICE -eq 1 ]]; then
        printf "     \033[1;32m1.\033[0m \033[1mllama3.2:1b\033[0m  \033[2m(1GB)\033[0m  - Fast, works on any system \033[1;33m[RECOMMENDED]\033[0m\n"
        printf "     \033[1;36m2.\033[0m llama3.2     \033[2m(4GB)\033[0m  - Balanced, recommended for workshop\n"
        printf "     \033[1;36m3.\033[0m mistral      \033[2m(4GB)\033[0m  - Good for coding tasks\n"
      elif [[ $RECOMMENDED_CHOICE -eq 2 ]]; then
        printf "     \033[1;36m1.\033[0m llama3.2:1b  \033[2m(1GB)\033[0m  - Fast, works on any system\n"
        printf "     \033[1;32m2.\033[0m \033[1mllama3.2\033[0m     \033[2m(4GB)\033[0m  - Balanced, recommended for workshop \033[1;33m[RECOMMENDED]\033[0m\n"
        printf "     \033[1;36m3.\033[0m mistral      \033[2m(4GB)\033[0m  - Good for coding tasks\n"
      elif [[ $RECOMMENDED_CHOICE -eq 3 ]]; then
        printf "     \033[1;36m1.\033[0m llama3.2:1b  \033[2m(1GB)\033[0m  - Fast, works on any system\n"
        printf "     \033[1;36m2.\033[0m llama3.2     \033[2m(4GB)\033[0m  - Balanced, recommended for workshop\n"
        printf "     \033[1;32m3.\033[0m \033[1mmistral\033[0m      \033[2m(4GB)\033[0m  - Good for coding tasks \033[1;33m[RECOMMENDED]\033[0m\n"
      else
        printf "     \033[1;36m1.\033[0m llama3.2:1b  \033[2m(1GB)\033[0m  - Fast, works on any system\n"
        printf "     \033[1;36m2.\033[0m llama3.2     \033[2m(4GB)\033[0m  - Balanced, recommended for workshop\n"
        printf "     \033[1;36m3.\033[0m mistral      \033[2m(4GB)\033[0m  - Good for coding tasks\n"
      fi

      printf "     \033[1;35m4.\033[0m All models   \033[2m(9GB)\033[0m  - Download all three \033[1;33m([!] takes longest, 15-30 min)\033[0m\n"
      printf "     \033[1;90m5.\033[0m Skip for now\n"
      echo ""
      read -p "$(printf '\033[1mEnter choice (1-5)\033[0m [default: \033[1;33m'$RECOMMENDED_CHOICE'\033[0m]: ')" model_choice

      # Use recommended model if user just presses Enter
      if [[ -z "$model_choice" ]]; then
        model_choice=$RECOMMENDED_CHOICE
        echo "  Using recommended choice: $model_choice"
      fi
      
      case "$model_choice" in
        1) MODELS_TO_PULL=("llama3.2:1b") ;;
        2) MODELS_TO_PULL=("llama3.2") ;;
        3) MODELS_TO_PULL=("mistral") ;;
        4) MODELS_TO_PULL=("llama3.2:1b" "llama3.2" "mistral") ;;
        *) MODELS_TO_PULL=() ;;
      esac
      
      if [[ ${#MODELS_TO_PULL[@]} -gt 0 ]]; then
        echo ""
        if [[ ${#MODELS_TO_PULL[@]} -gt 1 ]]; then
          info "Downloading ${#MODELS_TO_PULL[@]} models... This will take 15-30 minutes."
          echo "   >> Total size: ~9GB. Please be patient..."
        fi
        
        success_count=0
        fail_count=0
        
        for model in "${MODELS_TO_PULL[@]}"; do
          # Check if model already exists
          if echo "$EXISTING_MODELS" | grep -q "$model"; then
            ok "Model '$model' is already downloaded. Skipping."
            ((success_count++))
          else
            echo ""
            info "Downloading '$model'... This may take 2-10 minutes depending on your connection."
            if [[ ${#MODELS_TO_PULL[@]} -eq 1 ]]; then
              echo "   >> Model size and download time varies. Please be patient..."
              echo "   >> After download completes, the model will be validated/extracted (may take 1-2 min)"
            fi
            echo ""
            
            if "${OLLAMA_CMD[@]}" pull "$model"; then
              echo ""
              ok "Model '$model' downloaded successfully!"
              ((success_count++))
            else
              echo ""
              err "Model '$model' download failed"
              ((fail_count++))
              echo ""
              echo "  >> Verify download with:"
              if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]]; then
                echo "     ollama list"
              else
                echo "     docker exec -it ollama ollama list"
              fi
              echo "  >> Retry download with:"
              if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]]; then
                echo "     ollama pull $model"
              else
                echo "     docker exec -it ollama ollama pull $model"
              fi
            fi
          fi
        done
        
        # Summary for multiple models
        if [[ ${#MODELS_TO_PULL[@]} -gt 1 ]]; then
          echo ""
          echo "  Model Download Summary:"
          echo "    [OK] Successful: $success_count"
          if [[ $fail_count -gt 0 ]]; then
            echo "    [X] Failed: $fail_count"
          fi
        fi
        
        echo ""
        echo "  >> You can download additional models later with:"
        if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]]; then
          echo "     ollama pull [model-name]"
        else
          echo "     docker exec -it ollama ollama pull [model-name]"
        fi
      fi
    fi
  fi
fi

echo ""
separator
printf "\033[1;36m   ✨ Setup Summary\033[0m\n"
separator
echo ""

# Summary of what was accomplished
printf "\033[1;32m✓ Completed:\033[0m\n"
printf "   \033[1;32m✓\033[0m Docker verified and running\n"
printf "   \033[1;32m✓\033[0m Configuration files prepared (.env and docker-compose.yml)\n"

if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]]; then
  printf "   \033[1;32m✓\033[0m Containers started: \033[1mn8n, open-webui, postgres\033[0m (using host Ollama)\n"
else
  printf "   \033[1;32m✓\033[0m Containers started: \033[1mollama, n8n, open-webui, postgres\033[0m\n"
fi

# Count models
MODEL_COUNT=0
if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]] && have ollama; then
  MODEL_COUNT=$(ollama list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
elif docker ps --format '{{.Names}}' | grep -q '^ollama$'; then
  MODEL_COUNT=$(docker exec ollama ollama list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
fi

if [[ $MODEL_COUNT -gt 0 ]]; then
  printf "   \033[1;32m✓\033[0m Ollama models installed: \033[1;33m$MODEL_COUNT\033[0m\n"
else
  printf "   \033[1;33m⚠\033[0m  Ollama models: none (download later)\n"
fi

echo ""
printf "\033[1;36m🌐 Access Your Services:\033[0m\n"
printf "   \033[1;35m•\033[0m OpenWebUI:  \033[4;36mhttp://localhost:3000\033[0m  \033[2m(Chat with LLMs)\033[0m\n"
printf "   \033[1;35m•\033[0m N8N:        \033[4;36mhttp://localhost:5678\033[0m  \033[2m(Build workflows)\033[0m\n"

if [[ "${USE_HOST_OLLAMA:-0}" == "1" ]]; then
  printf "   \033[1;35m•\033[0m Ollama API: \033[4;36mhttp://localhost:11434\033[0m \033[2m(Host Ollama)\033[0m\n"
else
  printf "   \033[1;35m•\033[0m Ollama API: \033[4;36mhttp://localhost:11434\033[0m \033[2m(LLM API endpoint)\033[0m\n"
fi

echo ""
printf "\033[1;33m📋 Next Steps:\033[0m\n"
printf "   \033[1m1.\033[0m Open OpenWebUI (\033[4;36mhttp://localhost:3000\033[0m) and create an account\n"
printf "   \033[1m2.\033[0m Open N8N (\033[4;36mhttp://localhost:5678\033[0m) and set up credentials\n"
printf "   \033[1m3.\033[0m Import workflows using n8n's 'Import from File' (see \033[2mdocs/QUICK_START.md\033[0m)\n"
echo ""
printf "\033[1;36m📚 Documentation:\033[0m\n"
printf "   \033[1;35m•\033[0m Quick Start:     \033[2mdocs/QUICK_START.md\033[0m\n"
printf "   \033[1;35m•\033[0m Configuration:   \033[2mdocs/CONFIGURATION.md\033[0m\n"
printf "   \033[1;35m•\033[0m Troubleshooting: \033[2mdocs/TROUBLESHOOTING.md\033[0m\n"
printf "   \033[1;35m•\033[0m Workflows:       \033[2mworkflows/README.md\033[0m\n"
echo ""
printf "\033[1;32m🎉 Happy building!\033[0m\n"
echo ""

if [[ "${ENABLE_LOGGING:-0}" == "1" ]]; then
  echo "Log saved to: $LOG_FILE"
fi
