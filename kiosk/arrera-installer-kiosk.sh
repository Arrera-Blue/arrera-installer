#!/bin/bash
# ==============================================================================
# Arrera Linux - Script de session Kiosque pour Calamares
# Lance Calamares dans un compositeur ultra-léger (cage sous Wayland ou openbox)
# sans démarrer l'environnement lourd GNOME sur le média d'installation Live.
# ==============================================================================

set -e

echo "=== Démarrage de la session Kiosque Arrera Installer ==="

# Quitter Plymouth s'il tourne encore pour libérer le terminal graphique
plymouth quit 2>/dev/null || true

# Configuration des variables d'environnement (requis pour Wayland et Qt en root)
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/0}"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 0700 "$XDG_RUNTIME_DIR"
export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
export QT_QPA_PLATFORM="wayland;xcb"
export GDK_BACKEND="wayland,x11"
export XDG_CURRENT_DESKTOP="ArreraInstaller"
export MOZ_ENABLE_WAYLAND=1

CALAMARES_BIN="$(command -v calamares || echo "/usr/bin/calamares")"

# NOTE : On ne passe PAS -c à Calamares.
# Avec -c /etc/calamares, Calamares utilise /etc/calamares comme dossier de
# données COMPLET (cherche qml/, branding/, etc. dedans) — ce qui cause des
# erreurs FATAL car ces ressources sont dans /usr/share/calamares/.
# Sans -c, Calamares utilise les chemins standard :
#   - settings.conf  : /etc/calamares/settings.conf  (notre fichier)
#   - branding/qml/… : /usr/share/calamares/          (notre install)

if [ ! -x "$CALAMARES_BIN" ]; then
    echo "ERREUR: Binaire Calamares non trouvé ($CALAMARES_BIN)." >&2
    exit 1
fi

# S'assurer que le répertoire qml existe (Calamares l'exige même vide)
mkdir -p /usr/share/calamares/qml

# Fonction de fin d'installation / sortie
on_exit_prompt() {
    echo ""
    echo "=========================================================="
    echo "   Session d'installation Arrera Linux terminée"
    echo "=========================================================="
    if [ -f "/root/.cache/calamares/session.log" ]; then
        echo "--- Dernières lignes du journal (/root/.cache/calamares/session.log) ---"
        tail -n 25 /root/.cache/calamares/session.log || true
        echo "-------------------------------------------------------------------------"
    fi
    echo "Que souhaitez-vous faire ?"
    echo "  1) Redémarrer l'ordinateur (reboot)"
    echo "  2) Éteindre l'ordinateur (poweroff)"
    echo "  3) Ouvrir une invite de commande (bash)"
    echo "  4) Relancer l'installateur"
    echo "=========================================================="
    read -r -p "Votre choix [1-4] (défaut: 1 dans 30s): " -t 30 CHOICE || CHOICE=1
    case "$CHOICE" in
        2)
            echo "Extinction du système..."
            systemctl poweroff || poweroff
            ;;
        3)
            echo "Ouverture du shell de secours..."
            exec /bin/bash
            ;;
        4)
            exec "$0"
            ;;
        1|*)
            echo "Redémarrage du système..."
            systemctl reboot || reboot
            ;;
    esac
}

# 1. Tentative d'exécution avec Cage (Compositeur Wayland Kiosque recommandé)
if command -v cage >/dev/null 2>&1; then
    echo "Lancement via le compositeur Wayland 'cage'..."
    # -d : activer le mode debug
    # -s : fermer dès que l'application cliente se termine
    cage -s -- "$CALAMARES_BIN" -d || true
    on_exit_prompt
    exit 0
fi

# 2. Fallback avec Sway si présent
if command -v sway >/dev/null 2>&1; then
    echo "Compositeur 'cage' absent, fallback vers Sway..."
    sway --config /dev/null -c "$CALAMARES_BIN -d" || true
    on_exit_prompt
    exit 0
fi

# 3. Fallback X11 (Openbox / xinit)
if command -v xinit >/dev/null 2>&1; then
    echo "Environnement Wayland non disponible, fallback X11 avec openbox / xinit..."
    export DISPLAY="${DISPLAY:-:0}"
    xinit "$CALAMARES_BIN" -d -- :0 vt1 || true
    on_exit_prompt
    exit 0
fi

# 4. Lancement direct (si un serveur graphique tourne déjà)
echo "Lancement direct de Calamares..."
"$CALAMARES_BIN" -d || true
on_exit_prompt
exit 0
