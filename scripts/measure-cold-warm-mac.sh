#!/usr/bin/env bash
# n8n Workshop - Cold vs Warm Start Performance Measurement (macOS)
# Version: 1.1.1
# Last Updated: 2025-10-05
# Workshop: Go to Agentic Conference 2025

set -euo pipefail

# Config (env-overridable)
MODEL=${MODEL:-"llama3.2:3b"}
WARM_RUNS=${WARM_RUNS:-5}
OLLAMA_HOST=${OLLAMA_HOST:-"http://localhost:11434"}
SETTLE_SECONDS=${SETTLE_SECONDS:-2}
PROMPT=${PROMPT:-"Explain what artificial intelligence is in 2-3 sentences."}

have() { command -v "$1" >/dev/null 2>&1; }
info() { printf "\033[1;36m[info]\033[0m %s\n" "$*"; }
ok() { printf "\033[1;32m[ok]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[error]\033[0m %s\n" "$*"; }

# Check required tools
if ! have curl; then
  err "curl is required but not found"
  echo ""
  echo "curl should be pre-installed on macOS."
  echo "If missing, install with: brew install curl"
  echo ""
  exit 1
fi

if ! have jq; then
  err "jq is required for JSON processing but not found"
  echo ""
  echo "Install with: brew install jq"
  echo "Or download from: https://stedolan.github.io/jq/"
  echo ""
  exit 1
fi

if ! have docker; then
  err "Docker is required but not found"
  echo ""
  echo "Install Docker Desktop for Mac:"
  echo "https://www.docker.com/products/docker-desktop/"
  echo ""
  exit 1
fi

# Repo root
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
cd "$ROOT_DIR"

echo "======================================================="
echo "   Cold vs Warm Start Measurement v1.1.1"
echo "======================================================="
echo ""
echo "Model: $MODEL"
echo "Warm runs: $WARM_RUNS"
echo ""

# ==================== PRE-FLIGHT CHECKS ====================
info "Running pre-flight checks..."
echo ""

# Check 1: Ollama API is accessible
printf "Checking Ollama API accessibility..."
if curl -fsS --max-time 5 "$OLLAMA_HOST/api/tags" >/dev/null 2>&1; then
  echo " [OK]"
else
  echo " [X]"
  echo ""
  err "Cannot connect to Ollama at $OLLAMA_HOST"
  echo ""
  echo "Troubleshooting steps:"
  echo "  1. Ensure Docker containers are running:"
  echo "     docker-compose ps"
  echo "  2. Check if Ollama container is healthy:"
  echo "     docker ps | grep ollama"
  echo "  3. Check Ollama container logs:"
  echo "     docker logs ollama"
  echo "  4. Try restarting containers:"
  echo "     docker-compose restart ollama"
  echo ""
  exit 1
fi

# Check 2: Model exists
printf "Checking if model '$MODEL' is available..."
if curl -fsS --max-time 5 "$OLLAMA_HOST/api/tags" 2>/dev/null | jq -e ".models[] | select(.name==\"$MODEL\")" >/dev/null 2>&1; then
  echo " [OK]"
else
  echo " [X]"
  echo ""
  err "Model '$MODEL' not found in Ollama"
  echo ""
  echo "Available models:"
  curl -fsS "$OLLAMA_HOST/api/tags" 2>/dev/null | jq -r '.models[].name' 2>/dev/null | while read -r m; do
    echo "  • $m"
  done || echo "  (Could not retrieve model list)"
  echo ""
  echo "To download the model:"
  echo "  docker exec -it ollama ollama pull $MODEL"
  echo ""
  echo "Or specify a different model with:"
  echo "  MODEL='llama3.2' ./scripts/measure-cold-warm-mac.sh"
  echo ""
  exit 1
fi

# Check 3: Disk space
printf "Checking available disk space..."
FREE_GB=$(df -g . 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
if [[ "$FREE_GB" =~ ^[0-9]+$ ]] && [ "$FREE_GB" -lt 5 ]; then
  echo " [!] Low (${FREE_GB}GB free)"
elif [[ "$FREE_GB" =~ ^[0-9]+$ ]] && [ "$FREE_GB" -ge 5 ]; then
  echo " [OK] (${FREE_GB}GB free)"
else
  echo " ?"
fi

echo ""
ok "All pre-flight checks passed. Starting measurement..."
echo ""

# System summary (best-effort)
CPU=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
MEM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
if [[ "$MEM_BYTES" =~ ^[0-9]+$ ]] && [ "$MEM_BYTES" -gt 0 ]; then
  RAM_GB=$(awk -v b="$MEM_BYTES" 'BEGIN{printf "%.0f GB", b/1073741824}')
else
  RAM_GB="Unknown"
fi
mapfile -t GPU_LIST < <(system_profiler SPDisplaysDataType 2>/dev/null | awk -F": " '/Chipset Model:/{print $2}') || true
if [[ ${#GPU_LIST[@]} -eq 0 ]]; then GPU_LIST=("Unknown"); fi

# Docker containers snapshot
container_stats_before=( )
if docker stats --no-stream --format '{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' >/dev/null 2>&1; then
  while IFS= read -r line; do container_stats_before+=("$line"); done < <(docker stats --no-stream --format '{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}')
fi

# GPU stats placeholder (macOS typically no nvidia-smi)
gpu_stats_before="Unknown"
gpu_stats_after="Unknown"

# Helper: call generate and capture timings
ollama_generate() {
  local prompt="$1"
  local body
  body=$(jq -n --arg m "$MODEL" --arg p "$prompt" '{model:$m,prompt:$p,stream:false}')
  # Use curl timing for total wall-clock
  local tmpfile resp time_total
  tmpfile=$(mktemp)
  time_total=$(curl -sS -o "$tmpfile" -w '%{time_total}' -H 'Content-Type: application/json' -X POST \
    "$OLLAMA_HOST/api/generate" -d "$body")
  resp=$(cat "$tmpfile")
  rm -f "$tmpfile"
  # Parse fields via jq
  local load_d prompt_eval_d eval_d tokens
  load_d=$(echo "$resp" | jq -r 'try (.load_duration // 0)')
  prompt_eval_d=$(echo "$resp" | jq -r 'try (.prompt_eval_duration // 0)')
  eval_d=$(echo "$resp" | jq -r 'try (.eval_duration // 0)')
  tokens=$(echo "$resp" | jq -r 'try (.eval_count // 0)')
  # Convert ns to s
  load_s=$(awk -v n="$load_d" 'BEGIN{printf "%.2f", n/1e9}')
  prompt_s=$(awk -v n="$prompt_eval_d" 'BEGIN{printf "%.2f", n/1e9}')
  eval_s=$(awk -v n="$eval_d" 'BEGIN{printf "%.2f", n/1e9}')
  total_s=$(awk -v t="$time_total" 'BEGIN{printf "%.2f", t}')
  # tokens per second overall
  if [[ "$total_s" == "0" || "$tokens" == "0" ]]; then tps="0"; else tps=$(awk -v tok="$tokens" -v t="$total_s" 'BEGIN{printf "%.2f", tok/t}'); fi
  jq -n --arg total "$total_s" --arg load "$load_s" --arg prompt "$prompt_s" --arg infer "$eval_s" --arg tokens "$tokens" --arg tps "$tps" \
     '{total:($total|tonumber), load:($load|tonumber), prompt:($prompt|tonumber), infer:($infer|tonumber), tokens:($tokens|tonumber), tps:($tps|tonumber)}'
}

# Attempt to stop/unload model for cold start
info "Preparing cold start by unloading model if possible..."
if have ollama; then
  ollama stop "$MODEL" >/dev/null 2>&1 || true
else
  # Fallback: request with keep_alive 0s
  curl -sS -H 'Content-Type: application/json' -X POST "$OLLAMA_HOST/api/generate" \
    -d "{\"model\":\"$MODEL\",\"prompt\":\"Preparing to unload\",\"stream\":false,\"keep_alive\":\"0s\"}" >/dev/null 2>&1 || true
fi
sleep 2

# Measure cold
info "Running cold start measurement..."
echo ""
echo "⏱ Cold start test may take 1-5 minutes depending on:"
echo "  • Model size ($MODEL)"
echo "  • CPU/GPU performance"
echo "  • System memory"
echo ""
printf "Running cold start test (loading model from disk)..."

if cold_json=$(ollama_generate "$PROMPT" 2>&1); then
  echo " Done!"
else
  echo " Failed!"
  echo ""
  err "Cold start test failed"
  echo ""
  echo "This might be due to:"
  echo "  • Model too large for available memory"
  echo "  • Ollama container crashed or restarted"
  echo "  • Network timeout (check OLLAMA_HOST=$OLLAMA_HOST)"
  echo "  • Insufficient disk space"
  echo ""
  echo "Check container logs: docker logs ollama"
  echo ""
  exit 1
fi
cold_total=$(echo "$cold_json" | jq -r .total)
cold_load=$(echo "$cold_json" | jq -r .load)
cold_prompt=$(echo "$cold_json" | jq -r .prompt)
cold_infer=$(echo "$cold_json" | jq -r .infer)
cold_tokens=$(echo "$cold_json" | jq -r .tokens)
cold_tps=$(echo "$cold_json" | jq -r .tps)

info "Waiting $SETTLE_SECONDS second(s) before warm runs..."
sleep "$SETTLE_SECONDS"

# Warm runs
warm_times=()
warm_loads=()
warm_prompts=()
warm_infers=()
warm_tokens=()

for ((i=1;i<=WARM_RUNS;i++)); do
  info "Warm run $i of $WARM_RUNS..."
  wjson=$(ollama_generate "$PROMPT")
  warm_times+=("$(echo "$wjson" | jq -r .total)")
  warm_loads+=("$(echo "$wjson" | jq -r .load)")
  warm_prompts+=("$(echo "$wjson" | jq -r .prompt)")
  warm_infers+=("$(echo "$wjson" | jq -r .infer)")
  warm_tokens+=("$(echo "$wjson" | jq -r .tokens)")
  sleep 1
done

# Aggregate warm metrics
join_by_comma() { local IFS=","; echo "$*"; }

warm_avg=$(printf '%s
' "${warm_times[@]}" | awk '{s+=$1} END {if(NR>0) printf "%.2f", s/NR; else print 0}')
warm_min=$(printf '%s
' "${warm_times[@]}" | awk 'NR==1{m=$1} $1<m{m=$1} END {if(NR>0) printf "%.2f", m; else print 0}')
warm_max=$(printf '%s
' "${warm_times[@]}" | awk 'NR==1{m=$1} $1>m{m=$1} END {if(NR>0) printf "%.2f", m; else print 0}')
load_avg=$(printf '%s
' "${warm_loads[@]}" | awk '{s+=$1} END {if(NR>0) printf "%.3f", s/NR; else print 0}')
prompt_avg=$(printf '%s
' "${warm_prompts[@]}" | awk '{s+=$1} END {if(NR>0) printf "%.2f", s/NR; else print 0}')
infer_avg=$(printf '%s
' "${warm_infers[@]}" | awk '{s+=$1} END {if(NR>0) printf "%.2f", s/NR; else print 0}')
tokens_avg=$(printf '%s
' "${warm_tokens[@]}" | awk '{s+=$1} END {if(NR>0) printf "%.0f", s/NR; else print 0}')
if [[ "$warm_avg" == "0" ]]; then warm_tps="0"; else warm_tps=$(awk -v tok="$tokens_avg" -v t="$warm_avg" 'BEGIN{printf "%.2f", tok/t}'); fi

# Docker containers snapshot after
container_stats_after=( )
if docker stats --no-stream --format '{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' >/dev/null 2>&1; then
  while IFS= read -r line; do container_stats_after+=("$line"); done < <(docker stats --no-stream --format '{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}')
fi

# Comparison
speedup=$(awk -v c="$cold_total" -v w="$warm_avg" 'BEGIN{ if(w==0) print 0; else printf "%.2f", c/w }')
time_saved=$(awk -v c="$cold_total" -v w="$warm_avg" 'BEGIN{ printf "%.2f", c-w }')
load_time_saved=$(awk -v c="$cold_load" -v w="$load_avg" 'BEGIN{ printf "%.2f", c-w }')

# Build export JSON via jq
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

system_json=$(jq -n --arg cpu "$CPU" --arg ram "$RAM_GB" --argjson gpus "$(printf '%s\n' "${GPU_LIST[@]}" | jq -R . | jq -s .)" '{cpu:$cpu, ram:$ram, gpus:$gpus, gpuToolAvailable:false, gpuActive:false}')

cold_json_obj=$(jq -n --arg total "$cold_total" --arg load "$cold_load" --arg prompt "$cold_prompt" --arg infer "$cold_infer" --arg tokens "$cold_tokens" --arg tps "$cold_tps" '{totalSeconds:($total|tonumber), loadSeconds:($load|tonumber), promptEvalSeconds:($prompt|tonumber), inferenceSeconds:($infer|tonumber), tokens:($tokens|tonumber), tokensPerSecond:($tps|tonumber)}')

warm_json_obj=$(jq -n --arg runs "$WARM_RUNS" --arg avg "$warm_avg" --arg min "$warm_min" --arg max "$warm_max" --arg l "$load_avg" --arg p "$prompt_avg" --arg inf "$infer_avg" --arg tok "$tokens_avg" --arg tps "$warm_tps" '{runs:($runs|tonumber), avgSeconds:($avg|tonumber), minSeconds:($min|tonumber), maxSeconds:($max|tonumber), avgLoadSeconds:($l|tonumber), avgPromptEvalSeconds:($p|tonumber), avgInferenceSeconds:($inf|tonumber), avgTokens:($tok|tonumber), avgTokensPerSecond:($tps|tonumber)}')

comparison_json=$(jq -n --arg c "$cold_total" --arg w "$warm_avg" --arg s "$speedup" --arg ts "$time_saved" --arg ls "$load_time_saved" '{coldTotalSeconds:($c|tonumber), warmAvgSeconds:($w|tonumber), speedupFactor:($s|tonumber), timeSavedSeconds:($ts|tonumber), loadTimeSavedSeconds:($ls|tonumber)}')

csb_json=$(printf '%s\n' "${container_stats_before[@]}" | jq -R . | jq -s .)
csa_json=$(printf '%s\n' "${container_stats_after[@]}" | jq -R . | jq -s .)

export_json=$(jq -n \
  --arg ts "$timestamp" --arg model "$MODEL" --arg prompt "$PROMPT" --arg runs "$WARM_RUNS" --arg settle "$SETTLE_SECONDS" \
  --arg gpuBefore "$gpu_stats_before" --arg gpuAfter "$gpu_stats_after" \
  --argjson system "$system_json" --argjson cold "$cold_json_obj" --argjson warm "$warm_json_obj" --argjson cmp "$comparison_json" \
  --argjson csb "$csb_json" --argjson csa "$csa_json" \
  '{timestamp:$ts, model:$model, prompt:$prompt, warmRuns:($runs|tonumber), settleSeconds:($settle|tonumber), system:$system, coldStart:$cold, warmStart:$warm, comparison:$cmp, containerStatsBefore:$csb, containerStatsAfter:$csa, gpuStatsBefore:$gpuBefore, gpuStatsAfter:$gpuAfter}')

# Save under artifacts/performance
OUT_DIR="$ROOT_DIR/artifacts/performance"
mkdir -p "$OUT_DIR"
outfile="$OUT_DIR/performance-cold-warm-$(date '+%Y%m%d-%H%M%S').json"
echo "$export_json" > "$outfile"
ok "Results saved to $outfile"
