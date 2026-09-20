#!/bin/bash
# ==============================================================================
# Arrera Linux - Finalisation post-installation Calamares (chroot cible)
# Aligne le système installé sur la configuration officielle Arrera (identique Anaconda)
# ==============================================================================
set -e

echo "=========================================================="
echo "   Arrera Linux - Finalisation post-installation"
echo "=========================================================="

# 1. Vérification réseau et mise à jour DNF (Option A)
echo "[1/7] Test de la connectivité Internet..."
if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    echo "-> Connexion Internet active détectée !"
    echo "-> Rafraîchissement des dépôts et mise à jour des paquets Arrera..."
    dnf makecache -y || true
    dnf upgrade -y --refresh || true
    echo "-> Système mis à jour avec succès."
else
    echo "-> Aucune connexion Internet détectée (ou mode hors-ligne)."
    echo "-> Étape réseau ignorée : installation locale directe."
fi

# 2. Forcer la cible graphique (GDM / GNOME)
echo "[2/7] Configuration du démarrage graphique (GDM)..."
systemctl set-default graphical.target 2>/dev/null || ln -sf /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target
systemctl enable gdm 2>/dev/null || ln -sf /usr/lib/systemd/system/gdm.service /etc/systemd/system/display-manager.service

# 3. Désactiver et supprimer définitivement le mode kiosque
echo "[3/7] Nettoyage des composants Kiosque Live..."
systemctl disable arrera-kiosk.service 2>/dev/null || true
rm -f /etc/systemd/system/arrera-kiosk.service
rm -f /etc/systemd/system/multi-user.target.wants/arrera-kiosk.service
rm -f /usr/bin/arrera-installer-kiosk.sh

# 4. Supprimer tout autologin GDM résiduel
echo "[4/7] Réinitialisation de la configuration de connexion GDM..."
rm -f /etc/gdm/custom.conf

# 5. Nettoyer le compte Live temporaire 'arrera' si un utilisateur a été créé
echo "[5/7] Vérification des comptes utilisateurs..."
OTHER_USER=$(awk -F: '$3 >= 1000 && $1 != "arrera" && $1 != "nobody" {print $1}' /etc/passwd | head -n 1)
if [ -n "$OTHER_USER" ]; then
    echo "-> Utilisateur principal installé détecté : $OTHER_USER"
    echo "-> Suppression du compte temporaire live 'arrera'..."
    pkill -9 -u arrera 2>/dev/null || true
    userdel -r -f arrera 2>/dev/null || true
    rm -rf /home/arrera
    rm -f /etc/sudoers.d/arrera
fi

# 6. Nettoyage des raccourcis et fichiers d'installation résiduels
echo "[6/7] Nettoyage des raccourcis d'installation..."
rm -f /home/*/Bureau/install-*.desktop /home/*/Desktop/install-*.desktop 2>/dev/null || true
rm -f /home/*/.config/autostart/install-*.desktop 2>/dev/null || true
rm -f /etc/xdg/autostart/install-*.desktop 2>/dev/null || true
rm -f /usr/share/applications/calamares*.desktop 2>/dev/null || true

# 7. Actualiser les caches système (dconf et icônes)
echo "[7/7] Application des réglages d'environnement Arrera..."
if command -v dconf >/dev/null 2>&1; then
    dconf update 2>/dev/null || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
fi

# Auto-nettoyage du script
rm -f /usr/bin/arrera-postinstall.sh 2>/dev/null || true

echo "=========================================================="
echo "   Système Arrera installé avec succès et prêt !"
echo "=========================================================="
exit 0
