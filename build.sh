#!/usr/bin/bash
# ==============================================================================
# Arrera Linux - Script de construction d'arrera-installer
# Compile et génère les paquets RPM / SRPM dans le dossier output/
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

# Répertoire du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

OUTPUT_DIR="output"

# Bannière
echo -e "${BLUE}${BOLD}==========================================================${NC}"
echo -e "${CYAN}${BOLD}       Arrera Linux - Constructeur de paquets RPM         ${NC}"
echo -e "${BLUE}${BOLD}==========================================================${NC}"

usage() {
    echo -e "${BOLD}Usage:${NC} $0 [OPTION]"
    echo ""
    echo -e "${BOLD}Options disponibles :${NC}"
    echo -e "  ${GREEN}(sans argument)${NC}  Exécute les tests et génère le RPM binaire + SRPM dans ${CYAN}${OUTPUT_DIR}/${NC}"
    echo -e "  ${GREEN}--srpm${NC}           Génère uniquement le paquet source (SRPM) pour COPR"
    echo -e "  ${GREEN}--test${NC}           Exécute uniquement les tests et vérifications"
    echo -e "  ${GREEN}--clean${NC}          Nettoie les dossiers temporaires et le dossier output/"
    echo -e "  ${GREEN}--help${NC}           Affiche cette aide"
    echo ""
}

# Vérification des outils nécessaires
check_dependencies() {
    echo -e "${CYAN}--> Vérification des dépendances de compilation...${NC}"
    MISSING=0
    for CMD in rpmbuild make python3; do
        if ! command -v "$CMD" >/dev/null 2>&1; then
            echo -e "${RED}Erreur: la commande '$CMD' est introuvable.${NC}"
            MISSING=1
        fi
    done

    if [ "$MISSING" -eq 1 ]; then
        echo -e "${YELLOW}Veuillez installer les outils requis avec :${NC}"
        echo -e "  sudo dnf install -y rpm-build make python3-pyyaml"
        exit 1
    fi
    echo -e "${GREEN}✓ Outils de compilation prêts.${NC}"
}

# Gestion des arguments
MODE="rpm"

case "$1" in
    --help|-h)
        usage
        exit 0
        ;;
    --clean|-c)
        echo -e "${YELLOW}--> Nettoyage des artefacts de compilation...${NC}"
        make clean
        echo -e "${GREEN}✓ Nettoyage terminé.${NC}"
        exit 0
        ;;
    --test|-t)
        check_dependencies
        make test
        exit 0
        ;;
    --srpm|-s)
        MODE="srpm"
        ;;
    "")
        MODE="rpm"
        ;;
    *)
        echo -e "${RED}Option inconnue : $1${NC}"
        usage
        exit 1
        ;;
esac

check_dependencies

# Étape 1 : Validation
echo ""
echo -e "${CYAN}--> Exécution des vérifications et tests de conformité...${NC}"
make test

# Étape 2 : Construction
echo ""
mkdir -p "$OUTPUT_DIR"

if [ "$MODE" = "srpm" ]; then
    echo -e "${CYAN}--> Construction du paquet SRPM...${NC}"
    make srpm
else
    echo -e "${CYAN}--> Construction des paquets RPM (noarch) et SRPM...${NC}"
    make rpm
fi

# Étape 3 : Résumé
echo ""
echo -e "${GREEN}${BOLD}==========================================================${NC}"
echo -e "${GREEN}${BOLD}       Compilation réussie avec succès !                  ${NC}"
echo -e "${GREEN}${BOLD}==========================================================${NC}"
echo -e "${BOLD}Fichiers générés dans le dossier ${CYAN}${OUTPUT_DIR}/${NC} :${BOLD}"
ls -lh "$OUTPUT_DIR" | awk 'NR>1 {print "  - " $9 " (" $5 ")"}'

echo ""
echo -e "${YELLOW}Pour soumettre le SRPM à votre dépôt COPR :${NC}"
SRPM_FILE=$(ls -1 "$OUTPUT_DIR"/*.src.rpm 2>/dev/null | head -n 1 || true)
if [ -n "$SRPM_FILE" ]; then
    echo -e "  ${BOLD}copr-cli build copr-arrera-blue $SRPM_FILE${NC}"
fi

echo -e "${YELLOW}Pour installer localement le RPM binaire :${NC}"
RPM_FILE=$(ls -1 "$OUTPUT_DIR"/*.noarch.rpm 2>/dev/null | head -n 1 || true)
if [ -n "$RPM_FILE" ]; then
    echo -e "  ${BOLD}sudo dnf install -y $RPM_FILE${NC}"
fi
echo ""
