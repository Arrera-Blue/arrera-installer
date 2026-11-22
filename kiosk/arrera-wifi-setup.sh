#!/bin/bash
# ==============================================================================
# Arrera Linux - Lanceur de l'assistant Wi-Fi
# ==============================================================================
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="$(command -v python3 || echo "/usr/bin/python3")"

if [ -f "$SCRIPT_DIR/arrera-wifi-setup.py" ]; then
    "$PYTHON_BIN" "$SCRIPT_DIR/arrera-wifi-setup.py" "$@" 2>/dev/null || true
elif [ -f "/usr/bin/arrera-wifi-setup.py" ]; then
    "$PYTHON_BIN" "/usr/bin/arrera-wifi-setup.py" "$@" 2>/dev/null || true
fi

exit 0
