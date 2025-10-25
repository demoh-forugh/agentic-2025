# Test Ollama API - PowerShell Script
# This script demonstrates how to interact with Ollama API

Write-Host "Testing Ollama API..." -ForegroundColor Cyan
Write-Host ""

# Configuration
$OLLAMA_URL = "http://localhost:11434"

# Test 1: Check if Ollama is running
Write-Host "Test 1: Checking Ollama health..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$OLLAMA_URL/api/tags" -UseBasicParsing
    Write-Host "✓ Ollama is running" -ForegroundColor Green
    
    $models = ($response.Content | ConvertFrom-Json).models
    Write-Host "  Available models: $($models.Count)" -ForegroundColor Cyan
    foreach ($model in $models) {
        Write-Host "    • $($model.name) ($([math]::Round($model.size/1GB, 2)) GB)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Ollama is not accessible" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Generate text
Write-Host "Test 2: Generating text..." -ForegroundColor Yellow

$body = @{
    model = "llama3.2"
    prompt = "What is the capital of France? Answer in one sentence."
    stream = $false
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$OLLAMA_URL/api/generate" -Method Post -Body $body -ContentType "application/json"
    Write-Host "✓ Generation successful" -ForegroundColor Green
    Write-Host "  Response: $($response.response)" -ForegroundColor White
    Write-Host "  Tokens: $($response.eval_count)" -ForegroundColor Gray
    Write-Host "  Duration: $([math]::Round($response.total_duration/1000000000, 2))s" -ForegroundColor Gray
} catch {
    Write-Host "✗ Generation failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Chat completion
Write-Host "Test 3: Chat completion..." -ForegroundColor Yellow

$chatBody = @{
    model = "llama3.2"
    messages = @(
        @{
            role = "system"
            content = "You are a helpful assistant."
        },
        @{
            role = "user"
            content = "Tell me a short joke about programming."
        }
    )
    stream = $false
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$OLLAMA_URL/api/chat" -Method Post -Body $chatBody -ContentType "application/json"
    Write-Host "✓ Chat successful" -ForegroundColor Green
    Write-Host "  Response: $($response.message.content)" -ForegroundColor White
} catch {
    Write-Host "✗ Chat failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 4: Model info
Write-Host "Test 4: Getting model info..." -ForegroundColor Yellow

$showBody = @{
    name = "llama3.2"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$OLLAMA_URL/api/show" -Method Post -Body $showBody -ContentType "application/json"
    Write-Host "✓ Model info retrieved" -ForegroundColor Green
    Write-Host "  Model: $($response.modelfile.Split("`n")[0])" -ForegroundColor Gray
    Write-Host "  Parameters: $($response.details.parameter_size)" -ForegroundColor Gray
    Write-Host "  Format: $($response.details.format)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Failed to get model info" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "All tests completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  • Try different models with the -model parameter" -ForegroundColor White
Write-Host "  • Experiment with temperature and other parameters" -ForegroundColor White
Write-Host "  • Use these patterns in your n8n workflows" -ForegroundColor White
