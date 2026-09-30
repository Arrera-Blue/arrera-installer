#!/usr/bin/env bash
# ==============================================================================
# Arrera Linux - Script de lancement en mode DEBUG pour tester l'installateur
# Installe les dépendances nécessaires, déploie la configuration de l'édition choisie
# et lance Calamares en mode debug (-d) pour tester les interfaces graphiques.
# ==============================================================================

set -e

# Couleurs pour le terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}${BOLD}==========================================================${NC}"
echo -e "${CYAN}${BOLD}       Arrera Linux - Test & Débogage Installateur        ${NC}"
echo -e "${BLUE}${BOLD}==========================================================${NC}"

usage() {
    echo -e "${BOLD}Usage:${NC} $0 [OPTIONS]"
    echo ""
    echo -e "${BOLD}Description:${NC}"
    echo "  Ce script prépare la machine de test en installant Calamares et"
    echo "  ses dépendances, déploie l'édition Arrera choisie, puis"
    echo "  exécute l'installateur en mode debug pour tester les interfaces."
    echo ""
    echo -e "${BOLD}Options d'édition :${NC}"
    echo -e "  ${GREEN}--edition, -e <nom>${NC} Spécifie la déclinaison à tester :"
    echo -e "                       ${CYAN}home${NC}        : Arrera Blue Édition Home (Bleu GNOME - Thème Blanc)"
    echo -e "                       ${CYAN}education${NC}   : Arrera Blue Édition Éducation (Turquoise GNOME - Thème Blanc)"
    echo -e "                       ${CYAN}server${NC}      : Arrera Blue Édition Serveur (Black GNOME - Thème Blanc)"
    echo -e "                       ${CYAN}enterprise${NC}  : Arrera Blue Édition Entreprise (Purple GNOME - Thème Blanc)"
    echo -e "                       (défaut: ${CYAN}home${NC})"
    echo ""
    echo -e "${BOLD}Options d'exécution :${NC}"
    echo -e "  ${GREEN}--dry-run, --demo${NC}    Mode simulation SÉCURISÉ (retire le formatage et copie disque)"
    echo -e "  ${GREEN}--kiosk, -k${NC}          Force le lancement en session kiosque plein écran (Cage / Wayland)"
    echo -e "  ${GREEN}--setup-only, -s${NC}     Installe les dépendances et déploie les fichiers sans lancer"
    echo -e "  ${GREEN}--no-deps${NC}            Saute la vérification/installation des paquets DNF"
    echo -e "  ${GREEN}--wifi, -w${NC}            Teste l'assistant graphique de connexion Wi-Fi"
    echo -e "  ${GREEN}--help, -h${NC}           Affiche cette aide"
    echo ""
}

# Gestion des privilèges sudo/root
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo -e "${RED}Erreur : Ce script nécessite les privilèges root ou la commande sudo.${NC}"
        exit 1
    fi
fi

# Arguments par défaut
FORCE_KIOSK=0
SKIP_DEPS=0
SETUP_ONLY=0
DRY_RUN=0
EDITION="home"

while [ $# -gt 0 ]; do
    case "$1" in
        --edition|-e)
            if [ -n "$2" ] && [[ ! "$2" =~ ^-- ]]; then
                EDITION="$2"
                shift 2
            else
                echo -e "${RED}Erreur : L'option --edition requiert un argument (home, education, server, enterprise).${NC}"
                exit 1
            fi
            ;;
        --dry-run|--demo)
            DRY_RUN=1
            shift
            ;;
        --kiosk|-k)
            FORCE_KIOSK=1
            shift
            ;;
        --setup-only|-s)
            SETUP_ONLY=1
            shift
            ;;
        --no-deps)
            SKIP_DEPS=1
            shift
            ;;
        --wifi|-w)
            echo -e "${CYAN}--> Test direct de l'assistant Wi-Fi Arrera...${NC}"
            if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
                if command -v cage >/dev/null 2>&1; then
                    echo -e "${GREEN}Démarrage de Cage (Wayland) pour afficher l'interface graphique Wi-Fi...${NC}"
                    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/0}"
                    $SUDO mkdir -p "$XDG_RUNTIME_DIR" && $SUDO chmod 0700 "$XDG_RUNTIME_DIR"
                    export XDG_SESSION_TYPE="wayland"
                    export QT_QPA_PLATFORM="wayland"
                    export GDK_BACKEND="wayland"
                    export LIBGL_ALWAYS_SOFTWARE=1
                    export WLR_LIBINPUT_NO_DEVICES=1
                    export WLR_RENDERER=pixman
                    $SUDO env \
                        XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
                        XDG_SESSION_TYPE="wayland" \
                        GDK_BACKEND="wayland" \
                        LIBGL_ALWAYS_SOFTWARE=1 \
                        WLR_LIBINPUT_NO_DEVICES=1 \
                        WLR_RENDERER=pixman \
                        cage -s -- python3 "$SCRIPT_DIR/kiosk/arrera-wifi-setup.py" --force
                    exit 0
                fi
            fi
            python3 "$SCRIPT_DIR/kiosk/arrera-wifi-setup.py" --force
            exit 0
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Option inconnue : $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Normalisation du nom de l'édition
case "$EDITION" in
    home|default)
        EDITION="home"
        EDITION_TITLE="Arrera Blue Édition Home 2026"
        SETTINGS_SRC="config/settings-home.conf"
        ;;
    education|edu)
        EDITION="education"
        EDITION_TITLE="Arrera Blue Édition Éducation 2026"
        SETTINGS_SRC="config/settings-education.conf"
        ;;
    server|srv)
        EDITION="server"
        EDITION_TITLE="Arrera Blue Édition Serveur 2026"
        SETTINGS_SRC="config/settings-server.conf"
        ;;
    enterprise|pro)
        EDITION="enterprise"
        EDITION_TITLE="Arrera Blue Édition Entreprise 2026"
        SETTINGS_SRC="config/settings-enterprise.conf"
        ;;
    *)
        echo -e "${RED}Édition inconnue : '$EDITION'. Choix possibles : home, education, server, enterprise${NC}"
        exit 1
        ;;
esac

echo -e "${MAGENTA}${BOLD}--> Déclinaison sélectionnée : ${EDITION_TITLE}${NC}"

# ==============================================================================
# 1. Vérification et installation des dépendances système
# ==============================================================================
if [ "$SKIP_DEPS" -eq 0 ]; then
    echo -e "\n${CYAN}--> [1/3] Vérification des paquets requis pour Calamares & Arrera...${NC}"
    
    PKG_MGR=""
    if command -v dnf5 >/dev/null 2>&1; then
        PKG_MGR="dnf5"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MGR="dnf"
    fi

    REQUIRED_PKGS=(
        calamares
        cage
        make
        python3-pyyaml
        abattis-cantarell-fonts
        adwaita-cursor-theme
        qt6-qtdeclarative
    )

    MISSING_PKGS=()
    for PKG in "${REQUIRED_PKGS[@]}"; do
        if ! rpm -q "$PKG" >/dev/null 2>&1; then
            MISSING_PKGS+=("$PKG")
        fi
    done

    if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
        if [ -n "$PKG_MGR" ]; then
            echo -e "${YELLOW}Installation des paquets manquants (${MISSING_PKGS[*]})...${NC}"
            $SUDO "$PKG_MGR" install -y "${MISSING_PKGS[@]}"
            echo -e "${GREEN}✓ Paquets installés avec succès.${NC}"
        else
            echo -e "${YELLOW}Avertissement : Gestionnaire DNF non trouvé. Assurez-vous que Calamares est installé.${NC}"
        fi
    else
        echo -e "${GREEN}✓ Toutes les dépendances sont déjà installées.${NC}"
    fi
else
    echo -e "\n${YELLOW}--> [1/3] Étape des dépendances ignorée (--no-deps).${NC}"
fi

# ==============================================================================
# 2. Déploiement local des brandings et configuration
# ==============================================================================
echo -e "\n${CYAN}--> [2/3] Déploiement des fichiers et activation de l'édition ${EDITION_TITLE}...${NC}"
$SUDO make install

# Activation du settings.conf propre à l'édition demandée
if [ -f "$SETTINGS_SRC" ]; then
    $SUDO cp "$SETTINGS_SRC" /etc/calamares/settings.conf
    echo -e "${GREEN}✓ Fichier /etc/calamares/settings.conf configuré (branding: arrera-${EDITION}).${NC}"
else
    echo -e "${RED}Erreur: Fichier de configuration $SETTINGS_SRC introuvable.${NC}"
    exit 1
fi

# Copie de sécurité explicite des fichiers QML vers /usr/share/calamares/branding/
if [ -d "branding/arrera-${EDITION}" ]; then
    $SUDO cp -f branding/arrera-${EDITION}/*.qml "/usr/share/calamares/branding/arrera-${EDITION}/" 2>/dev/null || true
fi

# Liens symboliques directs pour garantir l'accès au branding et à qml depuis /etc/calamares
$SUDO rm -rf /etc/calamares/branding /etc/calamares/qml
$SUDO ln -sfn /usr/share/calamares/branding /etc/calamares/branding
$SUDO ln -sfn /usr/share/calamares/qml /etc/calamares/qml
$SUDO mkdir -p /run/rootfsbase

echo -e "${GREEN}✓ Fichiers et liens symboliques installés dans /etc/calamares et /usr/share/calamares.${NC}"

if [ "$SETUP_ONLY" -eq 1 ]; then
    echo -e "\n${GREEN}${BOLD}Configuration terminée avec succès (--setup-only).${NC}"
    exit 0
fi

# ==============================================================================
# 3. Gestion du mode Simulation (--dry-run)
# ==============================================================================
restore_settings() {
    if [ -f /etc/calamares/settings.conf.real_backup ]; then
        echo -e "\n${CYAN}Restauration de la configuration d'origine...${NC}"
        $SUDO mv -f /etc/calamares/settings.conf.real_backup /etc/calamares/settings.conf 2>/dev/null || true
    fi
}

if [ "$DRY_RUN" -eq 1 ]; then
    echo -e "\n${GREEN}${BOLD}[MODE SIMULATION SÉCURISÉ ACTIVÉ]${NC}"
    echo -e "${GREEN}Les modules de formatage et d'écriture disque réelle (partition, mount, unpackfs, bootloader) sont neutralisés.${NC}"
    
    $SUDO cp -f /etc/calamares/settings.conf /etc/calamares/settings.conf.real_backup
    trap restore_settings EXIT INT TERM

    $SUDO python3 -c "
import yaml
with open('/etc/calamares/settings.conf', 'r') as f:
    data = yaml.safe_load(f)

destructive = {'partition', 'mount', 'unpackfs', 'fstab', 'bootloader', 'shellprocess@postinstall', 'umount'}
new_seq = []
for entry in data.get('sequence', []):
    if 'exec' in entry:
        safe_jobs = [job for job in entry['exec'] if job not in destructive]
        if safe_jobs:
            new_seq.append({'exec': safe_jobs})
    else:
        new_seq.append(entry)

data['sequence'] = new_seq
with open('/etc/calamares/settings.conf', 'w') as f:
    yaml.dump(data, f, default_flow_style=False)
"
    echo -e "${GREEN}✓ Configuration modifiée : aucun disque ne sera formaté.${NC}"
else
    echo -e "\n${YELLOW}${BOLD}[MODE D'INSTALLATION STANDARD]${NC}"
    echo -e "${YELLOW}- Vous pouvez naviguer dans les écrans tant que vous ne validez pas le bouton 'Installer' sur le résumé.${NC}"
    echo -e "${RED}- Si vous confirmez l'installation, le disque sélectionné sera formaté !${NC}"
    echo -e "${CYAN}- Pour tester sans risque : ${BOLD}./debug.sh --edition ${EDITION} --dry-run${NC}\n"
fi

# ==============================================================================
# 4. Détection du type d'environnement (Console pure vs Bureau graphique)
# ==============================================================================
CALAMARES_BIN="$(command -v calamares || echo "/usr/bin/calamares")"

if [ ! -x "$CALAMARES_BIN" ]; then
    echo -e "${RED}Erreur critique: Binaire Calamares non trouvé ($CALAMARES_BIN).${NC}"
    exit 1
fi

# Nettoyage de l'ancien journal pour garantir un diagnostic fiable
$SUDO rm -f /root/.cache/calamares/session.log "$HOME/.cache/calamares/session.log" 2>/dev/null || true

HAS_DISPLAY=0
if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
    HAS_DISPLAY=1
fi

if [ "$FORCE_KIOSK" -eq 1 ] || [ "$HAS_DISPLAY" -eq 0 ]; then
    # ==========================================================================
    # CAS A : Console pure / TTY (Lancement via Cage - Compositeur Wayland)
    # ==========================================================================
    echo -e "\n${CYAN}--> [3/3] Console pure détectée : démarrage du compositeur Wayland Kiosque (Cage)...${NC}"
    
    if ! command -v cage >/dev/null 2>&1; then
        echo -e "${RED}Erreur : 'cage' n'est pas installé. Installation en cours via DNF...${NC}"
        if [ -n "$PKG_MGR" ]; then
            $SUDO "$PKG_MGR" install -y cage
        fi
    fi

    # Variables d'environnement pour Cage et Qt sous Wayland en root
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/0}"
    $SUDO mkdir -p "$XDG_RUNTIME_DIR"
    $SUDO chmod 0700 "$XDG_RUNTIME_DIR"
    export XDG_SESSION_TYPE="wayland"
    export QT_QPA_PLATFORM="wayland"
    export GDK_BACKEND="wayland"
    export XDG_CURRENT_DESKTOP="GNOME"
    export QT_QPA_PLATFORMTHEME="gnome"
    export GTK_THEME="Adwaita"
    export XCURSOR_THEME="Adwaita"
    export XCURSOR_SIZE="24"
    
    # Compatibilité VM sans GPU matériel 3D (VirtualBox, QEMU, Proxmox)
    export LIBGL_ALWAYS_SOFTWARE=1
    export WLR_LIBINPUT_NO_DEVICES=1
    export WLR_RENDERER=pixman

    # Clavier AZERTY par défaut
    export XKB_DEFAULT_LAYOUT="fr"
    export XKB_DEFAULT_MODEL="pc105"

    echo -e "${GREEN}Lancement plein écran de Calamares dans Cage (${EDITION_TITLE})...${NC}\n"
    
    set +e
    $SUDO env \
        XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
        XDG_SESSION_TYPE="wayland" \
        QT_QPA_PLATFORM="wayland" \
        GDK_BACKEND="wayland" \
        LIBGL_ALWAYS_SOFTWARE=1 \
        WLR_LIBINPUT_NO_DEVICES=1 \
        WLR_RENDERER=pixman \
        XKB_DEFAULT_LAYOUT="fr" \
        XKB_DEFAULT_MODEL="pc105" \
        cage -s -- "$CALAMARES_BIN" -d -c /etc/calamares
    
    EXIT_CODE=$?
    set -e

else
    # ==========================================================================
    # CAS B : Bureau graphique existant (GNOME / X11 / Wayland)
    # ==========================================================================
    echo -e "\n${CYAN}--> [3/3] Démarrage de Calamares en mode fenêtré (-d)...${NC}"
    echo -e "${BOLD}Configuration :${NC} /etc/calamares/settings.conf (${EDITION_TITLE})"
    echo -e "${BOLD}Logs en direct :${NC}\n"
    
    if command -v xhost >/dev/null 2>&1; then
        xhost +si:localuser:root >/dev/null 2>&1 || true
        xhost +local:root >/dev/null 2>&1 || true
    fi

    set +e
    $SUDO env \
        DISPLAY="$DISPLAY" \
        WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
        XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" \
        QT_QPA_PLATFORM="xcb" \
        QT_QPA_PLATFORMTHEME="gnome" \
        GTK_THEME="Adwaita" \
        XCURSOR_THEME="Adwaita" \
        "$CALAMARES_BIN" -d -c /etc/calamares
    
    EXIT_CODE=$?
    set -e
fi

# ==============================================================================
# Diagnostic de sortie
# ==============================================================================
if [ "$EXIT_CODE" -ne 0 ]; then
    echo -e "\n${RED}${BOLD}Calamares s'est arrêté avec le code d'erreur : $EXIT_CODE${NC}"
    for LOG_FILE in "/root/.cache/calamares/session.log" "$HOME/.cache/calamares/session.log"; do
        if [ -f "$LOG_FILE" ]; then
            echo -e "${YELLOW}--- Dernières lignes du journal ($LOG_FILE) : ---${NC}"
            tail -n 35 "$LOG_FILE"
            echo -e "${YELLOW}------------------------------------------------${NC}"
            break
        fi
    done
    exit "$EXIT_CODE"
fi

echo -e "\n${GREEN}Session Calamares terminée avec succès pour ${EDITION_TITLE}.${NC}"
