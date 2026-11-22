# 📋 Feuille de route (`todo.md`) — `arrera-installer`

Ce document détaille toutes les modifications à apporter dans le dépôt **`arrera-installer`** pour résoudre :
1. **La lenteur extrême de l'installation à 91 %** (étape `shellprocess@postinstall` exécutant `/usr/bin/arrera-postinstall.sh`).
2. **L'échec du démarrage sur les systèmes BIOS Legacy (`x86_64`)** après l'installation par Calamares, tout en préservant à 100 % le démarrage UEFI (`x86_64` GRUB2 + Shim Secure Boot et `aarch64` `systemd-boot`) ainsi que l'assistant OOBE de premier démarrage (`arrera-blue-lynx`).

---

## 🔍 1. Diagnostic des deux problèmes dans `arrera-installer`

### A. Pourquoi l'installation bloque très longtemps à 91 %
À 91 %, Calamares exécute `/usr/bin/arrera-postinstall.sh "online"`. Trois opérations y prennent entre 5 et 12 minutes sans retour visuel :
1. **`dnf makecache -y` suivi de `dnf upgrade -y --refresh` sur tous les dépôts (`kiosk/arrera-postinstall.sh` lignes 53-54)** :
   - Télécharge deux fois les métadonnées des 8 dépôts configurés (Fedora, Updates, RPM Fusion Free/Non-Free, Copr Arrera, et surtout **`rpmsphere` sur GitHub** dont le `repodata` est très lent).
   - Télécharge et met à jour **tous** les paquets du système (noyau, `linux-firmware`, Mesa, Firefox, GNOME...) à l'intérieur du chroot Calamares.
2. **`dracut --regenerate-all --force --add plymouth` (`kiosk/arrera-postinstall.sh` ligne 106)** :
   - Exécuté **avant** la suppression de l'ancien noyau `rescue` du média Live (ligne 192).
   - Reconstruit donc l'initramfs de tous les noyaux présents + l'ancien `rescue` du Live pour rien.
3. **Double génération du noyau `rescue` `--no-hostonly` de ~200 Mo sur `x86_64` (`kiosk/arrera-postinstall.sh` lignes 459-470)** :
   - Appelle `/usr/lib/kernel/install.d/51-dracut-rescue.install` sans les variables `KERNEL_INSTALL_*` requises sur Fedora 44, puis relance `dracut -f --no-hostonly -a "rescue"` qui compresse **tous** les pilotes et firmwares du noyau (~200 Mo, 2 à 4 minutes à 100 % CPU).
4. **Redirection `exec > >(tee -a /var/log/arrera-postinstall.log) 2>&1` (ligne 11)** :
   - Crée un sous-processus `tee` persistant qui peut garder le descripteur `stdout` ouvert dans Calamares si un processus fils (`gpg-agent` lancé par DNF) en hérite.

---

### B. Pourquoi le système ne démarre pas en BIOS Legacy (`x86_64`) après installation
1. **Table de partitions en mode BIOS (`config/modules/partition.conf` & `kiosk/arrera-installer-kiosk.sh`)** :
   - `config/modules/partition.conf` contient `defaultPartitionTableType: "gpt"` et `createHybridBootloaderLayout: true`.
   - Or, `arrera-installer-kiosk.sh` ne bascule pas `defaultPartitionTableType` en `"msdos"` (MBR) lorsque le Live ISO est démarré en mode BIOS (`[ ! -d /sys/firmware/efi ]`).
   - Si le disque est partitionné sans MBR standard (ou en GPT sans partition `bios_grub` correctement reconnue) ou sans le drapeau bootable MBR (`0x80`), le BIOS refuse d'amorcer le disque.
2. **`GRUB_ENABLE_BLSCFG=true` + `grub2-editenv create` en mode BIOS (`kiosk/arrera-postinstall.sh` lignes 417 & 553)** :
   - En UEFI, `/boot/efi/EFI/fedora/grub.cfg` (le stub EFI) cherche la partition par UUID et possède un `menuentry` de secours.
   - En **BIOS Legacy (`i386-pc`)**, GRUB lit uniquement `/boot/grub2/grub.cfg`. Avec `GRUB_ENABLE_BLSCFG=true`, `grub2-mkconfig` n'écrit **aucun `menuentry`** dans `/boot/grub2/grub.cfg` et délègue tout au module `blscfg`, qui dépend de `grubenv` (réinitialisé juste avant par `grub2-editenv create`) et de `$blsdir`. Avec `GRUB_TIMEOUT=0`, si `blscfg` ne résout pas les entrées en BIOS, le système reste bloqué sur un écran noir ou `grub>`.
3. **Ordre d'exécution et validation de `grub2-install` / `grub2-mkconfig` (`kiosk/arrera-postinstall.sh` lignes 563-690)** :
   - L'ancien `/boot/grub2/grub.cfg` issu du Live ISO (avec l'UUID du build Live) n'est pas supprimé avant `grub2-mkconfig` : si `grub2-mkconfig` échoue dans le chroot, le fichier n'est pas vide (`[ ! -s /boot/grub2/grub.cfg ]` est faux) et l'ancien `grub.cfg` avec le mauvais UUID reste en place.
   - `grub2-install --target=i386-pc` est exécuté **après** `grub2-mkconfig`, sans `--boot-directory=/boot`, et sans activer le drapeau bootable MBR (`0x80`) sur la partition de démarrage.

---

## 🛠️ 2. Checklist détaillée des modifications à effectuer

### Tâche 1 : Mettre à jour `config/modules/partition.conf`
- [ ] Désactiver `createHybridBootloaderLayout` par défaut (`false`) et conserver `defaultPartitionTableType: "gpt"` comme valeur par défaut (qui sera ajustée dynamiquement en `"msdos"` par le script kiosque si le système est en BIOS Legacy) :

```yaml
# ==============================================================================
# Configuration du module partition pour Arrera Linux
# Par défaut : ESP sur /boot/efi (Standard Fedora pour GRUB2 sous x86_64)
# Note : Sur BIOS Legacy, arrera-installer-kiosk.sh bascule automatiquement
#        defaultPartitionTableType sur "msdos" (MBR).
# ==============================================================================
---
defaultFileSystemType: "ext4"
availableFileSystemTypes: ["ext4", "btrfs", "xfs"]
createHybridBootloaderLayout: false
defaultPartitionTableType: "gpt"
efiSystemPartition: "/boot/efi"
efiSystemPartitionSize: 600M
essentialMounts: [ "live-*", "control", "ventoy" ]
lvm:
    enable: false
```

---

### Tâche 2 : Adapter dynamiquement `partition.conf` (BIOS vs UEFI) dans `kiosk/arrera-installer-kiosk.sh`
- [ ] Dans `kiosk/arrera-installer-kiosk.sh` (juste après la neutralisation de `- bootloader` autour de la ligne 60), ajouter la détection du mode de démarrage (`[ -d /sys/firmware/efi ]`) pour forcer `"gpt"` en UEFI et `"msdos"` en BIOS Legacy :

```bash
# Configuration dynamique de la table de partition sur x86_64 selon le mode (UEFI -> gpt | BIOS -> msdos)
if [ "$(uname -m)" = "x86_64" ]; then
    for pconf in /etc/calamares/modules/partition.conf /etc/calamares/modules/partition-*.conf /usr/share/calamares/modules/partition.conf; do
        [ -f "$pconf" ] || continue
        if [ -d /sys/firmware/efi ]; then
            TARGET_PT="gpt"
        else
            TARGET_PT="msdos"
        fi
        if grep -qE '^[[:space:]]*defaultPartitionTableType:' "$pconf"; then
            sed -i -E "s/^[[:space:]]*defaultPartitionTableType:.*/defaultPartitionTableType: \"${TARGET_PT}\"/" "$pconf" 2>/dev/null || true
        else
            echo "defaultPartitionTableType: \"${TARGET_PT}\"" >> "$pconf"
        fi
        if grep -qE '^[[:space:]]*createHybridBootloaderLayout:' "$pconf"; then
            sed -i -E 's/^[[:space:]]*createHybridBootloaderLayout:.*/createHybridBootloaderLayout: false/' "$pconf" 2>/dev/null || true
        else
            echo "createHybridBootloaderLayout: false" >> "$pconf"
        fi
    done
fi
```

---

### Tâche 3 : Optimiser la vitesse (étape 91 % en ~20s) dans `kiosk/arrera-postinstall.sh`
- [ ] **3.1. Remplacer la redirection `tee` (ligne 11)** :
  ```bash
  mkdir -p /var/log
  exec >> /var/log/arrera-postinstall.log 2>&1
  ```
- [ ] **3.2. Remplacer le `dnf makecache` + `dnf upgrade -y --refresh` global (lignes 50-56)** :
  - Ne mettre à jour en mode `online` **que** les paquets Arrera depuis le dépôt Copr `arrera-blue` (évite de télécharger les métadonnées lentes de `rpmsphere` et les centaines de Mo de Fedora Updates pendant Calamares) :
  ```bash
  if [ "$IS_ONLINE" -eq 1 ]; then
      echo "-> Connexion Internet confirmée !"
      echo "-> Mise à jour rapide des composants Arrera..."
      dnf upgrade -y --disablerepo="*" --enablerepo="*arrera*" \
          --setopt=timeout=10 --setopt=retries=2 \
          "arrera-*" "blue-*" "abpm" "gnome-shell-extension-arrera-*" || true
      gpgconf --kill all 2>/dev/null || true
      echo "-> Composants Arrera à jour."
  fi
  ```
- [ ] **3.3. Nettoyer l'ancien `rescue` du Live AVANT Dracut et ne régénérer qu'un seul initramfs `--hostonly` (lignes 93-112)** :
  - Initialiser `/etc/machine-id` et supprimer les anciens `/boot/*rescue*` du Live **avant** d'appeler `dracut`.
  - Remplacer `dracut --regenerate-all --force --add plymouth` par un seul appel ciblé sur `$KVER` :
  ```bash
  if command -v dracut >/dev/null 2>&1 && [ -n "$KVER" ]; then
      echo "-> Génération rapide de l'initramfs (--hostonly) pour le noyau $KVER..."
      dracut -f --hostonly --add plymouth --kver "$KVER" "/boot/initramfs-${KVER}.img" 2>&1 || \
          dracut -f --add plymouth --kver "$KVER" "/boot/initramfs-${KVER}.img" 2>&1 || true
  fi
  ```
- [ ] **3.4. Remplacer la génération lente du `rescue` `--no-hostonly` (~3 min) par une copie directe (~0,1 s) sur `x86_64` (lignes 457-471)** :
  - Supprimer l'appel à `51-dracut-rescue.install` et à `dracut -f --no-hostonly -a "rescue"`.
  - Copier directement l'initramfs principal nouvellement généré :
  ```bash
  if [ ! -f "$RESCUE_VMLINUZ" ]; then
      cp -f "/boot/vmlinuz-${KVER}" "$RESCUE_VMLINUZ" 2>/dev/null || cp -f "$LATEST_KERNEL" "$RESCUE_VMLINUZ" 2>/dev/null || true
  fi
  if [ ! -f "$RESCUE_INITRD" ] && [ -s "/boot/initramfs-${KVER}.img" ]; then
      cp -f "/boot/initramfs-${KVER}.img" "$RESCUE_INITRD" 2>/dev/null || true
  fi
  ```

---

### Tâche 4 : Fiabiliser l'amorçage BIOS Legacy (`x86_64`) dans `kiosk/arrera-postinstall.sh`
- [ ] **4.1. Désactiver `GRUB_ENABLE_BLSCFG` en mode BIOS Legacy (`[ ! -d /sys/firmware/efi ]`)** :
  - Dans `/etc/default/grub` (ligne 417), définir `GRUB_ENABLE_BLSCFG=true` en UEFI, mais **`GRUB_ENABLE_BLSCFG=false` en BIOS Legacy** :
  ```bash
  IS_UEFI_SYSTEM=0
  if [ -d /sys/firmware/efi ] || grep -q '/boot/efi' /etc/fstab 2>/dev/null; then
      IS_UEFI_SYSTEM=1
  fi
  if [ "$IS_UEFI_SYSTEM" -eq 1 ]; then
      GRUB_BLSCFG_VAL="true"
  else
      GRUB_BLSCFG_VAL="false"
  fi
  ```
  *(Avec `GRUB_ENABLE_BLSCFG=false` en BIOS, `grub2-mkconfig` génère directement les entrées `menuentry` classiques dans `/boot/grub2/grub.cfg`, ce qui évite tout blocage de `blscfg.mod` sur MBR/BIOS.)*
- [ ] **4.2. Activer le drapeau bootable MBR (`0x80`) et exécuter `grub2-install --target=i386-pc` AVANT `grub2-mkconfig` (uniquement en BIOS)** :
  - Détecter `BOOT_PART_DEV`, `BOOT_PART_NUM` et `TARGET_DISK`.
  - Si `[ "$IS_UEFI_SYSTEM" -eq 0 ]` :
    1. Si la table de partitions (`blkid -s PTTYPE -o value "$TARGET_DISK"`) est `dos` (MBR), activer le drapeau bootable sur la partition :
       ```bash
       sfdisk --activate "$TARGET_DISK" "$BOOT_PART_NUM" 2>&1 || true
       parted -s "$TARGET_DISK" set "$BOOT_PART_NUM" boot on 2>&1 || true
       ```
    2. Supprimer tout ancien `/boot/grub2/device.map`.
    3. Exécuter le vrai binaire `grub2-install.orig` :
       ```bash
       "$GRUB_INSTALL_BIN" --target=i386-pc --boot-directory=/boot --recheck "$TARGET_DISK" 2>&1 || \
           "$GRUB_INSTALL_BIN" --target=i386-pc --boot-directory=/boot --recheck --force "$TARGET_DISK" 2>&1 || true
       ```
- [ ] **4.3. Supprimer l'ancien `/boot/grub2/grub.cfg` du Live avant d'appeler `grub2-mkconfig.orig` et valider le résultat** :
  - Faire `rm -f /boot/grub2/grub.cfg /boot/grub2/grub.cfg.new` avant `"$GRUB_MKCONFIG_BIN" -o /boot/grub2/grub.cfg`.
  - Vérifier que `/boot/grub2/grub.cfg` contient bien `$BOOT_UUID` et (en BIOS) au moins un bloc `menuentry`.
  - Si ce n'est pas le cas (ou si `grub2-mkconfig` échoue en chroot), écrire le `/boot/grub2/grub.cfg` autonome avec un bloc `menuentry 'Arrera Blue 2026'` explicite et un `function load_video` compatible BIOS (`insmod vbe; insmod vga` quand `${grub_platform} != efi`).

---

### Tâche 5 : Builder et publier le RPM `arrera-installer`
- [ ] Incrémenter le numéro de `Release:` dans `rpm/arrera-installer.spec` (ex: `20%{?dist}`).
- [ ] Compiler et publier la mise à jour sur le dépôt Copr `arrera-software/arrera-blue`.
