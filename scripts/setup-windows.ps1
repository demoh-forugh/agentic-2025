<#
.SYNOPSIS
    n8n Workshop - Automated Setup Script

.DESCRIPTION
    Automated setup for n8n workshop container stack including Ollama, OpenWebUI, n8n, and PostgreSQL.
    Supports both Docker and Podman container runtimes.
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
    Version: 1.4.0
    Last Updated: 2025-10-11
    Workshop: Go to Agentic Conference 2025
    Requires: Docker Desktop (or Podman) for Windows, WSL2
#>

# n8n Workshop - Automated Setup Script
# Version: 1.4.0
# Last Updated: 2025-10-11
# Workshop: Go to Agentic Conference 2025
# Supports: Docker Desktop, Podman (with automatic machine setup and GPU auto-configuration)

# Optional logging (set $env:ENABLE_LOGGING="1" to enable)
if ($env:ENABLE_LOGGING -eq "1") {
    $logFile = "setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    Start-Transcript -Path $logFile
    Write-Host "Logging enabled. Transcript will be saved to: $logFile" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   n8n Workshop - Automated Setup Script v1.4.0" -ForegroundColor White
Write-Host "   Go to Agentic Conference 2025" -ForegroundColor Yellow
Write-Host "   Supports: Docker & Podman (with GPU auto-config)" -ForegroundColor DarkCyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# Global variables to track which container runtime is being used
$script:ContainerRuntime = $null
$script:containerCmd = $null
$script:composeCmd = $null

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
        "DEFAULT" { "[i]" }
    }

    Write-Host "  $symbol " -ForegroundColor $color -NoNewline
    Write-Host $Message -ForegroundColor White
}

# Helper to run Docker/Podman Compose (supports v1 'docker-compose' and v2 'docker compose' or 'podman-compose')
function Invoke-Compose {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    if ($script:ContainerRuntime -eq "podman") {
        if (Test-CommandExists podman-compose) {
            & podman-compose @Args
        } else {
            & podman compose @Args
        }
    } else {
        if (Test-CommandExists docker-compose) {
            & docker-compose @Args
        } else {
            & docker compose @Args
        }
    }
}

# Function to detect system specifications
function Get-SystemSpecs {
    $specs = @{
        TotalRAM = 0
        AvailableRAM = 0
        CPUCores = 0
        HasGPU = $false
        GPUName = ""
        RecommendedModel = ""
        RecommendedChoice = 1
    }

    # Detect RAM (in GB)
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os) {
            $specs.TotalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
            $specs.AvailableRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
        }
    } catch {
        # Fallback: try WMI
        try {
            $cs = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
            if ($cs) {
                $specs.TotalRAM = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
            }
        } catch {
            # Could not detect RAM
        }
    }

    # Detect CPU cores
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue
        if ($cpu) {
            $specs.CPUCores = $cpu.NumberOfLogicalProcessors
        }
    } catch {
        # Fallback
        $specs.CPUCores = $env:NUMBER_OF_PROCESSORS
    }

    # Detect GPU
    try {
        $nvsmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
        if ($nvsmi) {
            $gpuOutput = & nvidia-smi --query-gpu=name --format=csv,noheader 2>$null
            if ($LASTEXITCODE -eq 0 -and $gpuOutput) {
                $specs.HasGPU = $true
                $specs.GPUName = $gpuOutput.Trim()
            }
        }
    } catch {
        # No GPU detected
    }

    # Recommend model based on specs
    if ($specs.TotalRAM -lt 6) {
        $specs.RecommendedModel = "llama3.2:1b"
        $specs.RecommendedChoice = 1
    } elseif ($specs.TotalRAM -lt 10) {
        if ($specs.HasGPU) {
            $specs.RecommendedModel = "llama3.2:1b or llama3.2"
            $specs.RecommendedChoice = 2
        } else {
            $specs.RecommendedModel = "llama3.2:1b"
            $specs.RecommendedChoice = 1
        }
    } else {
        # 10GB+ RAM
        if ($specs.HasGPU) {
            $specs.RecommendedModel = "llama3.2 or mistral"
            $specs.RecommendedChoice = 2
        } else {
            $specs.RecommendedModel = "llama3.2"
            $specs.RecommendedChoice = 2
        }
    }

    return $specs
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
        $health = & $script:containerCmd inspect --format='{{.State.Health.Status}}' $ContainerName 2>$null
        $running = & $script:containerCmd inspect --format='{{.State.Running}}' $ContainerName 2>$null
        
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

# Check for Docker or Podman
$dockerInstalled = Test-CommandExists docker
$podmanInstalled = Test-CommandExists podman

if ($dockerInstalled) {
    $dockerVersion = docker --version
    Write-Status "Docker is installed: $dockerVersion" "SUCCESS"
    $script:ContainerRuntime = "docker"
    $script:containerCmd = "docker"
} elseif ($podmanInstalled) {
    $podmanVersion = podman --version
    Write-Status "Podman is installed: $podmanVersion" "SUCCESS"
    $script:ContainerRuntime = "podman"
    $script:containerCmd = "podman"
} else {
    Write-Status "Neither Docker nor Podman is installed!" "ERROR"
    Write-Host ""
    Write-Host "  >> Installation Options:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  OPTION 1: Docker Desktop (Recommended for beginners)" -ForegroundColor Cyan
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
    Write-Host ""
    Write-Host "  OPTION 2: Podman (Open-source alternative)" -ForegroundColor Cyan
    Write-Host "     1. Download Podman for Windows:" -ForegroundColor White
    Write-Host "        https://podman.io/getting-started/installation" -ForegroundColor Cyan
    Write-Host "     2. Install and initialize Podman machine:" -ForegroundColor White
    Write-Host "        podman machine init" -ForegroundColor Cyan
    Write-Host "        podman machine start" -ForegroundColor Cyan
    Write-Host "     3. Install podman-compose:" -ForegroundColor White
    Write-Host "        pip install podman-compose" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  >> Run this script again after installation is complete" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# If using Podman, ensure machine is initialized and running
if ($script:ContainerRuntime -eq "podman") {
    Write-Host ""
    Write-Status "Checking Podman machine status..." "INFO"

    # Check if any Podman machines exist
    $machineList = & podman machine list --format "{{.Name}}" 2>$null

    if (-not $machineList -or $machineList.Trim() -eq "") {
        Write-Status "No Podman machine found. Initializing..." "WARNING"
        Write-Host ""
        Write-Host "  >> First-time Podman setup - this will take 1-2 minutes" -ForegroundColor Yellow
        Write-Host "     - Downloading Podman machine OS image" -ForegroundColor White
        Write-Host "     - Creating WSL2 virtual machine" -ForegroundColor White
        Write-Host ""

        try {
            & podman machine init 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Status "Podman machine initialized successfully" "SUCCESS"
            } else {
                Write-Status "Podman machine initialization completed with warnings" "WARNING"
            }
        } catch {
            Write-Status "Failed to initialize Podman machine" "ERROR"
            Write-Host ""
            Write-Host "  >> Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "  >> Please run manually: podman machine init" -ForegroundColor Yellow
            Write-Host ""
            exit 1
        }
    } else {
        Write-Status "Podman machine exists" "SUCCESS"
    }

    # Check if machine is running
    $machineRunning = & podman machine list --format "{{.Running}}" 2>$null | Select-String -Pattern "true" -Quiet

    if (-not $machineRunning) {
        Write-Status "Podman machine is not running. Starting..." "WARNING"
        Write-Host ""
        Write-Host "  >> Starting Podman machine (this may take 10-30 seconds)" -ForegroundColor Yellow
        Write-Host ""

        try {
            & podman machine start 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Status "Podman machine started successfully" "SUCCESS"
                # Give it a moment to fully initialize
                Start-Sleep -Seconds 3
            } else {
                Write-Status "Podman machine start completed with warnings" "WARNING"
            }
        } catch {
            Write-Status "Failed to start Podman machine" "ERROR"
            Write-Host ""
            Write-Host "  >> Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "  >> Please run manually: podman machine start" -ForegroundColor Yellow
            Write-Host ""
            exit 1
        }
    } else {
        Write-Status "Podman machine is already running" "SUCCESS"
    }
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

# Check container daemon is running and healthy
try {
    & $script:containerCmd ps | Out-Null
    Write-Status "$($script:ContainerRuntime) is running" "SUCCESS"
} catch {
    Write-Status "$($script:ContainerRuntime) is not running!" "ERROR"
    Write-Host ""
    if ($script:ContainerRuntime -eq "podman") {
        Write-Host "  >> Troubleshooting Steps for Podman:" -ForegroundColor Yellow
        Write-Host "     1. Check Podman machine status:" -ForegroundColor White
        Write-Host "        podman machine list" -ForegroundColor Cyan
        Write-Host "     2. Check Podman machine logs:" -ForegroundColor White
        Write-Host "        podman machine inspect" -ForegroundColor Cyan
        Write-Host "     3. Try restarting the Podman machine:" -ForegroundColor White
        Write-Host "        podman machine stop" -ForegroundColor Cyan
        Write-Host "        podman machine start" -ForegroundColor Cyan
        Write-Host "     4. If issues persist, try recreating the machine:" -ForegroundColor White
        Write-Host "        podman machine rm" -ForegroundColor Cyan
        Write-Host "        podman machine init" -ForegroundColor Cyan
        Write-Host "        podman machine start" -ForegroundColor Cyan
    } else {
        Write-Host "  >> Troubleshooting Steps for Docker:" -ForegroundColor Yellow
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
    }
    Write-Host ""
    exit 1
}

# Additional health check - verify daemon is responsive
try {
    if ($script:ContainerRuntime -eq "podman") {
        $runtimeInfo = & $script:containerCmd info --format '{{.Version.Version}}' 2>$null
    } else {
        $runtimeInfo = & $script:containerCmd info --format '{{.ServerVersion}}' 2>$null
    }

    if ($runtimeInfo) {
        Write-Status "$($script:ContainerRuntime) is responsive (version: $runtimeInfo)" "SUCCESS"
    } else {
        Write-Status "$($script:ContainerRuntime) is slow to respond. Waiting 10 seconds..." "WARNING"
        Start-Sleep -Seconds 10

        if ($script:ContainerRuntime -eq "podman") {
            $runtimeInfo = & $script:containerCmd info --format '{{.Version.Version}}' 2>$null
        } else {
            $runtimeInfo = & $script:containerCmd info --format '{{.ServerVersion}}' 2>$null
        }

        if (-not $runtimeInfo) {
            Write-Status "$($script:ContainerRuntime) not fully initialized. Please wait and retry." "ERROR"
            exit 1
        }
    }
} catch {
    Write-Status "Could not verify $($script:ContainerRuntime) health." "WARNING"
}

# Check Compose tool (validate the compose command we detected works)
try {
    if ($script:composeCmd -like "*compose") {
        # Using 'docker compose' or 'podman compose' subcommand
        & $script:composeCmd version | Out-Null
        Write-Status "Compose command is available: $script:composeCmd" "SUCCESS"
    } else {
        # Using docker-compose or podman-compose standalone
        $composeVersion = & $script:composeCmd --version
        Write-Status "Compose is installed: $composeVersion" "SUCCESS"
    }
} catch {
    Write-Status "Compose command ($script:composeCmd) is not available!" "ERROR"
    Write-Host ""
    if ($script:ContainerRuntime -eq "podman") {
        Write-Host "  >> Installation Instructions:" -ForegroundColor Yellow
        Write-Host "     Install podman-compose with pip:" -ForegroundColor White
        Write-Host "     pip install podman-compose" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "     Or use Podman's built-in compose:" -ForegroundColor White
        Write-Host "     Ensure you have Podman 3.0+ with compose support" -ForegroundColor White
    } else {
        Write-Host "  >> Docker Compose should be included with Docker Desktop." -ForegroundColor Yellow
        Write-Host "     Try reinstalling Docker Desktop." -ForegroundColor White
    }
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# Detect system specifications
Write-Status "Detecting system specifications..." "INFO"
$systemSpecs = Get-SystemSpecs

Write-Host ""
Write-Host "  System Specifications:" -ForegroundColor Cyan
if ($systemSpecs.TotalRAM -gt 0) {
    Write-Host "    RAM:       $($systemSpecs.TotalRAM) GB total, $($systemSpecs.AvailableRAM) GB available" -ForegroundColor White
} else {
    Write-Host "    RAM:       Unable to detect" -ForegroundColor DarkGray
}

if ($systemSpecs.CPUCores -gt 0) {
    Write-Host "    CPU:       $($systemSpecs.CPUCores) cores" -ForegroundColor White
} else {
    Write-Host "    CPU:       Unable to detect" -ForegroundColor DarkGray
}

if ($systemSpecs.HasGPU) {
    Write-Host "    GPU:       $($systemSpecs.GPUName)" -ForegroundColor Green
} else {
    Write-Host "    GPU:       None detected (CPU-only mode)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  Recommended Model: $($systemSpecs.RecommendedModel)" -ForegroundColor Yellow
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

# GPU detection and configuration
$composeArgs = @('-f', 'docker-compose.yml')
$gpuOverridePath = 'configs\docker-compose.gpu.yml'
$podmanGpuOverridePath = 'configs\docker-compose.podman-gpu.yml'

if ($script:ContainerRuntime -eq "podman") {
    # Podman GPU detection and CDI setup
    try {
        $nvsmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
        if ($nvsmi) {
            & nvidia-smi > $null 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Status "NVIDIA GPU detected. Configuring Podman GPU support..." "INFO"

                # Check if nvidia-container-toolkit is installed in Podman machine
                $toolkitInstalled = & podman machine ssh podman-machine-default "command -v nvidia-ctk" 2>$null

                if (-not $toolkitInstalled) {
                    Write-Host "  >> Installing NVIDIA Container Toolkit (this may take 2-3 minutes)..." -ForegroundColor Yellow

                    # Add NVIDIA repository
                    & podman machine ssh podman-machine-default "curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo" > $null 2>&1

                    # Install toolkit
                    & podman machine ssh podman-machine-default "sudo dnf install -y nvidia-container-toolkit" > $null 2>&1

                    if ($LASTEXITCODE -eq 0) {
                        Write-Status "NVIDIA Container Toolkit installed successfully" "SUCCESS"
                    } else {
                        Write-Status "Failed to install NVIDIA Container Toolkit. Using CPU-only mode." "WARNING"
                        Write-Host "  >> You can install manually: see docs/PODMAN_GPU_SETUP.md" -ForegroundColor DarkGray
                        $nvsmi = $null  # Disable GPU
                    }
                } else {
                    Write-Status "NVIDIA Container Toolkit already installed" "SUCCESS"
                }

                # Generate CDI specifications if toolkit is installed
                if ($nvsmi) {
                    Write-Host "  >> Generating CDI specifications..." -ForegroundColor Cyan
                    & podman machine ssh podman-machine-default "sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml" > $null 2>&1

                    if ($LASTEXITCODE -eq 0) {
                        Write-Status "CDI specifications generated. GPU acceleration enabled!" "SUCCESS"

                        # Use Podman GPU compose file
                        if (Test-Path $podmanGpuOverridePath) {
                            $composeArgs += @('-f', $podmanGpuOverridePath)
                        } else {
                            Write-Status "Podman GPU compose file not found. Using CPU-only mode." "WARNING"
                        }
                    } else {
                        Write-Status "Failed to generate CDI specs. Using CPU-only mode." "WARNING"
                    }
                }
            } else {
                Write-Status "No NVIDIA GPU detected. Using CPU-only mode." "INFO"
            }
        } else {
            Write-Status "No NVIDIA GPU detected. Using CPU-only mode." "INFO"
        }
    } catch {
        Write-Status "GPU detection failed. Using CPU-only mode." "WARNING"
    }
} else {
    # Docker GPU detection
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
}

# Check if containers are already running (idempotency)
Write-Host ""
Write-Status "Checking for existing containers..." "INFO"
$existingContainers = @()
$requiredContainers = @("ollama", "n8n", "open-webui", "postgres")

foreach ($containerName in $requiredContainers) {
    $running = & $script:containerCmd ps --filter "name=$containerName" --format "{{.Names}}" 2>$null | Select-String -Pattern "^$containerName$" -Quiet
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
            Write-Host "        $($script:composeCmd) logs -f" -ForegroundColor Cyan
            Write-Host "     2. Stop and start manually:" -ForegroundColor White
            Write-Host "        $($script:composeCmd) down" -ForegroundColor Cyan
            Write-Host "        $($script:composeCmd) up -d" -ForegroundColor Cyan
            Write-Host ""
            exit 1
        }
    } else {
        Write-Status "Using existing containers (no changes made)" "INFO"
    }
} else {
    # Start containers
    Write-Status "Starting containers..." "INFO"
    Write-Host ""
    Write-Host "  >> IMPORTANT: First-time setup will download container images" -ForegroundColor Yellow
    Write-Host "     - Total download size: ~4-5 GB (ollama, n8n, open-webui, postgres)" -ForegroundColor White
    Write-Host "     - Download time: 5-15 minutes depending on your internet speed" -ForegroundColor White
    Write-Host "     - After download completes, images will be VERIFIED/EXTRACTED" -ForegroundColor Cyan
    Write-Host "     - Verification may take 1-3 minutes and will show 'Pulling' status" -ForegroundColor Cyan
    Write-Host "     - This is normal - please be patient while images are verified!" -ForegroundColor Yellow
    Write-Host ""

    try {
        # Start containers with real-time progress display
        Write-Host "  Creating and starting containers..." -ForegroundColor Cyan
        Write-Host "  >> Showing live download/extraction progress below..." -ForegroundColor Yellow
        Write-Host ""
        $startTime = Get-Date

        # Stream output in real-time to show download progress
        # Remove --quiet-pull to see progress, use --progress=plain for better output
        $ErrorActionPreference = 'Continue'

        # Track last output time for progress indicator
        $lastOutputTime = Get-Date
        $progressInterval = 10  # Show progress every 10 seconds of silence

        # Execute compose with real-time output
        Invoke-Compose @composeArgs up --detach 2>&1 | ForEach-Object {
            $line = $_.ToString()
            $now = Get-Date

            # Show periodic progress if no output for a while
            if (($now - $lastOutputTime).TotalSeconds -gt $progressInterval) {
                $elapsed = [math]::Round(($now - $startTime).TotalSeconds, 0)
                Write-Host "  ... still working (${elapsed}s elapsed)" -ForegroundColor DarkGray
                $lastOutputTime = $now
            }

            # Show meaningful progress lines (pulling, extracting, creating, starting)
            if ($line -match 'Pulling|Pull complete|Extracting|Download|Verifying|Creating|Starting|Container.*created|Container.*started|Network|Volume') {
                Write-Host "  $line" -ForegroundColor Gray
                $lastOutputTime = $now
            } elseif ($line -match 'Waiting|Downloaded') {
                Write-Host "  $line" -ForegroundColor DarkGray
                $lastOutputTime = $now
            } elseif ($line -match 'Error|Failed|error|failed') {
                Write-Host "  $line" -ForegroundColor Red
                $lastOutputTime = $now
            }
        }

        $ErrorActionPreference = 'Stop'

        if ($LASTEXITCODE -ne 0) {
            throw "compose up failed with exit code $LASTEXITCODE"
        }

        $elapsed = ((Get-Date) - $startTime).TotalSeconds
        Write-Host ""
        Write-Status "Containers started successfully in $([math]::Round($elapsed, 1))s" "SUCCESS"
        Write-Host "  >> Containers are running in the background" -ForegroundColor Cyan
        Write-Host "     To view logs: $($script:composeCmd) logs -f" -ForegroundColor DarkGray
    } catch {
        Write-Status "Failed to start containers." "ERROR"
        Write-Host ""
        Write-Host "  >> Troubleshooting Steps:" -ForegroundColor Yellow
        Write-Host "     1. Check logs:" -ForegroundColor White
        Write-Host "        $($script:composeCmd) logs -f" -ForegroundColor Cyan
        Write-Host "     2. Check for port conflicts:" -ForegroundColor White
        Write-Host "        netstat -ano | findstr `":5678 :3000 :11434 :5432`"" -ForegroundColor Cyan
        Write-Host "     3. Verify WSL2 is running:" -ForegroundColor White
        Write-Host "        wsl --status" -ForegroundColor Cyan
        Write-Host "     4. Restart $($script:ContainerRuntime) and retry this script" -ForegroundColor White
        Write-Host "     5. Check disk space:" -ForegroundColor White
        Write-Host "        $($script:containerCmd) system df" -ForegroundColor Cyan
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
        Write-Host "  >> Verify status with: $($script:composeCmd) ps" -ForegroundColor DarkGray
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
Write-Host "  >> Would you like to download an Ollama model? (Y/n) [default: Yes]" -ForegroundColor Yellow
$downloadModel = Read-Host

if ($downloadModel -eq "" -or $downloadModel -eq "Y" -or $downloadModel -eq "y") {
    Write-Host ""

    # First, check existing models
    Write-Status "Checking for existing Ollama models..." "INFO"
    try {
        $existingModels = & $script:containerCmd exec ollama ollama list 2>$null
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
    Write-Host "     Based on your system ($($systemSpecs.TotalRAM)GB RAM, $($systemSpecs.CPUCores) cores$(if($systemSpecs.HasGPU){', GPU'})):" -ForegroundColor Cyan
    Write-Host ""

    # Highlight recommended model
    $color1 = if ($systemSpecs.RecommendedChoice -eq 1) { "Green" } else { "White" }
    $color2 = if ($systemSpecs.RecommendedChoice -eq 2) { "Green" } else { "White" }
    $color3 = if ($systemSpecs.RecommendedChoice -eq 3) { "Green" } else { "White" }
    $color4 = if ($systemSpecs.RecommendedChoice -eq 4) { "Green" } else { "White" }
    $color5 = if ($systemSpecs.RecommendedChoice -eq 5) { "Green" } else { "White" }
    $color6 = if ($systemSpecs.RecommendedChoice -eq 6) { "Green" } else { "White" }

    $marker1 = if ($systemSpecs.RecommendedChoice -eq 1) { " [RECOMMENDED]" } else { "" }
    $marker2 = if ($systemSpecs.RecommendedChoice -eq 2) { " [RECOMMENDED]" } else { "" }
    $marker3 = if ($systemSpecs.RecommendedChoice -eq 3) { " [RECOMMENDED]" } else { "" }
    $marker4 = if ($systemSpecs.RecommendedChoice -eq 4) { " [RECOMMENDED]" } else { "" }
    $marker5 = if ($systemSpecs.RecommendedChoice -eq 5) { " [RECOMMENDED]" } else { "" }
    $marker6 = if ($systemSpecs.RecommendedChoice -eq 6) { " [RECOMMENDED]" } else { "" }

    Write-Host "     Small Models (CPU/Low-end GPU):" -ForegroundColor DarkCyan
    Write-Host "     1. llama3.2:1b      (1GB)   - Fast, works on any system$marker1" -ForegroundColor $color1
    Write-Host "     2. llama3.2         (4GB)   - Balanced, good for workshop$marker2" -ForegroundColor $color2
    Write-Host ""
    Write-Host "     Medium Models (GPU with 8GB+ VRAM):" -ForegroundColor DarkCyan
    Write-Host "     3. mistral          (4GB)   - Good for coding tasks$marker3" -ForegroundColor $color3
    Write-Host "     4. llama3.1:8b      (8GB)   - More capable, latest Llama$marker4" -ForegroundColor $color4
    Write-Host ""
    Write-Host "     Large Models (GPU with 12GB+ VRAM):" -ForegroundColor DarkCyan
    Write-Host "     5. mistral-nemo     (12GB)  - Advanced Mistral model$marker5" -ForegroundColor $color5
    Write-Host "     6. qwen2.5:14b      (14GB)  - Powerful multilingual model$marker6" -ForegroundColor $color6
    Write-Host ""
    Write-Host "     7. Workshop bundle  (5GB)   - llama3.2:1b + llama3.2" -ForegroundColor Cyan
    Write-Host "     8. Skip for now" -ForegroundColor DarkGray
    Write-Host ""

    $modelChoice = Read-Host "Enter choice (1-8) [default: $($systemSpecs.RecommendedChoice)]"

    # Use recommended model if user just presses Enter
    if ([string]::IsNullOrWhiteSpace($modelChoice)) {
        $modelChoice = $systemSpecs.RecommendedChoice
        Write-Host "  Using recommended choice: $modelChoice" -ForegroundColor Cyan
    }

    $models = switch ($modelChoice) {
        "1" { @("llama3.2:1b") }
        "2" { @("llama3.2") }
        "3" { @("mistral") }
        "4" { @("llama3.1:8b") }
        "5" { @("mistral-nemo") }
        "6" { @("qwen2.5:14b") }
        "7" { @("llama3.2:1b", "llama3.2") }
        default { @() }
    }

    if ($models.Count -gt 0) {
        Write-Host ""
        if ($models.Count -gt 1) {
            Write-Status "Downloading $($models.Count) models... This will take 15-30 minutes." "INFO"
            Write-Host "  >> Total size: ~9GB. Please be patient..." -ForegroundColor Yellow
        }
        
        $successCount = 0
        $failCount = 0
        
        foreach ($model in $models) {
            # Check if model already exists
            $modelExists = $false
            try {
                $existingModels = & $script:containerCmd exec ollama ollama list 2>$null
                if ($existingModels -match [regex]::Escape($model)) {
                    $modelExists = $true
                }
            } catch {
                # Ollama might not be ready yet
            }

            if ($modelExists) {
                Write-Status "Model '$model' is already downloaded. Skipping." "SUCCESS"
                $successCount++
            } else {
                Write-Host ""
                Write-Status "Downloading '$model'... This may take 2-10 minutes depending on your connection." "INFO"
                if ($models.Count -eq 1) {
                    Write-Host "  >> Model size and download time varies. Please be patient..." -ForegroundColor Yellow
                    Write-Host "  >> After download completes, the model will be validated/extracted (may take 1-2 min)" -ForegroundColor Cyan
                }
                Write-Host ""

                try {
                    & $script:containerCmd exec -it ollama ollama pull $model
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host ""
                        Write-Status "Model '$model' downloaded successfully!" "SUCCESS"
                        $successCount++
                    } else {
                        Write-Host ""
                        Write-Status "Model '$model' download may have failed (exit code: $LASTEXITCODE)" "WARNING"
                        $failCount++
                        Write-Host ""
                        Write-Host "  >> Verify download with:" -ForegroundColor Yellow
                        Write-Host "     $($script:containerCmd) exec -it ollama ollama list" -ForegroundColor Cyan
                        Write-Host "  >> Retry download with:" -ForegroundColor Yellow
                        Write-Host "     $($script:containerCmd) exec -it ollama ollama pull $model" -ForegroundColor Cyan
                    }
                } catch {
                    Write-Host ""
                    Write-Status "Failed to download model '$model'." "ERROR"
                    $failCount++
                    Write-Host ""
                    Write-Host "  >> Troubleshooting:" -ForegroundColor Yellow
                    Write-Host "     * Check internet connection" -ForegroundColor White
                    Write-Host "     * Verify Ollama container is running:" -ForegroundColor White
                    Write-Host "       $($script:containerCmd) ps | findstr ollama" -ForegroundColor Cyan
                    Write-Host "     * Check Ollama logs:" -ForegroundColor White
                    Write-Host "       $($script:containerCmd) logs ollama" -ForegroundColor Cyan
                    Write-Host "     * Retry manually:" -ForegroundColor White
                    Write-Host "       $($script:containerCmd) exec -it ollama ollama pull $model" -ForegroundColor Cyan
                    Write-Host ""
                }
            }
        }
        
        # Summary for multiple models
        if ($models.Count -gt 1) {
            Write-Host ""
            Write-Host "  Model Download Summary:" -ForegroundColor Cyan
            Write-Host "    [OK] Successful: $successCount" -ForegroundColor Green
            if ($failCount -gt 0) {
                Write-Host "    [X] Failed: $failCount" -ForegroundColor Red
            }
        }

        Write-Host ""
        Write-Host "  >> You can download additional models later with:" -ForegroundColor Cyan
        Write-Host "     $($script:containerCmd) exec -it ollama ollama pull [model-name]" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "                    SETUP SUMMARY" -ForegroundColor White
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""

# Summary of what was accomplished
$runtimeName = if ($script:ContainerRuntime -eq "podman") { "Podman" } else { "Docker" }
Write-Host "  [COMPLETED]" -ForegroundColor Green
Write-Host "     * $runtimeName verified and running" -ForegroundColor White
Write-Host "     * Configuration files prepared (.env and docker-compose.yml)" -ForegroundColor White
Write-Host "     * Containers started: ollama, n8n, open-webui, postgres" -ForegroundColor White

$modelCount = 0
try {
    $modelList = & $script:containerCmd exec ollama ollama list 2>$null
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
Write-Host "     1. Open OpenWebUI (http://localhost:3000) and create an account" -ForegroundColor White
Write-Host "     2. Open n8n (http://localhost:5678) and set up credentials" -ForegroundColor White
Write-Host "     3. Import workflows using n8n's 'Import from File' (see docs\QUICK_START.md)" -ForegroundColor White
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
