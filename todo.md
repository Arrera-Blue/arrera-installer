# TODO — `arrera-installer` : Simplification Calamares, Mise à jour exclusive OOBE/ABPM & Premier Démarrage Unifié sur les 4 Éditions

Ce document détaille les modifications et suppressions à effectuer dans le dépôt `arrera-installer` pour déléguer la création des utilisateurs et la mise à jour du système à **`arrera-blue-lynx`** sur les 4 éditions (`home`, `education`, `enterprise`, `server`).

---

## 1. Suppressions dans les configurations Calamares (`config/`)

### [ ] A. Suppression de l'écran « Mode d'installation (En ligne / Hors-ligne) » (`packagechooser@installmode`)
- **Fichiers à modifier** :
  - [config/settings.conf](file:///Users/baptistep/Documents/arrera-blue/arrera-installer/config/settings.conf)
  - [config/settings-home.conf](file:///Users/baptistep/Documents/arrera-blue/arrera-installer/config/settings-home.conf)
  - [config/settings-education.conf](file:///Users/baptistep/Documents/arrera-blue/arrera-installer/config/settings-education.conf)
  - [config/settings-enterprise.conf](file:///Users/baptistep/Documents/arrera-blue/arrera-installer/config/settings-enterprise.conf)
  - [config/settings-server.conf](file:///Users/baptistep/Documents/arrera-blue/arrera-installer/config/settings-server.conf)
- **Actions** :
  1. Retirer l'instance `installmode` (`module: packagechooser`, `config: packagechooser-installmode.conf`) de la section `instances:`.
  2. Retirer `- packagechooser@installmode` de la section `sequence -> show:`.
  3. Dans `config/settings-education.conf`, utiliser `config: shellprocess-postinstall.conf` (au lieu de `shellprocess-postinstall-education.conf`).
- **Fichiers à supprimer** :
  - `config/modules/packagechooser-installmode.conf`
  - `config/modules/shellprocess-postinstall-education.conf`
  - Dans [config/modules/shellprocess-postinstall.conf](file:///Users/baptistep/Documents/arrera-blue/arrera-installer/config/modules/shellprocess-postinstall.conf), simplifier la commande en :
    ```yaml
    script:
        - command: "/usr/bin/arrera-postinstall.sh"
          timeout: 1200
    ```

### [ ] B. Suppression du module `users` de Calamares sur toutes les éditions
- **Fichiers à modifier** :
  - [config/settings.conf](file:///Users/baptistep/Documents/arrera-blue/arrera-installer/config/settings.conf)
  - [config/settings-enterprise.conf](file:///Users/baptistep/Documents/arrera-blue/arrera-installer/config/settings-enterprise.conf)
  - [config/settings-server.conf](file:///Users/baptistep/Documents/arrera-blue/arrera-installer/config/settings-server.conf)
- **Actions** :
  1. Retirer `- users` de `sequence -> show:` et de `sequence -> exec:`.
  2. Les 4 fichiers `settings-*.conf` auront désormais exactement la même séquence Calamares :
     - `show` : `welcome` -> `locale` -> `keyboard` -> `partition` -> `summary` -> `finished`
     - `exec` : `partition` -> `mount` -> `unpackfs` -> `machineid` -> `fstab` -> `locale` -> `keyboard` -> `localecfg` -> `networkcfg` -> `hwclock` -> `services-systemd` -> `shellprocess@postinstall` -> `umount`
- **Fichier à supprimer** :
  - `config/modules/users.conf`

---

## 2. Mise à jour de `kiosk/arrera-postinstall.sh`

### [ ] A. Étape 1 : Mise à jour exclusive de `arrera-blue-lynx` et `abpm`
- **Fichier** : [kiosk/arrera-postinstall.sh](file:///Users/baptistep/Documents/arrera-blue/arrera-installer/kiosk/arrera-postinstall.sh)
- **Actions** :
  1. Supprimer la gestion du paramètre `$1` (`online` / `offline`).
  2. Tester automatiquement la connectivité Internet (timeout court 3-4s).
  3. Si Internet est disponible, mettre à jour **uniquement** l'assistant de premier démarrage `arrera-blue-lynx` et le gestionnaire de paquets `abpm` :
     ```bash
     abpm clean expire-cache 2>/dev/null || true
     abpm update -y --dnf arrera-blue-lynx abpm || \
         dnf upgrade -y --disablerepo="*" --enablerepo="*arrera*" \
             --setopt=timeout=10 --setopt=retries=2 \
             arrera-blue-lynx abpm || true
     ```
  4. Si aucune connexion Internet n'est détectée, continuer immédiatement avec les versions embarquées sur l'ISO.

### [ ] B. Étapes 4, 7 et 8 : Activation de l'OOBE sur les 4 éditions (`home`, `education`, `enterprise`, `server`)
- **Fichier** : [kiosk/arrera-postinstall.sh](file:///Users/baptistep/Documents/arrera-blue/arrera-installer/kiosk/arrera-postinstall.sh)
- **Actions** :
  1. Déterminer `OOBE_EDITION` et `IS_GRAPHICAL_OOBE` selon `ED_BRANDING` dans `/etc/calamares/settings.conf` :
     - `arrera-education` -> `OOBE_EDITION="education"`, `IS_GRAPHICAL_OOBE=1`, `TARGET_HOSTNAME="arrera-school"`
     - `arrera-enterprise` -> `OOBE_EDITION="enterprise"`, `IS_GRAPHICAL_OOBE=1`, `TARGET_HOSTNAME="arrera-enterprise"`
     - `arrera-server` -> `OOBE_EDITION="server"`, `IS_GRAPHICAL_OOBE=0`, `TARGET_HOSTNAME="arrera-server"`
     - `arrera-home` | `arrera` | `*` -> `OOBE_EDITION="home"`, `IS_GRAPHICAL_OOBE=1`, `TARGET_HOSTNAME="arrera"`
  2. Sur **toutes les éditions** :
     - Installer `/usr/local/bin/arrera-oobe.sh`, `/etc/systemd/system/arrera-oobe.service` et écrire `$OOBE_EDITION` dans `/etc/arrera-oobe-edition`.
     - Désactiver `gdm` pour le premier démarrage, activer `multi-user.target` et `arrera-oobe.service`.
     - Supprimer systématiquement le compte temporaire Live `arrera` (`/home/arrera`, `/etc/sudoers.d/arrera`).
  3. Lors de la désinstallation finale des paquets Live (Étape 8) :
     - Désinstaller `calamares`, `arrera-installer`, `arrera-installer-home`, `arrera-installer-education`, `arrera-installer-enterprise`, `arrera-installer-server`, `gnome-extensions-app`.
     - Conserver `cage` si `IS_GRAPHICAL_OOBE=1` (`home`, `education`, `enterprise`) ; désinstaller `cage` si `IS_GRAPHICAL_OOBE=0` (`server`).

---

## 3. Mise à jour de `kiosk/arrera-oobe.sh`

### [ ] A. Prise en charge des 4 éditions (3 graphiques sous Cage + 1 console sur `tty1`)
- **Fichier** : [kiosk/arrera-oobe.sh](file:///Users/baptistep/Documents/arrera-blue/arrera-installer/kiosk/arrera-oobe.sh)
- **Actions** :
  1. Sélectionner le binaire selon `$EDITION` :
     - `education`|`edu` -> `OOBE_BIN="/usr/bin/arrera-blue-lynx-education"`, `OOBE_MODE="gui"`
     - `enterprise`|`ent` -> `OOBE_BIN="/usr/bin/arrera-blue-lynx-enterprise"`, `OOBE_MODE="gui"`
     - `server`|`srv` -> `OOBE_BIN="/usr/bin/arrera-blue-lynx-server"`, `OOBE_MODE="cli"`
     - `home`|`*` -> `OOBE_BIN="/usr/bin/arrera-blue-lynx-home"`, `OOBE_MODE="gui"`
  2. Dans `run_oobe_session` :
     - Si `OOBE_MODE="cli"` (`server`) :
       - Restaurer le curseur et attacher `stdin`/`stdout`/`stderr` à `/dev/tty1`.
       - Exécuter directement `"$OOBE_BIN"` en console interactive.
     - Si `OOBE_MODE="gui"` (`home`, `education`, `enterprise`) :
       - Exécuter `"${runner[@]}" cage -s -- "$OOBE_BIN" --windowed`.
  3. En fin d'assistant (une fois l'utilisateur créé et `OOBE_RC == 0`) :
     - Nettoyer `arrera-oobe.service`, `/etc/arrera-oobe-edition`, `/usr/local/bin/arrera-oobe.sh`.
     - Sur `home`, `education`, `enterprise` : désinstaller `cage` (plus nécessaire après l'OOBE) ou le conserver, activer `graphical.target` + `gdm.service`.
     - Sur `server` : activer `multi-user.target`.
     - Si un noyau CachyOS a été installé (`ls /boot/vmlinuz-*cachyos*` et `uname -r` != `*cachyos*`), redémarrer immédiatement (`systemctl reboot`).
     - Sinon : sur Desktop basculer vers GDM (`systemctl --no-block isolate graphical.target`), sur Server démarrer `getty@tty1.service` (`systemctl --no-block start getty@tty1.service`).

---

## 4. Thème Serveur (`branding/arrera-server/stylesheet.qss`)

### [ ] A. Lisibilité du pourcentage sur la barre de progression noire
- **Fichier** : [branding/arrera-server/stylesheet.qss](file:///Users/baptistep/Documents/arrera-blue/arrera-installer/branding/arrera-server/stylesheet.qss#L449-L466)
- **Problème** : La barre de chargement (`QProgressBar::chunk`) est noire (`#303030`) et le texte du pourcentage (`QProgressBar { color: #1e1e1e; }`) est également noir, ce qui rend le pourcentage illisible dès que la barre dépasse 50 %.
- **Action** :
  - Conserver la barre de progression noire (`QProgressBar::chunk { background-color: #303030; }`).
  - Passer la couleur du texte du pourcentage en **blanc (`color: #ffffff;`)** dans `QProgressBar, QProgressBar#progressBar`.

---

## 5. Packaging RPM (`rpm/arrera-installer.spec`)

### [ ] A. Bump de version et validation
- **Fichier** : [rpm/arrera-installer.spec](file:///Users/baptistep/Documents/arrera-blue/arrera-installer/rpm/arrera-installer.spec)
- **Actions** :
  1. Retirer `packagechooser-installmode.conf`, `shellprocess-postinstall-education.conf` et `users.conf` s'ils étaient référencés explicitement.
  2. Incrémenter `Release` à `23%{?dist}` (`2026.beta.1-23`), exécuter `make test` et publier sur Copr.
