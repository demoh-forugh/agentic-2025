# Test script to demonstrate sending commands to the listener
# Usage: .\test-command.ps1 -Command "dir C:\"

param(
    [Parameter(Mandatory=$true)]
    [string]$Command
)

$commandDir = "C:\Code\open-source-setup\shared\commands"
$responseDir = "C:\Code\open-source-setup\shared\responses"

# Generate unique command ID
$cmdId = [Guid]::NewGuid().ToString()

# Create command file
$cmdData = @{
    command = $Command
    timestamp = (Get-Date).ToString("o")
} | ConvertTo-Json

$cmdFile = Join-Path $commandDir "$cmdId.json"
$cmdData | Out-File -FilePath $cmdFile -Encoding UTF8

Write-Host "Command submitted: $cmdId"
Write-Host "Waiting for response..."

# Wait for response (timeout after 10 seconds)
$timeout = 10
$elapsed = 0
$responseFile = Join-Path $responseDir "$cmdId.json"

while (-not (Test-Path $responseFile) -and $elapsed -lt $timeout) {
    Start-Sleep -Milliseconds 500
    $elapsed += 0.5
}

if (Test-Path $responseFile) {
    $response = Get-Content $responseFile -Raw | ConvertFrom-Json
    Write-Host "`nResponse received:" -ForegroundColor Green
    Write-Host "Command: $($response.command)"
    Write-Host "Timestamp: $($response.timestamp)"
    Write-Host "`nOutput:"
    Write-Host $response.output

    # Clean up response file
    Remove-Item $responseFile -Force
} else {
    Write-Host "`nTimeout: No response received after $timeout seconds" -ForegroundColor Red
    Write-Host "Make sure the command listener is running!"
}
