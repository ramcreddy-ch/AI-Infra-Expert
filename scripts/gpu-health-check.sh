#!/usr/bin/env bash
# Production GPU Health & Diagnostic Check Script
set -eo pipefail

echo "=================================================="
echo "🚀 Running AI Infra Expert GPU Health Diagnostics"
echo "=================================================="

# 1. Check if driver is loaded
if ! command -v nvidia-smi &> /dev/null; then
    echo "❌ ERROR: nvidia-smi not found. Driver is not installed or not in PATH."
    exit 1
fi

echo "✅ Driver status: CLI detected."

# 2. Check GPU persistence mode
PERSISTENCE=$(nvidia-smi --query-gpu=persistence_mode --format=csv,noheader | uniq)
if [ "$PERSISTENCE" != "Enabled" ]; then
    echo "⚠️  WARNING: Persistence mode is disabled. Recommended: Run 'sudo nvidia-smi -pm 1'"
else
    echo "✅ Persistence mode: Enabled."
fi

# 3. Check for ECC memory errors
ECC_ERRORS=$(nvidia-smi --query-gpu=ecc.errors.uncorrected.volatile.device --format=csv,noheader | paste -sd+ - | bc)
if [ "$ECC_ERRORS" -gt 0 ]; then
    echo "❌ CRITICAL: $ECC_ERRORS uncorrected volatile ECC errors detected! Action: Schedule RMA."
else
    echo "✅ Memory status: No volatile ECC errors detected."
fi

# 4. Check for active driver XID errors in kernel log
XID_CHECK=$(dmesg | grep -i "NVRM: Xid" | tail -n 5 || true)
if [ -n "$XID_CHECK" ]; then
    echo "❌ CRITICAL: Recent XID driver error codes found in dmesg:"
    echo "$XID_CHECK"
else
    echo "✅ Kernel logs: No recent XID driver errors."
fi

# 5. Query device temperatures
TEMPS=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)
MAX_TEMP=0
for T in $TEMPS; do
    if [ "$T" -gt "$MAX_TEMP" ]; then
        MAX_TEMP=$T
    fi
done

if [ "$MAX_TEMP" -gt 80 ]; then
    echo "❌ CRITICAL: Max GPU temperature is ${MAX_TEMP}°C, exceeding 80°C threshold. Thermal throttling active!"
else
    echo "✅ Thermal status: Safe. Max GPU temperature is ${MAX_TEMP}°C."
fi

echo "=================================================="
echo "🎯 Diagnosis Complete."
echo "=================================================="
