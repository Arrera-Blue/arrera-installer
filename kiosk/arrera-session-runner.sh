#!/bin/bash
# ==============================================================================
# Arrera Linux - Exécuteur de session Kiosque (Wi-Fi + Calamares)
# ==============================================================================
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CALAMARES_BIN="$(command -v calamares || echo "/usr/bin/calamares")"

# 1. Assistant Wi-Fi : s'ouvre uniquement si une carte Wi-Fi est présente et non connectée
if [ -x "/usr/bin/arrera-wifi-setup.sh" ]; then
    /usr/bin/arrera-wifi-setup.sh 2>/dev/null || true
elif [ -f "$SCRIPT_DIR/arrera-wifi-setup.sh" ]; then
    bash "$SCRIPT_DIR/arrera-wifi-setup.sh" 2>/dev/null || true
fi

# 2. Lancement de l'installateur Calamares
"$CALAMARES_BIN" -d -c /etc/calamares
