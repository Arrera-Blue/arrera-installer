#!/bin/bash
# ==============================================================================
# Arrera Linux - Script de session Kiosque pour Calamares
# Lance Calamares dans un compositeur ultra-léger (cage sous Wayland ou openbox)
# sans démarrer l'environnement lourd GNOME sur le média d'installation Live.
# ==============================================================================

set -e

# Configuration des variables d'environnement (requis pour Wayland et Qt en root)
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/0}"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 0700 "$XDG_RUNTIME_DIR"
export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
export QT_QPA_PLATFORM="wayland;xcb"
export GDK_BACKEND="wayland,x11"
export XDG_CURRENT_DESKTOP="GNOME"
export DESKTOP_SESSION="gnome"
export QT_QPA_PLATFORMTHEME="gnome"
export GTK_THEME="Adwaita:dark"
export XCURSOR_THEME="Adwaita"
export XCURSOR_SIZE="24"
export MOZ_ENABLE_WAYLAND=1

# Configuration du clavier pour le compositeur Wayland (Cage / wlroots)
# Détecte la disposition configurée dans le système (ex: fr) ou applique fr par défaut
KEYMAP="$(localectl status 2>/dev/null | awk -F': ' '/X11 Layout/ {print $2}' | tr -d ' ' || true)"
if [ -z "$KEYMAP" ]; then
    KEYMAP="$(awk -F'=' '/KEYMAP/ {gsub(/["'\'' ]/, "", $2); print $2}' /etc/vconsole.conf 2>/dev/null || true)"
fi
export XKB_DEFAULT_LAYOUT="${KEYMAP:-fr}"
export XKB_DEFAULT_MODEL="pc105"

CALAMARES_BIN="$(command -v calamares || echo "/usr/bin/calamares")"

if [ ! -x "$CALAMARES_BIN" ]; then
    echo "ERREUR: Binaire Calamares non trouvé ($CALAMARES_BIN)." >&2
    exit 1
fi

# S'assurer que le répertoire QML existe (Calamares l'exige au démarrage)
mkdir -p /usr/share/calamares/qml

# ==============================================================================
# Préparation de la racine LiveOS pour Calamares unpackfs (/run/rootfsbase)
# Fedora LiveOS fournit l'image racine ext4 via dracut ou device-mapper.
# ==============================================================================
mkdir -p /run/rootfsbase
if ! mountpoint -q /run/rootfsbase; then
    if [ -b /dev/mapper/live-base ]; then
        mount -o ro /dev/mapper/live-base /run/rootfsbase 2>/dev/null || true
    elif [ -b /dev/mapper/live-rw ]; then
        mount -o ro /dev/mapper/live-rw /run/rootfsbase 2>/dev/null || true
    elif [ -f /run/initramfs/live/LiveOS/rootfs.img ]; then
        mount -o loop,ro /run/initramfs/live/LiveOS/rootfs.img /run/rootfsbase 2>/dev/null || true
    elif [ -f /run/install/repo/LiveOS/rootfs.img ]; then
        mount -o loop,ro /run/install/repo/LiveOS/rootfs.img /run/rootfsbase 2>/dev/null || true
    fi
fi

# Nettoyer l'affichage TTY1 et masquer le curseur pour une transition graphique propre
clear >/dev/tty1 2>/dev/null || true
setterm -cursor off >/dev/tty1 2>/dev/null || true

# Fonction de fin d'installation / sortie (affiche le menu uniquement en cas de fermeture)
on_exit_prompt() {
    exec 1>/dev/tty1 2>&1
    setterm -cursor on >/dev/tty1 2>/dev/null || true
    clear >/dev/tty1 2>/dev/null || true

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

# Quitter Plymouth juste avant de démarrer le compositeur graphique
plymouth quit 2>/dev/null || true

# 1. Exécution avec Cage (Compositeur Wayland Kiosque plein écran)
if command -v cage >/dev/null 2>&1; then
    cage -s -- "$CALAMARES_BIN" -d || true
    on_exit_prompt
    exit 0
fi

# 2. Fallback avec Sway si présent
if command -v sway >/dev/null 2>&1; then
    sway --config /dev/null -c "$CALAMARES_BIN -d" || true
    on_exit_prompt
    exit 0
fi

# 3. Fallback X11 (Openbox / xinit)
if command -v xinit >/dev/null 2>&1; then
    export DISPLAY="${DISPLAY:-:0}"
    xinit "$CALAMARES_BIN" -d -- :0 vt1 || true
    on_exit_prompt
    exit 0
fi

# 4. Lancement direct (si un serveur graphique tourne déjà)
"$CALAMARES_BIN" -d || true
on_exit_prompt
exit 0
