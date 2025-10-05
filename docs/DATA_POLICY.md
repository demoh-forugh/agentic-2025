# Data Accuracy Policy

## Documentation Standards

**CRITICAL RULE**: All documentation must contain only **real, measured data** or explicitly state **"Unknown"** or **"[TO BE MEASURED]"**.

---

## What is NOT Allowed

❌ **Estimated data** without measurement  
❌ **Mock data** or test data  
❌ **Stubbed data** placeholders  
❌ **Assumed performance metrics**  
❌ **Guessed response times**  
❌ **Approximate resource usage without measurement**  

---

## What IS Allowed

✅ **Actual measured data** from running systems  
✅ **"Unknown"** when data is not yet available  
✅ **"[TO BE MEASURED]"** as placeholder for future measurements  
✅ **Hardware specifications** queried from the system  
✅ **Software versions** from actual installations  

---

## Single Source of Truth for Measured Performance

- **All measured numeric results** (timings, throughput, resource usage) must live in `SYSTEM_SPECS.md`.
- Other docs (e.g., `README.md`, `QUICK_START.md`, `INSTALLATION.md`, `SPECS_SUMMARY.md`) must **link to this section** and avoid duplicating numbers.
- When numbers change, **update only** `SYSTEM_SPECS.md` and ensure other docs still link correctly.

---

## Current Status

### Measured Data (Real)
- **System Hardware**: AMD Ryzen 9 3900X, 128GB RAM, RTX 4090
- **Operating System**: Windows 11 Pro 24H2 (Build 26100)
- **WSL2 Version**: v2.3.24.0 (Kernel 5.15.153.1-2)
- **Storage**: 2TB + 250GB NVMe SSDs
- **GPU**: NVIDIA GeForce RTX 4090 (24GB VRAM)

### Not Yet Measured (Marked as Unknown)
- **LLM Response Times**: [TO BE MEASURED]
- **Container Resource Usage**: [TO BE MEASURED]
- **GPU vs CPU Performance**: [TO BE MEASURED]
- **RAM Usage During Inference**: [TO BE MEASURED]
- **CPU Utilization Percentages**: [TO BE MEASURED]
- **Docker Stats**: [TO BE MEASURED]
- **Actual Performance on Different Configurations**: [TO BE MEASURED]

---

## How to Collect Real Data

### Performance Metrics

```powershell
# 1. Start containers
docker-compose up -d

# 2. Wait for services to be ready
Start-Sleep -Seconds 30

# 3. Monitor resource usage
docker stats --no-stream

# 4. Check GPU usage
nvidia-smi

# 5. Time LLM responses
Measure-Command { 
    # Run inference via API or UI
    # Record the time
}
```

### Container Statistics

```powershell
# Real-time stats
docker stats

# Single snapshot
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# GPU monitoring
nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv
```

### Response Time Testing

1. Open OpenWebUI at http://localhost:3000
2. Enter a standardized test prompt
3. Measure time from send to complete response
4. Repeat 5-10 times for average
5. Test with different models (llama3.2, llama3.2:1b)
6. Test both GPU and CPU-only modes

---

## Updating Documentation

When real data is collected:

1. **Find all instances** of `[TO BE MEASURED]` or `Unknown`
2. **Replace with actual measured values**
3. **Include measurement conditions**:
   - Date/time of measurement
   - System state (idle, active, etc.)
   - Model being tested
   - GPU mode (enabled/disabled)

Example:
```markdown
# Before
- **Response time**: [TO BE MEASURED]

# After
- **Response time**: 3.2 seconds (measured 2025-10-04, GPU mode, llama3.2)
```

---

## Why This Matters

1. **Accuracy**: Workshop attendees need realistic expectations
2. **Credibility**: Real data builds trust
3. **Planning**: Helps attendees prepare appropriate hardware
4. **Transparency**: Shows what's tested vs. theoretical
5. **Debugging**: Real measurements help identify issues

---

## Files Requiring Measurement

### Priority 1 - Critical for Workshop
- [ ] `SYSTEM_SPECS.md` - Performance Metrics section (single source of truth)
- [ ] `SPECS_SUMMARY.md` - Performance Comparison Table
- [x] `README.md` - Link to `SYSTEM_SPECS.md` (no inline numbers)
- [x] `QUICK_START.md` - Link to `SYSTEM_SPECS.md` (no inline numbers)

### Priority 2 - Installation Guides
- [x] `INSTALLATION.md` - Link to `SYSTEM_SPECS.md` for demo measurements
- [ ] Resource Usage section

### Priority 3 - Supporting Documentation
- [ ] Model selection guidelines with real benchmarks
- [ ] GPU vs CPU comparison with actual numbers

---

## Review Checklist

Before finalizing documentation:

- [ ] No estimated response times without "estimate" label
- [ ] No resource usage numbers without measurement
- [ ] No performance claims without testing
- [ ] All placeholders clearly marked `[TO BE MEASURED]`
- [ ] Unknown data explicitly stated as `Unknown`
- [ ] Real hardware specs from system queries only
- [ ] Software versions from actual installations only

---

## Exceptions

The following are acceptable without measurement:

1. **Recommended specifications** (these are targets, not measurements)
2. **Minimum requirements** (based on software requirements)
3. **Cost estimates** (market prices, not performance)
4. **Installation steps** (procedures, not metrics)
5. **Hardware compatibility** (vendor specifications)

---

**Last Updated**: 2025-10-04  
**Policy Version**: 1.0  
**Status**: Active

**Remember**: When in doubt, mark as `Unknown` or `[TO BE MEASURED]`. Never estimate or guess.
