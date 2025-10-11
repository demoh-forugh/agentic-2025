<#
.SYNOPSIS
    n8n Workshop - Installation Verification Script

.DESCRIPTION
    Verifies that all container runtime (Docker/Podman), containers, ports, and services are running correctly.
    Provides prioritized troubleshooting guidance if issues are found.

.EXAMPLE
    .\verify-windows.ps1
    Run verification checks

.NOTES
    Version: 1.2.0
    Last Updated: 2025-10-10
    Workshop: Go to Agentic Conference 2025
    Requires: Docker Desktop or Podman running
#>

# n8n Workshop - Installation Verification Script
# Version: 1.2.0
# Last Updated: 2025-10-10
# Workshop: Go to Agentic Conference 2025
# Supports: Docker Desktop, Podman

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "   Installation Verification v1.2.0" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

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

Write-Host "Container Runtime: $($script:ContainerRuntime)" -ForegroundColor Cyan
Write-Host ""

$allGood = $true
$criticalFailures = @()
$warnings = @()

# Function to display status
function Write-Check {
    param(
        [string]$Message,
        [bool]$Success,
        [bool]$Critical = $false
    )

    if ($Success) {
        Write-Host "[OK] $Message" -ForegroundColor Green
    } else {
        if ($Critical) {
            Write-Host "[X] $Message" -ForegroundColor Red
            $script:criticalFailures += $Message
        } else {
            Write-Host "[!] $Message" -ForegroundColor Yellow
            $script:warnings += $Message
        }
        $script:allGood = $false
    }
}

# 1. Check container runtime (CRITICAL)
Write-Host "Checking $($script:ContainerRuntime)..." -ForegroundColor Yellow
try {
    & $script:containerCmd ps | Out-Null
    Write-Check "$($script:ContainerRuntime) is running" $true $true
} catch {
    Write-Check "$($script:ContainerRuntime) is not running" $false $true
}

# Additional runtime health check
try {
    if ($script:ContainerRuntime -eq "podman") {
        $runtimeVersion = & $script:containerCmd version --format '{{.Client.Version}}' 2>$null
    } else {
        $runtimeVersion = & $script:containerCmd version --format '{{.Server.Version}}' 2>$null
    }
    if ($runtimeVersion) {
        Write-Check "$($script:ContainerRuntime) is responsive (v$runtimeVersion)" $true
    }
} catch {
    Write-Check "$($script:ContainerRuntime) is not responding properly" $false $true
}

# 2. Check containers
Write-Host ""
Write-Host "Checking containers..." -ForegroundColor Yellow

$containers = @{
    "ollama" = "LLM runtime"
    "open-webui" = "Chat interface"
    "n8n" = "Workflow automation"
    "postgres" = "Database"
}

$runningContainers = @()
$stoppedContainers = @()
$missingContainers = @()

foreach ($containerName in $containers.Keys) {
    $running = & $script:containerCmd ps --filter "name=$containerName" --format "{{.Names}}" 2>$null | Select-String -Pattern "^$containerName$" -Quiet
    if ($running) {
        Write-Check "Container '$containerName' ($($containers[$containerName])) is running" $true
        $runningContainers += $containerName
    } else {
        # Check if it exists but is stopped
        $exists = & $script:containerCmd ps -a --filter "name=$containerName" --format "{{.Names}}" 2>$null | Select-String -Pattern "^$containerName$" -Quiet
        if ($exists) {
            Write-Check "Container '$containerName' exists but is NOT running" $false $true
            $stoppedContainers += $containerName
        } else {
            Write-Check "Container '$containerName' is NOT found" $false $true
            $missingContainers += $containerName
        }
    }
}

# 3. Check ports and verify they're mapped to correct containers
Write-Host ""
Write-Host "Checking ports..." -ForegroundColor Yellow

$ports = @{
    "11434" = @{ Service = "Ollama"; Container = "ollama" }
    "3000"  = @{ Service = "OpenWebUI"; Container = "open-webui" }
    "5678"  = @{ Service = "n8n"; Container = "n8n" }
    "5432"  = @{ Service = "PostgreSQL"; Container = "postgres" }
}

foreach ($port in $ports.Keys) {
    $serviceInfo = $ports[$port]
    $containerName = $serviceInfo.Container

    # Check if port is mapped in container
    $portMapping = & $script:containerCmd port $containerName 2>$null | Select-String -Pattern "$port"
    if ($portMapping) {
        Write-Check "Port $port ($($serviceInfo.Service)) mapped correctly: $portMapping" $true
    } else {
        # Fall back to checking if port is listening
        $listening = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        if ($listening) {
            Write-Check "Port $port ($($serviceInfo.Service)) is listening (but may not be mapped to container)" $false $false
        } else {
            Write-Check "Port $port ($($serviceInfo.Service)) is NOT listening" $false $true
        }
    }
}

# 4. Check HTTP endpoints
Write-Host ""
Write-Host "Checking HTTP endpoints..." -ForegroundColor Yellow

# Check Ollama API
try {
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Check "Ollama API is accessible" $true

        # Check for models
        $content = $response.Content | ConvertFrom-Json
        if ($content.models -and $content.models.Count -gt 0) {
            Write-Host "  -> Models available: $($content.models.Count)" -ForegroundColor Cyan
            foreach ($model in $content.models) {
                Write-Host "    * $($model.name)" -ForegroundColor Gray
            }
        } else {
            Write-Host ""
            Write-Host "  [!] No models downloaded yet" -ForegroundColor Yellow
            Write-Host "    Recommended models (see README.md):" -ForegroundColor Gray
            Write-Host "      * llama3.2:1b (1GB) - Fast, for testing" -ForegroundColor Cyan
            Write-Host "      * llama3.2 (4GB) - Recommended for workshop" -ForegroundColor Cyan
            Write-Host "      * mistral (4GB) - Good for coding" -ForegroundColor Cyan
            Write-Host "    Download with: $($script:containerCmd) exec -it ollama ollama pull llama3.2" -ForegroundColor White
            Write-Host ""
        }
    }
} catch {
    Write-Check "Ollama API is NOT accessible at http://localhost:11434" $false $true
}

# Check n8n
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5678" -UseBasicParsing -TimeoutSec 5 -MaximumRedirection 0 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 302) {
        Write-Check "n8n web interface is accessible" $true
    }
} catch {
    Write-Check "n8n web interface is NOT accessible at http://localhost:5678" $false $true
}

# Check OpenWebUI
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Check "OpenWebUI is accessible" $true
    }
} catch {
    Write-Check "OpenWebUI is NOT accessible at http://localhost:3000" $false $true
}

# Check PostgreSQL (port check only, not HTTP)
try {
    $pgPort = & $script:containerCmd port postgres 5432 2>$null
    if ($pgPort) {
        Write-Check "PostgreSQL port is mapped: $pgPort" $true
    } else {
        Write-Check "PostgreSQL port is NOT mapped" $false $false
    }
} catch {
    Write-Check "Could not verify PostgreSQL port" $false $false
}

# 5. Check container network
Write-Host ""
Write-Host "Checking container network..." -ForegroundColor Yellow

$network = & $script:containerCmd network ls --filter "name=ai-network" --format "{{.Name}}" 2>$null | Select-String -Pattern "ai-network" -Quiet
if ($network) {
    Write-Check "Container network 'ai-network' exists" $true
} else {
    Write-Check "Container network 'ai-network' does NOT exist" $false $false
}

# 6. Check volumes
Write-Host ""
Write-Host "Checking volumes..." -ForegroundColor Yellow

$volumes = @{
    "ollama_data" = "Ollama models and config"
    "n8n_data" = "n8n workflows and credentials"
    "open_webui_data" = "OpenWebUI data"
    "postgres_data" = "PostgreSQL database"
}

foreach ($volumeName in $volumes.Keys) {
    $exists = & $script:containerCmd volume ls --format "{{.Name}}" 2>$null | Select-String -Pattern $volumeName -Quiet
    if ($exists) {
        Write-Check "Volume '$volumeName' ($($volumes[$volumeName])) exists" $true
    } else {
        Write-Check "Volume '$volumeName' does NOT exist" $false $false
    }
}

# 7. Check disk space
Write-Host ""
Write-Host "Checking disk space..." -ForegroundColor Yellow

try {
    $dfOutput = & $script:containerCmd system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}"
    Write-Host $dfOutput -ForegroundColor Gray
} catch {
    Write-Host "Could not check disk space" -ForegroundColor Yellow
}

# 8. Memory check
Write-Host ""
Write-Host "Checking container resource usage..." -ForegroundColor Yellow

try {
    $stats = & $script:containerCmd stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    Write-Host $stats -ForegroundColor Gray
} catch {
    Write-Host "Could not retrieve container stats" -ForegroundColor Yellow
}

# Summary with prioritized troubleshooting
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan

if ($allGood) {
    Write-Host "   All checks passed! [OK]" -ForegroundColor Green
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Your workshop environment is ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[LINK] Access your services:" -ForegroundColor Cyan
    Write-Host "  * OpenWebUI:  http://localhost:3000  (Chat with LLMs)" -ForegroundColor White
    Write-Host "  * n8n:        http://localhost:5678  (Build workflows)" -ForegroundColor White
    Write-Host "  * Ollama API: http://localhost:11434 (LLM API endpoint)" -ForegroundColor White
    Write-Host ""
    Write-Host "[INFO] Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Configure Google API credentials (see docs\CONFIGURATION.md)" -ForegroundColor White
    Write-Host "  2. Import sample workflows from .\workflows\" -ForegroundColor White
    Write-Host "  3. Start building your agents!" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "   Some checks failed [X]" -ForegroundColor Red
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host ""

    # Prioritized troubleshooting based on what failed
    if ($criticalFailures.Count -gt 0) {
        Write-Host "[CRITICAL] Fix these issues first:" -ForegroundColor Red
        Write-Host ""

        # Priority 1: Container runtime not running
        if ($criticalFailures -match "$($script:ContainerRuntime).*not running") {
            Write-Host "1. $($script:ContainerRuntime) is not running" -ForegroundColor Red
            if ($script:ContainerRuntime -eq "docker") {
                Write-Host "   -> Start Docker Desktop from Windows Start Menu" -ForegroundColor Yellow
                Write-Host "   -> Wait 30-60 seconds for Docker to fully initialize" -ForegroundColor Yellow
                Write-Host "   -> Look for Docker icon in system tray (whale icon)" -ForegroundColor Yellow
            } else {
                Write-Host "   -> Start Podman machine: podman machine start" -ForegroundColor Yellow
                Write-Host "   -> Wait for machine to fully initialize" -ForegroundColor Yellow
                Write-Host "   -> Check status: podman machine list" -ForegroundColor Yellow
            }
            Write-Host "   -> If issues persist, restart your computer" -ForegroundColor Yellow
            Write-Host ""
        }

        # Priority 2: Containers not running
        if ($stoppedContainers.Count -gt 0) {
            Write-Host "2. Containers exist but are stopped: $($stoppedContainers -join ', ')" -ForegroundColor Red
            Write-Host "   -> Start them with: $($script:containerCmd) start $($stoppedContainers -join ' ')" -ForegroundColor Yellow
            Write-Host "   -> Or restart all services: $($script:composeCmd) restart" -ForegroundColor Yellow
            Write-Host ""
        }

        if ($missingContainers.Count -gt 0) {
            Write-Host "2. Containers are missing: $($missingContainers -join ', ')" -ForegroundColor Red
            Write-Host "   -> Run setup script: .\scripts\setup-windows.ps1" -ForegroundColor Yellow
            Write-Host "   -> Or manually start: $($script:composeCmd) up -d" -ForegroundColor Yellow
            Write-Host ""
        }

        # Priority 3: Ports not accessible
        if ($criticalFailures -match "Port.*NOT") {
            Write-Host "3. Some services are not accessible on their ports" -ForegroundColor Red
            Write-Host "   -> Check for port conflicts:" -ForegroundColor Yellow
            Write-Host "     netstat -ano | findstr `":5678 :3000 :11434 :5432`"" -ForegroundColor Gray
            Write-Host "   -> Check container logs:" -ForegroundColor Yellow
            Write-Host "     $($script:composeCmd) logs [service-name]" -ForegroundColor Gray
            Write-Host "   -> Restart containers: $($script:composeCmd) restart" -ForegroundColor Yellow
            Write-Host ""
        }

        # Priority 4: HTTP endpoints failing
        if ($criticalFailures -match "NOT accessible") {
            Write-Host "4. HTTP endpoints are not responding" -ForegroundColor Red
            Write-Host "   -> Containers may still be initializing (wait 30s and retry)" -ForegroundColor Yellow
            Write-Host "   -> Check container logs for errors:" -ForegroundColor Yellow
            Write-Host "     $($script:composeCmd) logs -f" -ForegroundColor Gray
            Write-Host "   -> Verify containers are healthy:" -ForegroundColor Yellow
            Write-Host "     $($script:containerCmd) ps" -ForegroundColor Gray
            Write-Host ""
        }
    }

    if ($warnings.Count -gt 0) {
        Write-Host "[WARNING] Non-critical issues:" -ForegroundColor Yellow
        Write-Host ""
        foreach ($warning in $warnings) {
            Write-Host "  * $warning" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    Write-Host "[HELP] Additional Help:" -ForegroundColor Cyan
    Write-Host "  * Troubleshooting guide: docs\TROUBLESHOOTING.md" -ForegroundColor White
    Write-Host "  * Check logs: $($script:composeCmd) logs -f" -ForegroundColor White
    Write-Host "  * View container status: $($script:composeCmd) ps" -ForegroundColor White
    Write-Host "  * Restart services: $($script:composeCmd) restart" -ForegroundColor White
    Write-Host ""

    exit 1
}

Write-Host "Need help? Check docs\TROUBLESHOOTING.md or run .\scripts\setup-windows.ps1 again." -ForegroundColor Cyan
Write-Host ""
