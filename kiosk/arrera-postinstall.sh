#!/bin/bash
# ==============================================================================
# Arrera Linux - Finalisation post-installation Calamares (chroot cible)
# Aligne le système installé sur la configuration officielle Arrera (identique Anaconda)
# ==============================================================================
# set -e désactivé : les erreurs mineures ne doivent pas faire échouer Calamares
set +e

echo "=========================================================="
echo "   Arrera Linux - Finalisation post-installation"
echo "=========================================================="

# 1. Vérification réseau et mise à jour DNF (Option A - compatible VirtualBox NAT & QEMU)
echo "[1/8] Test de la connectivité Internet..."

# Sauvegarder la cible du lien symbolique resolv.conf (souvent systemd-resolved)
RESOLV_IS_LINK=0
RESOLV_TARGET=""
if [ -L /etc/resolv.conf ]; then
    RESOLV_IS_LINK=1
    RESOLV_TARGET=$(readlink /etc/resolv.conf 2>/dev/null || true)
fi

# Supprimer le lien symbolique (souvent brisé dans le chroot) avant d'écrire un fichier régulier
rm -f /etc/resolv.conf 2>/dev/null || true
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

# Restauration propre du lien symbolique resolv.conf pour systemd-resolved
rm -f /etc/resolv.conf 2>/dev/null || true
if [ "$RESOLV_IS_LINK" -eq 1 ] && [ -n "$RESOLV_TARGET" ]; then
    ln -sf "$RESOLV_TARGET" /etc/resolv.conf 2>/dev/null || true
else
    ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf 2>/dev/null || true
fi

# 2. Nettoyage des noyaux Live et configuration complète de GRUB
echo "[2/8] Nettoyage des anciens noyaux et configuration de GRUB..."

CURRENT_MACHINE_ID=$(cat /etc/machine-id 2>/dev/null || true)

# Nettoyer les entrées BLS fantômes issues de la création du média Live
if [ -n "$CURRENT_MACHINE_ID" ] && [ -d /boot/loader/entries ]; then
    for conf in /boot/loader/entries/*.conf; do
        [ -f "$conf" ] || continue
        if ! grep -q "$CURRENT_MACHINE_ID" <<< "$(basename "$conf")"; then
            echo "-> Suppression entrée BLS obsolète du Live : $(basename "$conf")"
            rm -f "$conf"
        fi
    done
fi

# Nettoyer les fichiers rescue obsolètes issus de l'ISO Live
if [ -n "$CURRENT_MACHINE_ID" ]; then
    for f in /boot/*rescue*; do
        [ -f "$f" ] || continue
        if ! grep -q "$CURRENT_MACHINE_ID" <<< "$f"; then
            echo "-> Suppression rescue obsolète du Live : $(basename "$f")"
            rm -f "$f"
        fi
    done
fi

# Supprimer les entrées rescue de BLS pour empêcher qu'elles soient démarrées par défaut
rm -f /boot/loader/entries/*rescue*.conf 2>/dev/null || true

# Restaurer os-release Arrera si la mise à jour fedora-release l'a écrasé
if [ -f /usr/share/arrera-branding/os-release ]; then
    cp -f /usr/share/arrera-branding/os-release /usr/lib/os-release 2>/dev/null || true
    cp -f /usr/share/arrera-branding/os-release /etc/os-release 2>/dev/null || true
fi

# Identifier le noyau le plus récent et le définir comme SEUL noyau par défaut
LATEST_KERNEL=$(ls -v /boot/vmlinuz-* 2>/dev/null | grep -v 'rescue' | tail -n 1 || true)
if [ -n "$LATEST_KERNEL" ]; then
    echo "-> Noyau officiel sélectionné par défaut : $LATEST_KERNEL"
    if command -v grubby >/dev/null 2>&1; then
        grubby --set-default="$LATEST_KERNEL" 2>/dev/null || true
    fi
fi

# Configuration des paramètres silencieux et Plymouth pour toutes les entrées BLS
SILENT_CMDLINE="rhgb quiet splash loglevel=3 rd.udev.log_priority=3 systemd.show_status=false vt.global_cursor_default=0"

if [ -d /boot/loader/entries ]; then
    for entry in /boot/loader/entries/*.conf; do
        [ -f "$entry" ] || continue
        # Nettoyer les anciens arguments et rd.live.image
        sed -i -E 's/\s+rd\.live\.image//g' "$entry" 2>/dev/null || true
        sed -i -E 's/\s+(rhgb|quiet|splash|loglevel=[0-9]+|rd\.udev\.log_priority=[0-9]+|systemd\.show_status=\w+|vt\.global_cursor_default=[0-9]+)//g' "$entry" 2>/dev/null || true
        sed -i "/^options / s/$/ ${SILENT_CMDLINE}/" "$entry" 2>/dev/null || true
        sed -i 's/^title Fedora.*/title Arrera Blue-dev 2026/g' "$entry" 2>/dev/null || true
        sed -i 's/^title Arrera.*/title Arrera Blue-dev 2026/g' "$entry" 2>/dev/null || true
    done
fi

if command -v grubby >/dev/null 2>&1; then
    grubby --update-kernel=ALL --remove-args="rd.live.image" 2>/dev/null || true
    grubby --update-kernel=ALL --args="${SILENT_CMDLINE}" 2>/dev/null || true
fi

# Sauvegarder la ligne de commande par défaut pour les futures mises à jour de noyau (/etc/kernel/cmdline)
ROOT_ARG=$(grep -o 'root=[^ ]*' /boot/loader/entries/*.conf 2>/dev/null | head -n 1 || true)
if [ -n "$ROOT_ARG" ]; then
    mkdir -p /etc/kernel
    echo "${ROOT_ARG} ro ${SILENT_CMDLINE}" > /etc/kernel/cmdline
fi

# Configuration stricte de /etc/default/grub pour masquer totalement le menu
mkdir -p /etc/default
cat > /etc/default/grub << 'GRUB_EOF'
GRUB_TIMEOUT=0
GRUB_TIMEOUT_STYLE=hidden
GRUB_RECORDFAIL_TIMEOUT=0
GRUB_DISTRIBUTOR="Arrera Blue-dev 2026"
GRUB_DEFAULT=0
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="rhgb quiet splash loglevel=3 rd.udev.log_priority=3 systemd.show_status=false vt.global_cursor_default=0"
GRUB_DISABLE_RECOVERY=true
GRUB_EOF

# Marquer l'environnement GRUB comme démarré avec succès pour éviter que menu_auto_hide ne force l'affichage
if command -v grub2-editenv >/dev/null 2>&1; then
    for envfile in /boot/grub2/grubenv /boot/efi/EFI/fedora/grubenv; do
        if [ -f "$envfile" ] || [ -d "$(dirname "$envfile")" ]; then
            grub2-editenv "$envfile" set menu_auto_hide=1 2>/dev/null || true
            grub2-editenv "$envfile" set boot_success=1 2>/dev/null || true
            grub2-editenv "$envfile" set boot_indeterminate=0 2>/dev/null || true
            grub2-editenv "$envfile" set saved_entry=0 2>/dev/null || true
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
mkdir -p /etc/dracut.conf.d
cat > /etc/dracut.conf.d/plymouth.conf << 'DRACUT_EOF'
add_dracutmodules+=" plymouth "
DRACUT_EOF

mkdir -p /etc/plymouth
cat > /etc/plymouth/plymouthd.conf << 'PLYMOUTH_EOF'
[Daemon]
Theme=arrera
ShowDelay=0
DeviceTimeout=8
PLYMOUTH_EOF

if [ -d /usr/share/plymouth/themes/arrera ]; then
    ln -sf /usr/share/plymouth/themes/arrera/arrera.plymouth /usr/share/plymouth/themes/default.plymouth 2>/dev/null || true
fi

if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme arrera 2>/dev/null || true
fi

# Reconstruire explicitement l'initramfs pour TOUS les noyaux avec Plymouth et le thème Arrera
if command -v dracut >/dev/null 2>&1; then
    echo "-> Régénération complète de l'initramfs avec Dracut et le thème Arrera..."
    dracut --regenerate-all --force --add plymouth 2>/dev/null || {
        if [ -n "$LATEST_KERNEL" ]; then
            KVER=$(basename "$LATEST_KERNEL" | sed 's/vmlinuz-//')
            dracut -f --add plymouth "/boot/initramfs-${KVER}.img" "$KVER" 2>/dev/null || true
        fi
    }
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
