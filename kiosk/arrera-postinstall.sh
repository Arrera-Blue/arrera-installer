#!/bin/bash
# ==============================================================================
# Arrera Linux - Finalisation post-installation Calamares (chroot cible)
# Aligne le système installé sur la configuration officielle Arrera (identique Anaconda)
# ==============================================================================
set -e

echo "=========================================================="
echo "   Arrera Linux - Finalisation post-installation"
echo "=========================================================="

# 1. Vérification réseau et mise à jour DNF (Option A - compatible VirtualBox NAT & QEMU)
echo "[1/8] Test de la connectivité Internet..."
# Configuration temporaire d'un DNS fiable pour le chroot
cp -f /etc/resolv.conf /etc/resolv.conf.bak 2>/dev/null || true
cat > /etc/resolv.conf << 'DNS_EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
DNS_EOF

IS_ONLINE=0
if curl -s --connect-timeout 4 -m 6 https://fedoraproject.org >/dev/null 2>&1 || \
   curl -s --connect-timeout 4 -m 6 https://google.com >/dev/null 2>&1 || \
   curl -s --connect-timeout 3 -m 5 http://1.1.1.1 >/dev/null 2>&1 || \
   ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
    IS_ONLINE=1
fi

if [ "$IS_ONLINE" -eq 1 ]; then
    echo "-> Connexion Internet confirmée !"
    echo "-> Rafraîchissement des dépôts et mise à jour des paquets Arrera..."
    dnf makecache -y || true
    dnf upgrade -y --refresh || true
    echo "-> Système mis à jour avec succès."
else
    echo "-> Aucune connexion Internet détectée (ou mode hors-ligne)."
    echo "-> Étape réseau ignorée : installation locale directe."
fi

# Restauration du resolv.conf d'origine pour systemd-resolved
if [ -f /etc/resolv.conf.bak ]; then
    mv -f /etc/resolv.conf.bak /etc/resolv.conf 2>/dev/null || true
fi

# 2. Configuration et masquage complet de GRUB (aucun menu affiché au démarrage)
echo "[2/8] Configuration du chargeur GRUB (menu masqué)..."
mkdir -p /etc/default
if [ -f /etc/default/grub ]; then
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
    if grep -q '^GRUB_TIMEOUT_STYLE=' /etc/default/grub; then
        sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub
    else
        echo 'GRUB_TIMEOUT_STYLE=hidden' >> /etc/default/grub
    fi
    if ! grep -q 'splash' /etc/default/grub; then
        sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="splash /' /etc/default/grub
    fi
else
    cat > /etc/default/grub << 'GRUB_EOF'
GRUB_TIMEOUT=0
GRUB_TIMEOUT_STYLE=hidden
GRUB_DISTRIBUTOR="Arrera Blue 2026"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_CMDLINE_LINUX="rhgb quiet splash"
GRUB_DISABLE_RECOVERY=true
GRUB_EOF
fi

# Mettre à jour les entrées BLS (Boot Loader Specification) pour inclure rhgb quiet splash
if [ -d /boot/loader/entries ]; then
    for entry in /boot/loader/entries/*.conf; do
        [ -f "$entry" ] || continue
        if ! grep -q "splash" "$entry"; then
            sed -i '/^options / s/$/ splash/' "$entry"
        fi
    done
fi

# Régénération de la configuration GRUB
if command -v grub2-mkconfig >/dev/null 2>&1; then
    grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
    if [ -d /boot/efi/EFI/fedora ]; then
        grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg 2>/dev/null || true
    fi
fi

# 3. Configuration et régénération du thème Plymouth Arrera
echo "[3/8] Application du thème de démarrage Plymouth Arrera..."
mkdir -p /etc/plymouth
cat > /etc/plymouth/plymouthd.conf << 'PLYMOUTH_EOF'
[Daemon]
Theme=arrera
ShowDelay=0
DeviceTimeout=8
PLYMOUTH_EOF

# Définir le thème et reconstruire l'initramfs pour inclure le thème
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme -R arrera 2>/dev/null || true
fi

# 4. Forcer la cible graphique (GDM / GNOME)
echo "[4/8] Configuration du démarrage graphique (GDM)..."
systemctl set-default graphical.target 2>/dev/null || ln -sf /usr/lib/systemd/system/graphical.target /etc/systemd/system/default.target
systemctl enable gdm 2>/dev/null || ln -sf /usr/lib/systemd/system/gdm.service /etc/systemd/system/display-manager.service

# 5. Désactiver et supprimer définitivement le mode kiosque
echo "[5/8] Nettoyage des composants Kiosque Live..."
systemctl disable arrera-kiosk.service 2>/dev/null || true
rm -f /etc/systemd/system/arrera-kiosk.service
rm -f /etc/systemd/system/multi-user.target.wants/arrera-kiosk.service
rm -f /usr/bin/arrera-installer-kiosk.sh

# 6. Supprimer tout autologin GDM résiduel
echo "[6/8] Réinitialisation de la configuration de connexion GDM..."
rm -f /etc/gdm/custom.conf

# 7. Nettoyer le compte Live temporaire 'arrera' si un utilisateur a été créé
echo "[7/8] Vérification des comptes utilisateurs..."
OTHER_USER=$(awk -F: '$3 >= 1000 && $1 != "arrera" && $1 != "nobody" {print $1}' /etc/passwd | head -n 1)
if [ -n "$OTHER_USER" ]; then
    echo "-> Utilisateur principal installé détecté : $OTHER_USER"
    echo "-> Suppression du compte temporaire live 'arrera'..."
    pkill -9 -u arrera 2>/dev/null || true
    userdel -r -f arrera 2>/dev/null || true
    rm -rf /home/arrera
    rm -f /etc/sudoers.d/arrera
fi

# 8. Nettoyage des raccourcis et mise à jour des caches d'environnement
echo "[8/8] Application des réglages d'environnement Arrera..."
rm -f /home/*/Bureau/install-*.desktop /home/*/Desktop/install-*.desktop 2>/dev/null || true
rm -f /home/*/.config/autostart/install-*.desktop 2>/dev/null || true
rm -f /etc/xdg/autostart/install-*.desktop 2>/dev/null || true
rm -f /usr/share/applications/calamares*.desktop 2>/dev/null || true

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
