#!/usr/bin/env bash
# ==============================================================================
# Arrera Linux - Script de lancement en mode DEBUG pour tester l'installateur
# Installe les dépendances nécessaires, déploie les fichiers de configuration
# et lance Calamares en mode debug (-d) pour tester les interfaces graphiques.
# ==============================================================================

set -e

# Couleurs pour le terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}${BOLD}==========================================================${NC}"
echo -e "${CYAN}${BOLD}       Arrera Linux - Test & Débogage Installateur        ${NC}"
echo -e "${BLUE}${BOLD}==========================================================${NC}"

usage() {
    echo -e "${BOLD}Usage:${NC} $0 [OPTION]"
    echo ""
    echo -e "${BOLD}Description:${NC}"
    echo "  Ce script prépare la machine de test en installant Calamares et"
    echo "  ses dépendances, déploie la configuration Arrera Blue, puis"
    echo "  exécute l'installateur en mode debug pour tester les interfaces."
    echo ""
    echo -e "${BOLD}Options :${NC}"
    echo -e "  ${GREEN}(sans option)${NC}      Installe si nécessaire, déploie et lance en mode fenêtré"
    echo -e "  ${GREEN}--dry-run, --demo${NC}  Mode simulation SÉCURISÉ (désactive toute écriture disque lors de l'installation)"
    echo -e "  ${GREEN}--kiosk, -k${NC}        Force le lancement en mode kiosque plein écran (Cage / Wayland)"
    echo -e "  ${GREEN}--setup-only, -s${NC}   Installe les dépendances et déploie les fichiers sans lancer"
    echo -e "  ${GREEN}--no-deps${NC}          Saute la vérification/installation des paquets DNF"
    echo -e "  ${GREEN}--help, -h${NC}         Affiche cette aide"
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

# Arguments
MODE="window"
SKIP_DEPS=0
SETUP_ONLY=0
DRY_RUN=0

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run|--demo)
            DRY_RUN=1
            shift
            ;;
        --kiosk|-k)
            MODE="kiosk"
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
            echo -e "${YELLOW}Avertissement : Gestionnaire DNF non trouvé. Veuillez vous assurer que Calamares est installé.${NC}"
        fi
    else
        echo -e "${GREEN}✓ Toutes les dépendances sont déjà installées.${NC}"
    fi
else
    echo -e "\n${YELLOW}--> [1/3] Étape des dépendances ignorée (--no-deps).${NC}"
fi

# ==============================================================================
# 2. Déploiement local de la configuration et du branding Arrera
# ==============================================================================
echo -e "\n${CYAN}--> [2/3] Déploiement des fichiers de configuration et branding Arrera...${NC}"
$SUDO make install

# Préparation du dossier QML requis
$SUDO mkdir -p /usr/share/calamares/qml
$SUDO mkdir -p /run/rootfsbase

echo -e "${GREEN}✓ Fichiers installés dans /etc/calamares et /usr/share/calamares.${NC}"

if [ "$SETUP_ONLY" -eq 1 ]; then
    echo -e "\n${GREEN}${BOLD}Configuration terminée avec succès (--setup-only).${NC}"
    exit 0
fi

# ==============================================================================
# 3. Mode Simulation (--dry-run) : Neutralisation de la séquence d'exécution
# ==============================================================================
restore_settings() {
    if [ -f /etc/calamares/settings.conf.real_backup ]; then
        echo -e "\n${CYAN}Restauration de la configuration de production /etc/calamares/settings.conf...${NC}"
        $SUDO mv /etc/calamares/settings.conf.real_backup /etc/calamares/settings.conf
    fi
}

if [ "$DRY_RUN" -eq 1 ]; then
    echo -e "\n${GREEN}${BOLD}[MODE SIMULATION ACTIVÉ]${NC}"
    echo -e "${GREEN}Toutes les opérations d'écriture disque réelles sont désactivées.${NC}"
    echo -e "${GREEN}Vous pouvez tester l'ensemble du parcours et cliquer sur 'Installer' sans aucun risque pour le disque.${NC}"
    
    $SUDO cp /etc/calamares/settings.conf /etc/calamares/settings.conf.real_backup
    trap restore_settings EXIT INT TERM

    # Création d'une configuration sans la phase d'exécution destructrice
    $SUDO python3 -c "
import yaml
with open('/etc/calamares/settings.conf', 'r') as f:
    data = yaml.safe_load(f)
# Neutralisation de la séquence exec
data['sequence'] = [
    step for step in data.get('sequence', [])
    if 'exec' not in step
]
# Ajout d'une séquence exec vide pour valider la transition vers finished
data['sequence'].append({'exec': []})
data['sequence'].append({'show': ['finished']})
with open('/etc/calamares/settings.conf', 'w') as f:
    yaml.dump(data, f, default_flow_style=False)
"
else
    echo -e "\n${YELLOW}${BOLD}[ATTENTION - MODE STANDARD]${NC}"
    echo -e "${YELLOW}- Vous pouvez naviguer librement et configurer les partitions sans risque tant que vous ne cliquez pas sur 'Installer'.${NC}"
    echo -e "${RED}- Si vous cliquez sur 'Installer maintenant' à la fin, LE DISQUE SÉLECTIONNÉ SERA RÉELLEMENT FORMATÉ !${NC}"
    echo -e "${CYAN}- Astuce : Pour simuler une installation complète sans risque, relancez avec : ${BOLD}./debug.sh --dry-run${NC}\n"
fi

# ==============================================================================
# 4. Lancement de Calamares en mode DEBUG
# ==============================================================================
echo -e "${CYAN}--> Démarrage de Calamares en mode debug (-d)...${NC}"

# Permissions pour le serveur X11 si exécuté via sudo depuis un bureau utilisateur
if [ -n "$DISPLAY" ] && command -v xhost >/dev/null 2>&1; then
    xhost +local:root >/dev/null 2>&1 || true
fi

# Détection de l'affichage
HAS_DISPLAY=0
if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
    HAS_DISPLAY=1
fi

if [ "$MODE" = "kiosk" ] || [ "$HAS_DISPLAY" -eq 0 ]; then
    echo -e "${YELLOW}Lancement en session Kiosque via Cage / Wayland...${NC}"
    if [ -x "./kiosk/arrera-installer-kiosk.sh" ]; then
        $SUDO ./kiosk/arrera-installer-kiosk.sh
    else
        $SUDO /usr/bin/arrera-installer-kiosk.sh
    fi
else
    echo -e "${GREEN}Lancement en mode fenêtré interactif (-d)...${NC}"
    echo -e "${BOLD}Note :${NC} Consultez les logs en direct ci-dessous ou dans ${CYAN}~/.cache/calamares/session.log${NC}\n"
    
    # Préservation de l'environnement graphique lors de l'élévation sudo
    $SUDO -E env \
        QT_QPA_PLATFORM="wayland;xcb" \
        QT_QPA_PLATFORMTHEME="gnome" \
        GTK_THEME="Adwaita" \
        XCURSOR_THEME="Adwaita" \
        calamares -d
fi

echo -e "\n${GREEN}Session de test Calamares terminée.${NC}"
