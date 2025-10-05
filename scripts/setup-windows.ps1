<#
.SYNOPSIS
    n8n Workshop - Automated Setup Script

.DESCRIPTION
    Automated setup for n8n workshop Docker stack including Ollama, OpenWebUI, n8n, and PostgreSQL.
    Includes idempotency checks, health validation, and comprehensive error handling.

.PARAMETER WhatIf
    Shows what would happen without making changes (not yet implemented)

.EXAMPLE
    .\setup-windows.ps1
    Run the standard setup process

.EXAMPLE
    $env:ENABLE_LOGGING="1"
    .\setup-windows.ps1
    Run setup with detailed logging enabled

.NOTES
    Version: 1.1.1
    Last Updated: 2025-10-05
    Workshop: Go to Agentic Conference 2025
    Requires: Docker Desktop for Windows, WSL2
#>

# n8n Workshop - Automated Setup Script
# Version: 1.1.1
# Last Updated: 2025-10-05
# Workshop: Go to Agentic Conference 2025

# Optional logging (set $env:ENABLE_LOGGING="1" to enable)
if ($env:ENABLE_LOGGING -eq "1") {
    $logFile = "setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    Start-Transcript -Path $logFile
    Write-Host "Logging enabled. Transcript will be saved to: $logFile" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   n8n Workshop - Automated Setup Script v1.1.1" -ForegroundColor White
Write-Host "   Go to Agentic Conference 2025" -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if a command exists
function Test-CommandExists {
    param($command)
    $null = Get-Command $command -ErrorAction SilentlyContinue
    return $?
}

# Function to display status
function Write-Status {
    param(
        [string]$Message,
        [string]$Status = "INFO"
    )

    $color = switch ($Status) {
        "SUCCESS" { "Green" }
        "ERROR"   { "Red" }
        "WARNING" { "Yellow" }
        default   { "Cyan" }
    }

    $symbol = switch ($Status) {
        "SUCCESS" { "[OK]" }
        "ERROR"   { "[X]" }
        "WARNING" { "[!]" }
        default   { "[i]" }
    }

    Write-Host "  $symbol " -ForegroundColor $color -NoNewline
    Write-Host $Message -ForegroundColor White
}

# Helper to run Docker Compose (supports v1 'docker-compose' and v2 'docker compose')
function Invoke-Compose {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )
    if (Test-CommandExists docker-compose) {
        & docker-compose @Args
    } else {
        & docker compose @Args
    }
}

# Function to wait for container health
function Wait-ContainerHealth {
    param(
        [string]$ContainerName,
        [int]$TimeoutSeconds = 90
    )

    Write-Host "  Waiting for $ContainerName to be ready (max ${TimeoutSeconds}s)..." -NoNewline
    $elapsed = 0
    $interval = 2

    while ($elapsed -lt $TimeoutSeconds) {
        $health = docker inspect --format='{{.State.Health.Status}}' $ContainerName 2>$null
        $running = docker inspect --format='{{.State.Running}}' $ContainerName 2>$null
        
        # Container is healthy
        if ($health -eq "healthy") {
            Write-Host " [OK]" -ForegroundColor Green
            return $true
        }
        
        # Container is running without healthcheck
        if ($running -eq "true" -and !$health) {
            Write-Host " [OK] (running)" -ForegroundColor Green
            return $true
        }
        
        # For Ollama specifically, check if it's actually responding even if healthcheck is slow
        if ($ContainerName -eq "ollama" -and $running -eq "true") {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:11434/" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    Write-Host " [OK] (responding)" -ForegroundColor Green
                    return $true
                }
            } catch {
                # Continue waiting
            }
        }

        Start-Sleep -Seconds $interval
        $elapsed += $interval

        # Progress indicator every 10 seconds
        if ($elapsed % 10 -eq 0) {
            Write-Host "." -NoNewline
        }
    }

    # Final check - if container is running, consider it OK even if healthcheck failed
    if ($running -eq "true") {
        Write-Host " [OK] (running, healthcheck pending)" -ForegroundColor Yellow
        return $true
    }

    Write-Host " [X] (timeout)" -ForegroundColor Red
    return $false
}

# Check prerequisites
Write-Host ""
Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  CHECKING PREREQUISITES" -ForegroundColor Cyan
Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# Check Docker
if (Test-CommandExists docker) {
    $dockerVersion = docker --version
    Write-Status "Docker is installed: $dockerVersion" "SUCCESS"
} else {
    Write-Status "Docker is not installed!" "ERROR"
    Write-Host ""
    Write-Host "  >> Installation Instructions:" -ForegroundColor Yellow
    Write-Host "     1. Download Docker Desktop:" -ForegroundColor White
    Write-Host "        https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
    Write-Host "     2. Install and restart your computer" -ForegroundColor White
    Write-Host "     3. Ensure WSL2 is enabled:" -ForegroundColor White
    Write-Host "        wsl --install" -ForegroundColor Cyan
    Write-Host "     4. IMPORTANT: After installation, you MUST:" -ForegroundColor Yellow
    Write-Host "        - Open Docker Desktop from the Start Menu" -ForegroundColor White
    Write-Host "        - Log in to Docker Desktop (or skip login if prompted)" -ForegroundColor White
    Write-Host "        - Wait for Docker Desktop to fully start (icon in system tray)" -ForegroundColor White
    Write-Host "        - Ensure Docker Desktop shows 'Engine running' status" -ForegroundColor White
    Write-Host "     5. Run this script again after Docker Desktop is fully running" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Check Docker daemon is running and healthy
try {
    docker ps | Out-Null
    Write-Status "Docker daemon is running" "SUCCESS"
} catch {
    Write-Status "Docker daemon is not running!" "ERROR"
    Write-Host ""
    Write-Host "  >> Troubleshooting Steps:" -ForegroundColor Yellow
    Write-Host "     1. Open Docker Desktop from Windows Start Menu" -ForegroundColor White
    Write-Host "     2. IMPORTANT: Log in to Docker Desktop (or skip login if prompted)" -ForegroundColor Yellow
    Write-Host "        - Docker Desktop requires you to be logged in or skip the login prompt" -ForegroundColor White
    Write-Host "        - Wait for Docker Desktop to fully initialize (30-60 seconds)" -ForegroundColor White
    Write-Host "     3. Verify Docker Desktop status:" -ForegroundColor White
    Write-Host "        - Look for Docker icon in system tray (whale icon)" -ForegroundColor White
    Write-Host "        - Icon should show 'Engine running' when you hover over it" -ForegroundColor White
    Write-Host "        - Open Docker Desktop and ensure no error messages appear" -ForegroundColor White
    Write-Host "     4. If WSL2 errors appear, run:" -ForegroundColor White
    Write-Host "        wsl --update" -ForegroundColor Cyan
    Write-Host "     5. Run this script again after Docker Desktop is fully running" -ForegroundColor White
    Write-Host ""
    Write-Host "  >> Common Error: '500 Internal Server Error for API route'" -ForegroundColor Red
    Write-Host "     This usually means Docker Desktop is installed but not logged in or not fully started." -ForegroundColor White
    Write-Host "     Solution: Open Docker Desktop, complete login/skip, and wait for it to fully start." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Additional Docker health check - verify daemon is responsive
try {
    $dockerInfo = docker info --format '{{.ServerVersion}}' 2>$null
    if ($dockerInfo) {
        Write-Status "Docker daemon is responsive (version: $dockerInfo)" "SUCCESS"
    } else {
        Write-Status "Docker daemon is slow to respond. Waiting 10 seconds..." "WARNING"
        Start-Sleep -Seconds 10
        $dockerInfo = docker info --format '{{.ServerVersion}}' 2>$null
        if (-not $dockerInfo) {
            Write-Status "Docker daemon not fully initialized. Please wait and retry." "ERROR"
            exit 1
        }
    }
} catch {
    Write-Status "Could not verify Docker daemon health." "WARNING"
}

# Check Docker Compose
if (Test-CommandExists docker-compose) {
    $composeVersion = docker-compose --version
    Write-Status "Docker Compose is installed: $composeVersion" "SUCCESS"
} elseif (Test-CommandExists docker) {
    try {
        docker compose version | Out-Null
        Write-Status "Docker Compose V2 is available" "SUCCESS"
    } catch {
        Write-Status "Docker Compose (v1 or v2) is not available!" "ERROR"
        Write-Host ""
        Write-Host "  >> Docker Compose should be included with Docker Desktop." -ForegroundColor Yellow
        Write-Host "     Try reinstalling Docker Desktop." -ForegroundColor White
        Write-Host ""
        exit 1
    }
} else {
    Write-Status "Docker is not available!" "ERROR"
    exit 1
}

Write-Host ""
Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# Check if .env exists, if not create from example
if (-Not (Test-Path ".env")) {
    if (Test-Path "configs\.env.example") {
        Write-Status "Creating .env file from template..." "INFO"
        Copy-Item "configs\.env.example" ".env"
        Write-Status ".env file created. Edit as needed for Google API credentials." "WARNING"
    } else {
        Write-Status "No .env.example found. Continuing without environment file." "WARNING"
    }
} else {
    Write-Status ".env file already exists (skipping)" "SUCCESS"
}

# Copy docker-compose.yml if needed
if (-Not (Test-Path "docker-compose.yml")) {
    if (Test-Path "configs\docker-compose.yml") {
        Write-Status "Copying docker-compose.yml to root directory..." "INFO"
        Copy-Item "configs\docker-compose.yml" "docker-compose.yml"
        Write-Status "docker-compose.yml copied" "SUCCESS"
    } else {
        Write-Status "docker-compose.yml not found in configs!" "ERROR"
        Write-Host ""
        Write-Host "  >> Are you running this script from the repository root?" -ForegroundColor Yellow
        Write-Host "    Current directory: $(Get-Location)" -ForegroundColor White
        Write-Host ""
        exit 1
    }
} else {
    Write-Status "docker-compose.yml already exists (skipping)" "SUCCESS"
}

Write-Host ""

# GPU detection
$composeArgs = @('-f', 'docker-compose.yml')
$gpuOverridePath = 'configs\docker-compose.gpu.yml'
try {
    $nvsmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if ($nvsmi) {
        & nvidia-smi > $null 2>&1
        if ($LASTEXITCODE -eq 0 -and (Test-Path $gpuOverridePath)) {
            Write-Status "NVIDIA GPU detected. Enabling GPU acceleration." "INFO"
            $composeArgs += @('-f', $gpuOverridePath)
        } else {
            Write-Status "NVIDIA GPU not available or override file missing. Using CPU-only mode." "WARNING"
        }
    } else {
        Write-Status "No NVIDIA GPU detected. Using CPU-only mode." "INFO"
    }
} catch {
    Write-Status "GPU detection failed. Using CPU-only mode." "WARNING"
}

# Check if containers are already running (idempotency)
Write-Host ""
Write-Status "Checking for existing containers..." "INFO"
$existingContainers = @()
$requiredContainers = @("ollama", "n8n", "open-webui", "postgres")

foreach ($containerName in $requiredContainers) {
    $running = docker ps --filter "name=$containerName" --format "{{.Names}}" 2>$null | Select-String -Pattern "^$containerName$" -Quiet
    if ($running) {
        $existingContainers += $containerName
    }
}

if ($existingContainers.Count -gt 0) {
    Write-Status "Found running containers: $($existingContainers -join ', ')" "SUCCESS"
    Write-Host ""
    Write-Host "  >> Containers are already running. Options:" -ForegroundColor Yellow
    Write-Host "     * Continue to use existing containers (recommended)" -ForegroundColor White
    Write-Host "     * Restart containers to apply configuration changes" -ForegroundColor White
    Write-Host ""

    $restart = Read-Host "Restart containers? (y/N)"

    if ($restart -eq "y" -or $restart -eq "Y") {
        Write-Status "Restarting containers..." "INFO"
        try {
            Invoke-Compose @composeArgs restart 2>&1 | Out-Null
            Write-Status "Containers restarted successfully!" "SUCCESS"
        } catch {
            Write-Status "Failed to restart containers." "ERROR"
            Write-Host ""
            Write-Host "  >> Troubleshooting Steps:" -ForegroundColor Yellow
            Write-Host "     1. Check logs:" -ForegroundColor White
            Write-Host "        docker-compose logs -f" -ForegroundColor Cyan
            Write-Host "     2. Stop and start manually:" -ForegroundColor White
            Write-Host "        docker-compose down" -ForegroundColor Cyan
            Write-Host "        docker-compose up -d" -ForegroundColor Cyan
            Write-Host ""
            exit 1
        }
    } else {
        Write-Status "Using existing containers (no changes made)" "INFO"
    }
} else {
    # Start containers
    Write-Status "Starting Docker containers..." "INFO"
    Write-Host ""
    Write-Host "  >> IMPORTANT: First-time setup will download Docker images" -ForegroundColor Yellow
    Write-Host "     - Total download size: ~4-5 GB (ollama, n8n, open-webui, postgres)" -ForegroundColor White
    Write-Host "     - Download time: 5-15 minutes depending on your internet speed" -ForegroundColor White
    Write-Host "     - After download completes, Docker will VERIFY/EXTRACT the images" -ForegroundColor Cyan
    Write-Host "     - Verification may take 1-3 minutes and will show 'Pulling' status" -ForegroundColor Cyan
    Write-Host "     - This is normal - please be patient while images are verified!" -ForegroundColor Yellow
    Write-Host ""

    try {
        # Start containers in detached mode (suppress container logs, only show creation status)
        Write-Host "  Creating and starting containers..." -ForegroundColor Cyan
        $startTime = Get-Date
        
        # Use --detach explicitly and redirect to capture only status messages
        # The --quiet-pull flag suppresses pull output after first time
        $ErrorActionPreference = 'Continue'
        $output = Invoke-Compose @composeArgs up --detach --quiet-pull 2>&1 | Out-String
        $ErrorActionPreference = 'Stop'
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host $output
            throw "docker-compose up failed with exit code $LASTEXITCODE"
        }
        
        # Show only the summary lines (Running X/Y, Container created/started)
        # Filter out "Attaching to" and container log lines
        $output -split "`n" | Where-Object { 
            $_ -notmatch '^(Attaching to|.*\s+\|)' -and 
            $_ -match '^\[.*\]|^✔|^\s*✔|Container.*|Network.*|Volume.*' -and
            $_.Trim() -ne ''
        } | ForEach-Object { 
            Write-Host "  $_" -ForegroundColor Gray
        }
        
        $elapsed = ((Get-Date) - $startTime).TotalSeconds
        Write-Host ""
        Write-Status "Containers started successfully in $([math]::Round($elapsed, 1))s" "SUCCESS"
        Write-Host "  >> Containers are running in the background" -ForegroundColor Cyan
        Write-Host "     To view logs: docker-compose logs -f" -ForegroundColor DarkGray
    } catch {
        Write-Status "Failed to start containers." "ERROR"
        Write-Host ""
        Write-Host "  >> Troubleshooting Steps:" -ForegroundColor Yellow
        Write-Host "     1. Check logs:" -ForegroundColor White
        Write-Host "        docker-compose logs -f" -ForegroundColor Cyan
        Write-Host "     2. Check for port conflicts:" -ForegroundColor White
        Write-Host "        netstat -ano | findstr `":5678 :3000 :11434 :5432`"" -ForegroundColor Cyan
        Write-Host "     3. Verify WSL2 is running:" -ForegroundColor White
        Write-Host "        wsl --status" -ForegroundColor Cyan
        Write-Host "     4. Restart Docker Desktop and retry this script" -ForegroundColor White
        Write-Host "     5. Check disk space:" -ForegroundColor White
        Write-Host "        docker system df" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  >> Full error message:" -ForegroundColor Red
        Write-Host "     $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        exit 1
    }

    # Wait for container health
    Write-Host ""
    Write-Status "Waiting for services to be ready..." "INFO"

    $healthyContainers = @()
    $unhealthyContainers = @()

    foreach ($containerName in $requiredContainers) {
        if (Wait-ContainerHealth -ContainerName $containerName -TimeoutSeconds 90) {
            $healthyContainers += $containerName
        } else {
            $unhealthyContainers += $containerName
        }
    }

    Write-Host ""
    if ($unhealthyContainers.Count -gt 0) {
        Write-Status "Note: Some containers are still initializing: $($unhealthyContainers -join ', ')" "WARNING"
        Write-Host "  >> This is usually fine - containers may take extra time to fully start" -ForegroundColor Cyan
        Write-Host "  >> Verify status with: docker-compose ps" -ForegroundColor DarkGray
    } else {
        Write-Status "All containers are ready!" "SUCCESS"
    }
}

# Check container status
Write-Host ""
Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  CONTAINER STATUS" -ForegroundColor Cyan
Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Invoke-Compose ps

Write-Host ""
Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# Download Ollama model (with idempotency check)
Write-Host "  >> Would you like to download an Ollama model? (Y/N)" -ForegroundColor Yellow
$downloadModel = Read-Host

if ($downloadModel -eq "Y" -or $downloadModel -eq "y") {
    Write-Host ""

    # First, check existing models
    Write-Status "Checking for existing Ollama models..." "INFO"
    try {
        $existingModels = docker exec ollama ollama list 2>$null
        if ($existingModels) {
            Write-Host ""
            Write-Host "Currently installed models:" -ForegroundColor Cyan
            Write-Host $existingModels
            Write-Host ""
        }
    } catch {
        Write-Status "Could not check existing models (Ollama may still be starting)" "WARNING"
    }

    Write-Host "  >> Select a model to download:" -ForegroundColor Yellow
    Write-Host "     1. llama3.2:1b  (1GB)  - Fast, recommended for testing" -ForegroundColor White
    Write-Host "     2. llama3.2     (4GB)  - Balanced, recommended for workshop" -ForegroundColor White
    Write-Host "     3. mistral      (4GB)  - Good for coding tasks" -ForegroundColor White
    Write-Host "     4. Skip for now" -ForegroundColor DarkGray
    Write-Host ""

    $modelChoice = Read-Host "Enter choice (1-4)"

    $model = switch ($modelChoice) {
        "1" { "llama3.2:1b" }
        "2" { "llama3.2" }
        "3" { "mistral" }
        default { $null }
    }

    if ($model) {
        # Check if model already exists
        $modelExists = $false
        try {
            $existingModels = docker exec ollama ollama list 2>$null
            if ($existingModels -match [regex]::Escape($model)) {
                $modelExists = $true
            }
        } catch {
            # Ollama might not be ready yet
        }

        if ($modelExists) {
            Write-Status "Model '$model' is already downloaded. Skipping." "SUCCESS"
        } else {
            Write-Host ""
            Write-Status "Downloading '$model'... This may take 2-10 minutes depending on your connection." "INFO"
            Write-Host "  >> Model size and download time varies. Please be patient..." -ForegroundColor Yellow
            Write-Host ""

            try {
                docker exec -it ollama ollama pull $model
                if ($LASTEXITCODE -eq 0) {
                    Write-Host ""
                    Write-Status "Model '$model' downloaded successfully!" "SUCCESS"
                } else {
                    Write-Host ""
                    Write-Status "Model download may have failed (exit code: $LASTEXITCODE)" "WARNING"
                    Write-Host ""
                    Write-Host "  >> Verify download with:" -ForegroundColor Yellow
                    Write-Host "     docker exec -it ollama ollama list" -ForegroundColor Cyan
                    Write-Host "  >> Retry download with:" -ForegroundColor Yellow
                    Write-Host "     docker exec -it ollama ollama pull $model" -ForegroundColor Cyan
                }
            } catch {
                Write-Host ""
                Write-Status "Failed to download model." "ERROR"
                Write-Host ""
                Write-Host "  >> Troubleshooting:" -ForegroundColor Yellow
                Write-Host "     * Check internet connection" -ForegroundColor White
                Write-Host "     * Verify Ollama container is running:" -ForegroundColor White
                Write-Host "       docker ps | findstr ollama" -ForegroundColor Cyan
                Write-Host "     * Check Ollama logs:" -ForegroundColor White
                Write-Host "       docker logs ollama" -ForegroundColor Cyan
                Write-Host "     * Retry manually:" -ForegroundColor White
                Write-Host "       docker exec -it ollama ollama pull $model" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  >> You can continue and download models later." -ForegroundColor Cyan
            }
        }
    }
}

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "                    SETUP SUMMARY" -ForegroundColor White
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""

# Summary of what was accomplished
Write-Host "  [COMPLETED]" -ForegroundColor Green
Write-Host "     * Docker verified and running" -ForegroundColor White
Write-Host "     * Configuration files prepared (.env, docker-compose.yml)" -ForegroundColor White
Write-Host "     * Containers started: ollama, n8n, open-webui, postgres" -ForegroundColor White

$modelCount = 0
try {
    $modelList = docker exec ollama ollama list 2>$null
    if ($modelList) {
        $modelCount = ($modelList | Select-String -Pattern ":" -AllMatches).Count
    }
} catch {}

if ($modelCount -gt 0) {
    Write-Host "     * Ollama models installed: $modelCount" -ForegroundColor White
} else {
    Write-Host "     * Ollama models: none (download later)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  [ACCESS YOUR SERVICES]" -ForegroundColor Cyan
Write-Host "     * OpenWebUI:  http://localhost:3000  (Chat with LLMs)" -ForegroundColor White
Write-Host "     * n8n:        http://localhost:5678  (Build workflows)" -ForegroundColor White
Write-Host "     * Ollama API: http://localhost:11434 (LLM API endpoint)" -ForegroundColor White
Write-Host ""
Write-Host "  [NEXT STEPS]" -ForegroundColor Yellow
Write-Host "     1. Verify installation: .\scripts\verify-windows.ps1" -ForegroundColor White
Write-Host "     2. Open OpenWebUI (http://localhost:3000) and create an account" -ForegroundColor White
Write-Host "     3. Open n8n (http://localhost:5678) and set up credentials" -ForegroundColor White
Write-Host "     4. Import sample workflows from .\workflows\" -ForegroundColor White
Write-Host ""
Write-Host "  [DOCUMENTATION]" -ForegroundColor Cyan
Write-Host "     * Quick Start:     docs\QUICK_START.md" -ForegroundColor White
Write-Host "     * Configuration:   docs\CONFIGURATION.md" -ForegroundColor White
Write-Host "     * Troubleshooting: docs\TROUBLESHOOTING.md" -ForegroundColor White
Write-Host "     * Workflows:       workflows\README.md" -ForegroundColor White
Write-Host ""
Write-Host "  >> Happy building!" -ForegroundColor Green
Write-Host ""

# Stop transcript if logging was enabled
if ($env:ENABLE_LOGGING -eq "1") {
    Stop-Transcript
    Write-Host "Log saved to: $logFile" -ForegroundColor Cyan
}
