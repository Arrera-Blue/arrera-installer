#!/bin/bash
# ==============================================================================
# Arrera Linux - Lanceur OOBE de premier démarrage (Arrera Blue Lynx)
# Exécuté une seule fois au premier démarrage sur les 4 éditions :
# - Home, Education, Enterprise : interface graphique GTK4/Libadwaita sous Cage
# - Server : assistant console interactif directement sur tty1
# Puis bascule vers GDM (Desktop), getty@tty1 (Serveur) ou redémarre si le noyau
# CachyOS a été installé.
# ==============================================================================

set -e

# Détermination de l'édition (home, education, enterprise ou server)
EDITION="${1:-${ARRERA_OOBE_EDITION:-}}"
if [ -z "$EDITION" ] && [ -f /etc/arrera-oobe-edition ]; then
    EDITION="$(tr -d '[:space:]' < /etc/arrera-oobe-edition)"
fi
EDITION="${EDITION:-home}"

case "$EDITION" in
    education|edu)
        OOBE_BIN="/usr/bin/arrera-blue-lynx-education"
        OOBE_MODE="gui"
        ;;
    enterprise|ent)
        OOBE_BIN="/usr/bin/arrera-blue-lynx-enterprise"
        OOBE_MODE="gui"
        ;;
    server|srv)
        OOBE_BIN="/usr/bin/arrera-blue-lynx-server"
        OOBE_MODE="cli"
        ;;
    home|*)
        OOBE_BIN="/usr/bin/arrera-blue-lynx-home"
        OOBE_MODE="gui"
        ;;
esac

if [ "$OOBE_MODE" = "gui" ] && [ ! -x "$OOBE_BIN" ]; then
    for candidate in /usr/bin/arrera-blue-lynx-home /usr/bin/arrera-blue-lynx-education /usr/bin/arrera-blue-lynx-enterprise; do
        if [ -x "$candidate" ]; then
            OOBE_BIN="$candidate"
            break
        fi
    done
fi

# Configuration des variables d'environnement (Wayland / GTK4 / Libadwaita en root)
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/0}"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 0700 "$XDG_RUNTIME_DIR"
export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
export GDK_BACKEND="wayland,x11"
export XDG_CURRENT_DESKTOP="GNOME"
export DESKTOP_SESSION="gnome"
export GTK_THEME="Adwaita"
export XCURSOR_THEME="Adwaita"
export XCURSOR_SIZE="24"

# Détection de la disposition clavier système (fr par défaut)
KEYMAP="$(localectl status 2>/dev/null | awk -F': ' '/X11 Layout/ {print $2}' | tr -d ' ' || true)"
if [ -z "$KEYMAP" ] && [ -f /etc/vconsole.conf ]; then
    KEYMAP="$(awk -F'=' '/KEYMAP/ {gsub(/["'\'' ]/, "", $2); print $2}' /etc/vconsole.conf 2>/dev/null || true)"
fi
export XKB_DEFAULT_LAYOUT="${KEYMAP:-fr}"
export XKB_DEFAULT_MODEL="pc105"

on_oobe_error_prompt() {
    local reason="$1"
    exec 0</dev/tty1 1>/dev/tty1 2>&1 || true
    setterm -cursor on >/dev/tty1 2>/dev/null || true
    clear >/dev/tty1 2>/dev/null || true

    echo ""
    echo "=========================================================="
    echo "   Arrera Blue Lynx - Assistant de premier démarrage"
    echo "=========================================================="
    echo "Attention : $reason"
    if [ -f /root/arrera-blue-lynx-install.log ]; then
        echo "--- Dernières lignes (/root/arrera-blue-lynx-install.log) ---"
        tail -n 20 /root/arrera-blue-lynx-install.log || true
        echo "------------------------------------------------------------"
    fi
    echo "Que souhaitez-vous faire ?"
    echo "  1) Relancer l'assistant de configuration"
    echo "  2) Ouvrir une invite de commande (bash)"
    echo "  3) Redémarrer l'ordinateur (reboot)"
    echo "  4) Éteindre l'ordinateur (poweroff)"
    echo "=========================================================="
    read -r -p "Votre choix [1-4] (défaut: 1): " CHOICE || CHOICE=1
    case "$CHOICE" in
        2)
            exec /bin/bash
            ;;
        3)
            systemctl reboot || reboot
            ;;
        4)
            systemctl poweroff || poweroff
            ;;
        1|*)
            exec "$0" "$EDITION"
            ;;
    esac
}

if [ ! -x "$OOBE_BIN" ]; then
    on_oobe_error_prompt "Binaire Arrera Blue Lynx introuvable ($OOBE_BIN)."
    exit 1
fi

run_oobe_session() {
    if [ "$OOBE_MODE" = "cli" ]; then
        setterm -cursor on >/dev/tty1 2>/dev/null || true
        "$OOBE_BIN" </dev/tty1 >/dev/tty1 2>&1
        return $?
    fi

    setterm -cursor off >/dev/tty1 2>/dev/null || true

    local runner=()
    if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && command -v dbus-run-session >/dev/null 2>&1; then
        runner=(dbus-run-session --)
    fi

    if command -v cage >/dev/null 2>&1; then
        # --windowed évite l'appel prématuré xdg_toplevel_set_fullscreen avant surface->initialized dans Cage/wlroots (Cage force déjà le plein écran)
        "${runner[@]}" cage -s -- "$OOBE_BIN" --windowed
    elif command -v sway >/dev/null 2>&1; then
        "${runner[@]}" sway --config /dev/null -c "$OOBE_BIN"
    elif command -v xinit >/dev/null 2>&1; then
        export DISPLAY="${DISPLAY:-:0}"
        "${runner[@]}" xinit "$OOBE_BIN" -- :0 vt1
    else
        "${runner[@]}" "$OOBE_BIN"
    fi
}

clear >/dev/tty1 2>/dev/null || true
plymouth quit 2>/dev/null || true

set +e
run_oobe_session
OOBE_RC=$?
set -e

# Vérifier qu'au moins un compte utilisateur réel (UID >= 1000) a bien été créé
CREATED_USER="$(awk -F: '$3 >= 1000 && $1 != "nobody" && $1 != "arrera" && $1 != "arrera-setup" {print $1; exit}' /etc/passwd || true)"

if [ "$OOBE_RC" -ne 0 ] || [ -z "$CREATED_USER" ]; then
    on_oobe_error_prompt "Configuration incomplète (code=$OOBE_RC, utilisateur='$CREATED_USER')."
    exit 0
fi

# Nettoyage définitif du service OOBE de premier démarrage
systemctl disable arrera-oobe.service 2>/dev/null || true
rm -f /etc/systemd/system/arrera-oobe.service
rm -f /etc/systemd/system/multi-user.target.wants/arrera-oobe.service
rm -f /etc/arrera-oobe-edition
rm -f /usr/local/bin/arrera-oobe.sh
systemctl daemon-reload 2>/dev/null || true

# Configuration de la cible finale selon le mode (Desktop vs Serveur)
if [ "$OOBE_MODE" = "gui" ]; then
    systemctl set-default graphical.target 2>/dev/null || ln -sf /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target
    systemctl enable gdm 2>/dev/null || ln -sf /usr/lib/systemd/system/gdm.service /etc/systemd/system/display-manager.service
else
    systemctl set-default multi-user.target 2>/dev/null || ln -sf /usr/lib/systemd/system/multi-user.target /etc/systemd/system/default.target
fi

# Redémarrage requis uniquement si un nouveau noyau CachyOS vient d'être installé
NEEDS_REBOOT=0
if [ -f /etc/systemd/system/arrera-cleanup-fedora-kernel.service ] || compgen -G "/boot/vmlinuz-*cachyos*" >/dev/null 2>&1; then
    case "$(uname -r)" in
        *cachyos*) ;;
        *) NEEDS_REBOOT=1 ;;
    esac
fi

if [ "$NEEDS_REBOOT" -eq 1 ]; then
    systemctl reboot || reboot
    exit 0
fi

# Bascule immédiate sans redémarrage : GDM sur Desktop, getty@tty1 sur Serveur
if [ "$OOBE_MODE" = "gui" ]; then
    systemctl --no-block isolate graphical.target 2>/dev/null || systemctl --no-block start gdm.service 2>/dev/null || true
else
    systemctl --no-block start getty@tty1.service 2>/dev/null || true
fi
exit 0
