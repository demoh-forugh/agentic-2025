# File-based command runner - no admin required
# Commands are placed in ./commands/ directory as JSON files
# Responses are written to ./responses/ directory

$commandDir = "C:\Code\open-source-setup\shared\commands"
$responseDir = "C:\Code\open-source-setup\shared\responses"

# Create directories if they don't exist
New-Item -ItemType Directory -Force -Path $commandDir | Out-Null
New-Item -ItemType Directory -Force -Path $responseDir | Out-Null

Write-Host "File-based command executor started..."
Write-Host "Watching: $commandDir"
Write-Host "Responses: $responseDir"
Write-Host "Press Ctrl+C to stop"
Write-Host ""

# Process any existing command files first
Get-ChildItem -Path $commandDir -Filter "*.json" | ForEach-Object {
    Write-Host "Processing existing command: $($_.Name)"
    $cmdFile = $_.FullName
    $cmdId = $_.BaseName

    try {
        $cmdData = Get-Content $cmdFile -Raw | ConvertFrom-Json
        $command = $cmdData.command

        Write-Host "  Executing: $command"

        # Execute the command
        $output = try {
            Invoke-Expression $command 2>&1 | Out-String
        } catch {
            "ERROR: $($_.Exception.Message)"
        }

        # Write response
        $response = @{
            id = $cmdId
            command = $command
            output = $output
            timestamp = (Get-Date).ToString("o")
            success = $true
        } | ConvertTo-Json

        $responseFile = Join-Path $responseDir "$cmdId.json"
        $response | Out-File -FilePath $responseFile -Encoding UTF8

        # Delete command file
        Remove-Item $cmdFile -Force

        Write-Host "  Response written to: $cmdId.json"
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Watch for new command files
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $commandDir
$watcher.Filter = "*.json"
$watcher.EnableRaisingEvents = $true

$action = {
    $path = $Event.SourceEventArgs.FullPath
    $name = $Event.SourceEventArgs.Name
    $cmdId = [System.IO.Path]::GetFileNameWithoutExtension($name)

    Start-Sleep -Milliseconds 100  # Brief delay to ensure file is fully written

    try {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] New command: $name"

        $cmdData = Get-Content $path -Raw | ConvertFrom-Json
        $command = $cmdData.command

        Write-Host "  Executing: $command"

        # Execute the command
        $output = try {
            Invoke-Expression $command 2>&1 | Out-String
        } catch {
            "ERROR: $($_.Exception.Message)"
        }

        # Write response
        $responseFile = Join-Path $using:responseDir "$cmdId.json"
        $response = @{
            id = $cmdId
            command = $command
            output = $output
            timestamp = (Get-Date).ToString("o")
            success = $true
        } | ConvertTo-Json

        $response | Out-File -FilePath $responseFile -Encoding UTF8

        # Delete command file
        Remove-Item $path -Force

        Write-Host "  Response written: $cmdId.json" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red

        # Write error response
        $responseFile = Join-Path $using:responseDir "$cmdId.json"
        $response = @{
            id = $cmdId
            command = "unknown"
            output = "ERROR: $($_.Exception.Message)"
            timestamp = (Get-Date).ToString("o")
            success = $false
        } | ConvertTo-Json

        $response | Out-File -FilePath $responseFile -Encoding UTF8
    }
}

Register-ObjectEvent $watcher "Created" -Action $action | Out-Null

# Keep script running
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    $watcher.Dispose()
}
