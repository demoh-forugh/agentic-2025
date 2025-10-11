<#
.SYNOPSIS
    n8n Workshop - Cold vs Warm Start Performance Measurement

.DESCRIPTION
    Measures LLM performance comparing cold start (model loading) vs warm start (model cached).
    Includes pre-flight checks, system profiling, and comprehensive metrics export.

.PARAMETER Model
    Ollama model to test (default: llama3.2:3b)

.PARAMETER WarmRuns
    Number of warm start iterations (default: 5)

.PARAMETER OllamaHost
    Ollama API endpoint (default: http://localhost:11434)

.PARAMETER SettleSeconds
    Wait time between cold and warm tests (default: 2)

.EXAMPLE
    .\measure-cold-warm-windows.ps1
    Run with default settings

.EXAMPLE
    .\measure-cold-warm-windows.ps1 -Model "llama3.2:1b" -WarmRuns 10
    Test smaller model with 10 warm iterations

.NOTES
    Version: 1.2.0
    Last Updated: 2025-10-10
    Workshop: Go to Agentic Conference 2025
    Requires: Docker or Podman with Ollama container running
#>

# n8n Workshop - Cold vs Warm Start Performance Measurement
# Version: 1.2.0
# Last Updated: 2025-10-10
# Workshop: Go to Agentic Conference 2025
# Supports: Docker Desktop, Podman

param(
    [string]$Model = "llama3.2:3b",
    [int]$WarmRuns = 5,
    [string]$OllamaHost = "http://localhost:11434",
    [int]$SettleSeconds = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Detect container runtime
$script:ContainerRuntime = $null
$script:containerCmd = $null
$script:composeCmd = $null

function Test-CommandExists {
    param($command)
    $null = Get-Command $command -ErrorAction SilentlyContinue
    return $?
}

if (Test-CommandExists docker) {
    $script:ContainerRuntime = "docker"
    $script:containerCmd = "docker"
} elseif (Test-CommandExists podman) {
    $script:ContainerRuntime = "podman"
    $script:containerCmd = "podman"
} else {
    Write-Host "[X] Neither Docker nor Podman is installed!" -ForegroundColor Red
    Write-Host "Please install Docker Desktop or Podman and run setup script." -ForegroundColor Yellow
    exit 1
}

# Determine compose command
if ($script:ContainerRuntime -eq "podman") {
    if (Test-CommandExists podman-compose) {
        $script:composeCmd = "podman-compose"
    } else {
        $script:composeCmd = "podman compose"
    }
} else {
    if (Test-CommandExists docker-compose) {
        $script:composeCmd = "docker-compose"
    } else {
        $script:composeCmd = "docker compose"
    }
}

function Show-Banner {
    param([string]$Text)
    $line = "=" * 72
    Write-Host $line -ForegroundColor Cyan
    Write-Host ("  " + $Text) -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
}

function Write-Section {
    param([string]$Title)
    Write-Host ("-- " + $Title + " --") -ForegroundColor Cyan
}

function Write-StatusLine {
    param(
        [string]$Label,
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    Write-Host ("  [" + $Label + "] " + $Message) -ForegroundColor $Color
}

function Get-RamInGB {
    param([string]$RamString)
    if (-not $RamString) { return $null }
    if ($RamString -match "([0-9]+(\.[0-9]+)?)") {
        return [double]$Matches[1]
    }
    return $null
}

function Get-ContainerMemoryMiB {
    param(
        [string[]]$Stats,
        [string]$ContainerName
    )
    if (-not $Stats) { return $null }
    foreach ($line in $Stats) {
        if ($line -match $ContainerName) {
            if ($line -match "([0-9]+(\.[0-9]+)?)GiB") {
                return [double]$Matches[1] * 1024
            }
            if ($line -match "([0-9]+(\.[0-9]+)?)MiB") {
                return [double]$Matches[1]
            }
        }
    }
    return $null
}

function Write-CapabilitySummary {
    param(
        $System,
        $ColdMetrics,
        $WarmMetrics,
        $Comparison,
        [string[]]$ContainerStatsAfter
    )

    Show-Banner "AI Capability Summary"

    if (-not $WarmMetrics) {
        Write-StatusLine "Notice" "Warm-start data unavailable. Unable to assess responsiveness." [ConsoleColor]::Yellow
        return
    }

    $warmAvg = $WarmMetrics.avgSeconds
    $ramGb = Get-RamInGB $System.ram
    $gpuActive = $System.gpuActive
    $ollamaMem = Get-ContainerMemoryMiB -Stats $ContainerStatsAfter -ContainerName "ollama"
    $webuiMem = Get-ContainerMemoryMiB -Stats $ContainerStatsAfter -ContainerName "open-webui"
    $n8nMem = Get-ContainerMemoryMiB -Stats $ContainerStatsAfter -ContainerName "n8n"

    if ($warmAvg -le 1) {
        Write-StatusLine "Ollama" "Warm responses average $warmAvg s (~real-time)." [ConsoleColor]::Green
    } elseif ($warmAvg -le 3) {
        Write-StatusLine "Ollama" "Warm responses average $warmAvg s. Suitable for interactive agents." [ConsoleColor]::Yellow
    } else {
        Write-StatusLine "Ollama" "Warm responses average $warmAvg s. Expect noticeable delay; consider smaller models." [ConsoleColor]::Red
    }

    if ($ramGb) {
        if ($ramGb -ge 32) {
            Write-StatusLine "Memory" "$ramGb GB RAM detected. Plenty of headroom for concurrent agents." [ConsoleColor]::Green
        } elseif ($ramGb -ge 16) {
            Write-StatusLine "Memory" "$ramGb GB RAM detected. Adequate for workshop stack; monitor usage." [ConsoleColor]::Yellow
        } else {
            Write-StatusLine "Memory" "$ramGb GB RAM detected. Use smaller models and limit concurrent workloads." [ConsoleColor]::Red
        }
    } else {
        Write-StatusLine "Memory" "Total RAM unknown. Verify your system meets minimum requirements." [ConsoleColor]::Yellow
    }

    if ($gpuActive) {
        Write-StatusLine "GPU" "Dedicated GPU detected via nvidia-smi. Ollama can leverage acceleration for higher throughput." [ConsoleColor]::Green
    } elseif ($System.gpuToolAvailable) {
        Write-StatusLine "GPU" "nvidia-smi available but GPU not active. Ensure containers are configured for GPU usage if desired." [ConsoleColor]::Yellow
    } else {
        Write-StatusLine "GPU" "No NVIDIA GPU detected. Running in CPU-only mode - performance will depend on CPU strength." [ConsoleColor]::Yellow
    }

    if ($webuiMem) {
        $webuiMsg = "OpenWebUI consuming ~$([math]::Round($webuiMem,0)) MiB RAM; lightweight for chat UI."
        Write-StatusLine "OpenWebUI" $webuiMsg [ConsoleColor]::Green
    }

    if ($n8nMem) {
        $n8nMsg = "n8n consuming ~$([math]::Round($n8nMem,0)) MiB RAM; automation overhead is minimal."
        Write-StatusLine "n8n" $n8nMsg [ConsoleColor]::Green
    }

    if ($ollamaMem) {
        $ollamaMsg = "Ollama container currently using ~$([math]::Round($ollamaMem,0)) MiB RAM with cached model."
        Write-StatusLine "Ollama RAM" $ollamaMsg [ConsoleColor]::Cyan
    }

    if ($Comparison) {
        $note = "Warm requests are $($Comparison.speedupFactor)x faster than cold loads (save $([math]::Round($Comparison.timeSavedSeconds,2))s per request)."
        Write-StatusLine "Throughput" $note [ConsoleColor]::Cyan
    }

    Write-Host ""
    Write-StatusLine "Overall" "System is capable of running Ollama, OpenWebUI, and n8n together once the model is warmed up." [ConsoleColor]::Green
    Write-StatusLine "Recommendation" "Keep the model warm (scheduled health check or background job) to avoid the ~72s cold load penalty." [ConsoleColor]::Yellow
}


function Get-SystemSummary {
    $cpu = "Unknown"
    try {
        $cpuInfo = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1 -Property Name
        if ($cpuInfo -and $cpuInfo.Name) { $cpu = $cpuInfo.Name.Trim() }
    } catch {}

    $ram = "Unknown"
    try {
        $ramBytes = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum
        if ($ramBytes) { $ram = "{0} GB" -f ([math]::Round($ramBytes / 1GB, 2)) }
    } catch {}

    $gpuNames = @()
    try {
        $gpuNames = Get-CimInstance -ClassName Win32_VideoController |
            Where-Object { $_.Name -and $_.Name -notmatch "Microsoft Basic" -and $_.Name -notmatch "Remote" } |
            Select-Object -ExpandProperty Name -ErrorAction SilentlyContinue
    } catch {}
    if (-not $gpuNames -or $gpuNames.Count -eq 0) { $gpuNames = @("Unknown") }

    $gpuTool = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    $gpuActive = $false
    if ($gpuTool) {
        try {
            & nvidia-smi > $null
            if ($LASTEXITCODE -eq 0) { $gpuActive = $true }
        } catch {}
    }

    return [ordered]@{
        cpu = $cpu
        ram = $ram
        gpus = $gpuNames
        gpuToolAvailable = [bool]$gpuTool
        gpuActive = $gpuActive
    }
}

function Get-GPUStats {
    $gpuTool = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if (-not $gpuTool) { return $null }
    try {
        $gpuArgs = "--query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw", "--format=csv,noheader"
        return & nvidia-smi @gpuArgs
    } catch {
        return $null
    }
}

function Get-ContainerStats {
    if (-not $script:containerCmd) { return $null }
    try {
        return & $script:containerCmd stats --no-stream --format "{{.Name}}`t{{.CPUPerc}}`t{{.MemUsage}}" 2>$null
    } catch {
        return $null
    }
}

function Invoke-OllamaPrompt {
    param(
        [string]$Prompt,
        [hashtable]$AdditionalBody = @{}
    )

    $body = @{
        model = $Model
        prompt = $Prompt
        stream = $false
    }
    foreach ($key in $AdditionalBody.Keys) { $body[$key] = $AdditionalBody[$key] }

    $json = $body | ConvertTo-Json -Depth 10
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $response = Invoke-RestMethod -Uri "$OllamaHost/api/generate" -Method Post -Body $json -ContentType "application/json" -TimeoutSec 300
    $stopwatch.Stop()

    return [PSCustomObject]@{
        TotalSeconds = $stopwatch.Elapsed.TotalSeconds
        Response = $response
    }
}

function Stop-OllamaModel {
    param([string]$ModelName)

    $stopped = $false
    $ollamaCli = Get-Command ollama -ErrorAction SilentlyContinue
    if ($ollamaCli) {
        try {
            & $ollamaCli stop $ModelName 2>$null | Out-Null
            $stopped = $true
        } catch {}
    }

    if (-not $stopped) {
        try {
            Invoke-OllamaPrompt -Prompt "Preparing to unload" -AdditionalBody @{ keep_alive = "0s" } | Out-Null
            $stopped = $true
        } catch {}
    }

    if ($stopped) {
        Write-Host "Model unload requested" -ForegroundColor Green
        Start-Sleep -Seconds 2
    } else {
        Write-Host "Could not confirm model unload; cold start may not be accurate" -ForegroundColor Yellow
    }
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Show-Banner "Cold vs Warm Start Measurement v1.2.0"
Write-Host "Container Runtime: $($script:ContainerRuntime)" -ForegroundColor Cyan
Write-Host "Timestamp: $timestamp" -ForegroundColor Yellow
Write-Host "Model: $Model" -ForegroundColor Yellow
Write-Host ""

# ==================== PRE-FLIGHT CHECKS ====================
Write-Section "Pre-flight Checks"

# Check 1: Ollama API is accessible
Write-Host "Checking Ollama API accessibility..." -NoNewline
try {
    $tagsResponse = Invoke-RestMethod -Uri "$OllamaHost/api/tags" -Method Get -TimeoutSec 5 -ErrorAction Stop
    Write-Host " [OK]" -ForegroundColor Green
} catch {
    Write-Host " [X]" -ForegroundColor Red
    Write-Host ""
    Write-Host "ERROR: Cannot connect to Ollama at $OllamaHost" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "  1. Ensure containers are running:" -ForegroundColor White
    Write-Host "     $($script:composeCmd) ps" -ForegroundColor Gray
    Write-Host "  2. Check if Ollama container is healthy:" -ForegroundColor White
    Write-Host "     $($script:containerCmd) ps | findstr ollama" -ForegroundColor Gray
    Write-Host "  3. Check Ollama container logs:" -ForegroundColor White
    Write-Host "     $($script:containerCmd) logs ollama" -ForegroundColor Gray
    Write-Host "  4. Try restarting containers:" -ForegroundColor White
    Write-Host "     $($script:composeCmd) restart ollama" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Check 2: Model exists
Write-Host "Checking if model '$Model' is available..." -NoNewline
$modelExists = $false
try {
    $tagsResponse = Invoke-RestMethod -Uri "$OllamaHost/api/tags" -Method Get -TimeoutSec 5
    $modelExists = $tagsResponse.models | Where-Object { $_.name -eq $Model }
} catch {
    Write-Host " [X]" -ForegroundColor Red
    Write-Host ""
    Write-Host "ERROR: Could not retrieve model list from Ollama" -ForegroundColor Red
    exit 1
}

if (-not $modelExists) {
    Write-Host " [X]" -ForegroundColor Red
    Write-Host ""
    Write-Host "ERROR: Model '$Model' not found in Ollama" -ForegroundColor Red
    Write-Host ""
    Write-Host "Available models:" -ForegroundColor Yellow
    foreach ($availableModel in $tagsResponse.models) {
        Write-Host "  * $($availableModel.name)" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "To download the model:" -ForegroundColor Yellow
    Write-Host "  $($script:containerCmd) exec -it ollama ollama pull $Model" -ForegroundColor White
    Write-Host ""
    Write-Host "Or specify a different model with:" -ForegroundColor Yellow
    Write-Host "  .\scripts\measure-cold-warm-windows.ps1 -Model 'llama3.2'" -ForegroundColor White
    Write-Host ""
    exit 1
} else {
    Write-Host " [OK]" -ForegroundColor Green
}

# Check 3: Disk space
Write-Host "Checking available disk space..." -NoNewline
try {
    if ($script:ContainerRuntime -eq "podman") {
        $runtimeInfo = & $script:containerCmd info --format '{{.Store.GraphRoot}}' 2>$null
    } else {
        $runtimeInfo = & $script:containerCmd info --format '{{.DockerRootDir}}' 2>$null
    }

    if ($runtimeInfo) {
        $drive = Split-Path -Qualifier $runtimeInfo
        if ($drive) {
            $disk = Get-PSDrive -Name $drive.TrimEnd(':') -ErrorAction SilentlyContinue
            if ($disk -and $disk.Free) {
                $freeGB = [math]::Round($disk.Free / 1GB, 2)
                if ($freeGB -lt 5) {
                    Write-Host " [!] Low ($freeGB GB free)" -ForegroundColor Yellow
                } else {
                    Write-Host " [OK] ($freeGB GB free)" -ForegroundColor Green
                }
            } else {
                Write-Host " ?" -ForegroundColor Yellow
            }
        }
    }
} catch {
    Write-Host " ?" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "All pre-flight checks passed. Starting measurement..." -ForegroundColor Green
Write-Host ""

# Get system summary
$summary = Get-SystemSummary

Write-Host "System Summary:" -ForegroundColor Green
Write-Host "  CPU : $($summary.cpu)"
Write-Host "  RAM : $($summary.ram)"
Write-Host "  GPU(s): $([string]::Join(', ', $summary.gpus))"
Write-Host "  GPU Tool Available: $($summary.gpuToolAvailable)"
Write-Host "  GPU Active: $($summary.gpuActive)"
Write-Host ""

$baselineContainers = Get-ContainerStats
if ($baselineContainers) {
    Write-Host "Container Stats (Before):" -ForegroundColor Green
    $baselineContainers | ForEach-Object { Write-Host "  $_" }
    Write-Host ""
}

$baselineGPU = Get-GPUStats
if ($baselineGPU) {
    Write-Host "GPU Stats (Before):" -ForegroundColor Green
    $baselineGPU | ForEach-Object { Write-Host "  $_" }
    Write-Host ""
}

$prompt = "Explain what artificial intelligence is in 2-3 sentences."

Write-Host "Requesting cold start (unloading model)..." -ForegroundColor Yellow
Stop-OllamaModel -ModelName $Model

Write-Section "Cold Start"
Write-Host ""
Write-Host "[TIME] Cold start test may take 1-5 minutes depending on:" -ForegroundColor Yellow
Write-Host "  * Model size ($Model)" -ForegroundColor Gray
Write-Host "  * CPU/GPU performance" -ForegroundColor Gray
Write-Host "  * System memory" -ForegroundColor Gray
Write-Host ""
Write-Host "Running cold start test (loading model from disk)..." -NoNewline -ForegroundColor Cyan
try {
    $coldResult = Invoke-OllamaPrompt -Prompt $prompt
    Write-Host " Done!" -ForegroundColor Green
} catch {
    Write-Host " Failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "ERROR: Cold start test failed" -ForegroundColor Red
    Write-Host "Reason: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "This might be due to:" -ForegroundColor Yellow
    Write-Host "  * Model too large for available memory" -ForegroundColor White
    Write-Host "  * Ollama container crashed or restarted" -ForegroundColor White
    Write-Host "  * Network timeout (check -OllamaHost parameter)" -ForegroundColor White
    Write-Host ""
    exit 1
}
$coldResponse = $coldResult.Response

$coldMetrics = [ordered]@{
    totalSeconds = [math]::Round($coldResult.TotalSeconds, 2)
    loadSeconds = if ($coldResponse) { [math]::Round($coldResponse.load_duration / 1e9, 2) } else { 0 }
    promptEvalSeconds = if ($coldResponse) { [math]::Round($coldResponse.prompt_eval_duration / 1e9, 2) } else { 0 }
    inferenceSeconds = if ($coldResponse) { [math]::Round($coldResponse.eval_duration / 1e9, 2) } else { 0 }
    tokens = if ($coldResponse) { $coldResponse.eval_count } else { 0 }
    tokensPerSecond = if ($coldResult.TotalSeconds -eq 0) { 0 } else { [math]::Round($coldResponse.eval_count / $coldResult.TotalSeconds, 2) }
}

Write-Host "Cold start complete:" -ForegroundColor Green
Write-Host "  Total time: $($coldMetrics.totalSeconds) s"
Write-Host "  Load time: $($coldMetrics.loadSeconds) s"
Write-Host "  Prompt eval: $($coldMetrics.promptEvalSeconds) s"
Write-Host "  Inference: $($coldMetrics.inferenceSeconds) s"
Write-Host "  Tokens: $($coldMetrics.tokens)"
Write-Host "  Speed: $($coldMetrics.tokensPerSecond) tokens/s"
Write-Host ""

Write-Host "Waiting $SettleSeconds second(s) before warm tests..." -ForegroundColor Yellow
Start-Sleep -Seconds $SettleSeconds
Write-Section "Warm Start"
$warmHeader = "Running warm start tests ($WarmRuns runs)..."
Write-Host $warmHeader -ForegroundColor Cyan
$warmTimes = @()
$warmLoad = @()
$warmPrompt = @()
$warmEval = @()
$warmTokens = @()

for ($i = 1; $i -le $WarmRuns; $i++) {
    Write-Host "  Warm run $i..." -NoNewline
    try {
        $warmResult = Invoke-OllamaPrompt -Prompt $prompt
        $warmResponse = $warmResult.Response
        $warmTimes += $warmResult.TotalSeconds
        $warmLoad += ($warmResponse.load_duration / 1e9)
        $warmPrompt += ($warmResponse.prompt_eval_duration / 1e9)
        $warmEval += ($warmResponse.eval_duration / 1e9)
        $warmTokens += $warmResponse.eval_count
        Write-Host " $([math]::Round($warmResult.TotalSeconds, 2)) s" -ForegroundColor Green
    } catch {
        Write-Host " failed" -ForegroundColor Red
    }
    Start-Sleep -Seconds 1
}

$warmMetrics = $null
if ($warmTimes.Count -gt 0) {
    $warmMetrics = [ordered]@{
        runs = $warmTimes.Count
        avgSeconds = [math]::Round((($warmTimes | Measure-Object -Average).Average), 2)
        minSeconds = [math]::Round((($warmTimes | Measure-Object -Minimum).Minimum), 2)
        maxSeconds = [math]::Round((($warmTimes | Measure-Object -Maximum).Maximum), 2)
        avgLoadSeconds = [math]::Round((($warmLoad | Measure-Object -Average).Average), 3)
        avgPromptEvalSeconds = [math]::Round((($warmPrompt | Measure-Object -Average).Average), 2)
        avgInferenceSeconds = [math]::Round((($warmEval | Measure-Object -Average).Average), 2)
        avgTokens = [math]::Round((($warmTokens | Measure-Object -Average).Average), 0)
        avgTokensPerSecond = [math]::Round((($warmTokens | Measure-Object -Average).Average) / ((($warmTimes | Measure-Object -Average).Average)), 2)
    }

    Write-Host "Warm start summary:" -ForegroundColor Green
    Write-Host "  Average time: $($warmMetrics.avgSeconds) s"
    Write-Host "  Min/Max time: $($warmMetrics.minSeconds)s / $($warmMetrics.maxSeconds)s"
    Write-Host "  Load time (cached): $($warmMetrics.avgLoadSeconds) s"
    Write-Host "  Prompt eval: $($warmMetrics.avgPromptEvalSeconds) s"
    Write-Host "  Inference: $($warmMetrics.avgInferenceSeconds) s"
    Write-Host "  Tokens: $($warmMetrics.avgTokens)"
    Write-Host "  Speed: $($warmMetrics.avgTokensPerSecond) tokens/s"
    Write-Host ""
} else {
    Write-Host "No successful warm runs." -ForegroundColor Red
}

$containerAfter = Get-ContainerStats
if ($containerAfter) {
    Write-Host "Container Stats (After):" -ForegroundColor Green
    $containerAfter | ForEach-Object { Write-Host "  $_" }
    Write-Host ""
}

$gpuAfter = Get-GPUStats
if ($gpuAfter) {
    Write-Host "GPU Stats (After):" -ForegroundColor Green
    $gpuAfter | ForEach-Object { Write-Host "  $_" }
    Write-Host ""
}

$comparison = $null
if ($warmMetrics) {
    $comparison = [ordered]@{
        coldTotalSeconds = $coldMetrics.totalSeconds
        warmAvgSeconds = $warmMetrics.avgSeconds
        speedupFactor = if ($warmMetrics.avgSeconds -ne 0) { [math]::Round($coldMetrics.totalSeconds / $warmMetrics.avgSeconds, 2) } else { 0 }
        timeSavedSeconds = [math]::Round($coldMetrics.totalSeconds - $warmMetrics.avgSeconds, 2)
        loadTimeSavedSeconds = [math]::Round($coldMetrics.loadSeconds - $warmMetrics.avgLoadSeconds, 2)
    }

    Write-Host "Cold vs Warm Comparison:" -ForegroundColor Cyan
    Write-Host "  Cold total: $($comparison.coldTotalSeconds) s"
    Write-Host "  Warm average: $($comparison.warmAvgSeconds) s"
    Write-Host "  Time saved: $($comparison.timeSavedSeconds) s"
    Write-Host "  Speedup: $($comparison.speedupFactor)x"
    Write-Host "  Load time saved: $($comparison.loadTimeSavedSeconds) s"
}

Write-CapabilitySummary -System $summary -ColdMetrics $coldMetrics -WarmMetrics $warmMetrics -Comparison $comparison -ContainerStatsAfter $containerAfter

$export = [ordered]@{
    timestamp = $timestamp
    model = $Model
    prompt = $prompt
    warmRuns = $WarmRuns
    settleSeconds = $SettleSeconds
    system = $summary
    coldStart = $coldMetrics
    warmStart = $warmMetrics
    comparison = $comparison
    containerStatsBefore = $baselineContainers
    containerStatsAfter = $containerAfter
    gpuStatsBefore = $baselineGPU
    gpuStatsAfter = $gpuAfter
}

# Persist results under repo-level artifacts/performance (gitignored)
$repoRoot = try { (Resolve-Path (Join-Path $PSScriptRoot '..')).Path } catch { (Get-Location).Path }
$outDir = Join-Path $repoRoot 'artifacts\performance'
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}
$outputPath = Join-Path $outDir ("performance-cold-warm-{0}.json" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
($export | ConvertTo-Json -Depth 10) | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "Results saved to $outputPath" -ForegroundColor Green

