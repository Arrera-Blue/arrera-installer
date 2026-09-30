# Arrera Installer (`arrera-installer`)

[![Fedora COPR](https://img.shields.io/badge/COPR-copr--arrera--blue-blue.svg)](https://copr.fedorainfracloud.org/coprs/baptistep/copr-arrera-blue/)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Arch: noarch](https://img.shields.io/badge/Arch-noarch-lightgrey.svg)](#)

Configuration personnalisée de l'installateur **Calamares** et session **Kiosque ultra-légère** pour **Arrera Linux**, distribution basée sur Fedora supportant les architectures `x86_64` et `aarch64`.

---

## 🚀 Fonctionnalités principales

1. **Pipeline Calamares optimisé pour Fedora** :
   - Partitionnement automatisé et manuel (ext4, btrfs, xfs).
   - Décompression efficace du squashfs LiveOS (`unpackfs`).
   - Gestion des utilisateurs avec inclusion automatique dans le groupe `wheel` (accès `sudo`).
   - Configuration universelle du chargeur d'amorçage **GRUB2** pour UEFI et BIOS.
   - Script post-installation (`shellprocess@postinstall`) vérifiant l'accès Internet, rafraîchissant les paquets Arrera via DNF et appliquant les schémas dconf.
2. **Identité visuelle Arrera Blue** :
   - Thème moderne sombre aux accents bleus (`stylesheet.qss`).
   - Logo vectoriel SVG haute fidélité (`arrera-logo.svg`).
   - Diaporama interactif QML animé (`slideshow.qml`).
3. **Session Kiosque ultra-légère pour ISO** :
   - Lancement direct de Calamares dans le compositeur Wayland minimaliste **`cage`** (ou fallback X11).
   - Évite de charger la session complète GNOME au démarrage du média d'installation, réduisant drastiquement l'empreinte mémoire RAM et le temps de boot.
   - Service systemd dédié (`arrera-kiosk.service`) avec gestion propre de l'extinction et du redémarrage.
4. **Empaquetage RPM `noarch`** :
   - Fichier spec standardisé pour Fedora 41/42/44.
   - Prêt pour le déploiement sur le dépôt COPR `copr-arrera-blue`.

---

## 📁 Arborescence du projet

```text
Arrera-installer/
├── README.md                          # Documentation complète
├── Makefile                           # Automatisation des tests et builds RPM/SRPM
├── build.sh                           # Script de build RPM/SRPM
├── debug.sh                           # Lanceur de test et débogage multi-éditions
├── rpm/
│   └── arrera-installer.spec          # Spécification RPM noarch pour Fedora/COPR
├── config/
│   ├── settings.conf                  # Pipeline par défaut
│   ├── settings-home.conf             # Pipeline Édition Home
│   ├── settings-education.conf        # Pipeline Édition Éducation
│   ├── settings-server.conf           # Pipeline Édition Serveur
│   ├── settings-enterprise.conf       # Pipeline Édition Entreprise
│   └── modules/
│       ├── users-home.conf            # Utilisateur Home (machine arrera)
│       ├── users-education.conf       # Compte parents (machine arrera-school)
│       ├── users-server.conf          # Compte serveur avec mot de passe root
│       ├── users-enterprise.conf      # Compte entreprise avec mot de passe root
│       ├── welcome.conf               # Contrôle des prérequis système
│       ├── packagechooser-installmode.conf # Choix d'installation
│       ├── unpackfs.conf              # Décompression de la racine LiveOS
│       ├── bootloader.conf            # Gestion GRUB2 & systemd-boot
│       ├── services-systemd.conf      # Services actifs sur le système cible
│       └── shellprocess-postinstall.conf # Finalisation post-installation
├── branding/                          # Thèmes visuels Libadwaita Light
│   ├── arrera/                        # Base / Défaut (Bleu)
│   ├── arrera-home/                   # Édition Home (Bleu GNOME)
│   ├── arrera-education/              # Édition Éducation (Turquoise GNOME)
│   ├── arrera-server/                 # Édition Serveur (Noir GNOME)
│   └── arrera-enterprise/             # Édition Entreprise (Violet GNOME)
├── kiosk/
│   ├── arrera-installer-kiosk.sh      # Lanceur de session kiosque (cage/wayland)
│   ├── arrera-kiosk.service           # Unité systemd TTY1 pour l'ISO Live
│   └── arrera-postinstall.sh          # Automatisation post-install et hostname
└── desktop/
    └── calamares-arrera.desktop       # Raccourci d'installation pour bureau
```

---

## 🔨 Compilation rapide avec `build.sh`

Un script tout-en-un exécutable [build.sh](file:///home/baptistep/arrera-installer/build.sh) est disponible à la racine du projet :

```bash
# Compilation complète (tests + RPM binaire + SRPM vers output/) :
./build.sh

# Génération uniquement du SRPM pour COPR :
./build.sh --srpm

# Exécution des tests de syntaxe et validation :
./build.sh --test

# Nettoyage des artefacts :
./build.sh --clean
```

Tous les paquets compilés (`.rpm`, `.src.rpm` et `.tar.gz`) sont automatiquement déposés dans le dossier **`output/`**.

---

## 🛠️ Commandes du Makefile

Le [Makefile](file:///home/baptistep/Documents/arrera-linux/arrera-installer/Makefile) gère les cibles sous-jacentes :

| Commande | Action |
| :--- | :--- |
| `make test` | Valide la syntaxe des scripts Bash, des fichiers YAML et du fichier `.desktop`. |
| `make dist` | Génère l'archive tarball source dans `output/`. |
| `make srpm` | Construit le paquet source SRPM dans `output/`. |
| `make rpm` | Construit le RPM binaire `noarch` et le SRPM dans `output/`. |
| `make install` | Installe les fichiers dans l'arborescence système (`DESTDIR`). |
| `make clean` | Supprime les répertoires temporaires et le dossier `output/`. |

---

## 🧪 Tester l'installateur localement & en VM de test

Le script [debug.sh](file:///home/baptistep/arrera-installer/debug.sh) installe automatiquement les dépendances requises (Calamares, Cage, polices, thèmes), déploie la configuration et démarre Calamares en mode debug :

```bash
# Tester l'édition Home (compte perso, hostname 'arrera' masqué, accent GNOME Blue) :
./debug.sh --edition home --dry-run

# Tester l'édition Éducation (compte 'parents', mdp uniquement, hostname 'arrera-school', accent Turquoise) :
./debug.sh --edition education --dry-run

# Tester l'édition Serveur (compte utilisateur + mot de passe root, accent GNOME Black) :
./debug.sh --edition server --dry-run

# Tester l'édition Entreprise (compte utilisateur + mot de passe root, accent GNOME Purple) :
./debug.sh --edition enterprise --dry-run

# Tester la session Kiosque plein écran (Cage / Wayland, identique à l'ISO) :
./debug.sh --edition home --kiosk
```

---

## 📦 Déploiement sur Fedora COPR (`copr-arrera-blue`)

### 1. Générer le paquet SRPM
```bash
make srpm
```

### 2. Soumettre le SRPM à COPR avec l'outil `copr-cli`
```bash
copr-cli build copr-arrera-blue arrera-installer-1.0.0-1.fc*.src.rpm
```

Ou bien via un dépôt Git configuré directement dans l'interface web de COPR :
- Type de source : **SCM / Git**
- URL du dépôt : `https://github.com/Arrera-Software/arrera-installer.git`
- Répertoire spec : `rpm/arrera-installer.spec`

---

## 💿 Intégration dans l'ISO d'Arrera Linux

Dans le fichier Kickstart (`.ks`) utilisé par `livemedia-creator` ou `lorax` :

```kickstart
# Dépôt Arrera
repo --name=copr-arrera-blue --baseurl=https://download.copr.fedorainfracloud.org/results/baptistep/copr-arrera-blue/fedora-$releasever-$basearch/

# Paquets de l'installateur (choisir le paquet selon l'édition de l'ISO) :
%packages
# Pour l'édition Home :
arrera-installer-home

# OU pour l'édition Éducation :
# arrera-installer-education

# OU pour l'édition Serveur :
# arrera-installer-server

# OU pour l'édition Entreprise :
# arrera-installer-enterprise

calamares
cage
%end

# Activation du mode Kiosque sur l'image Live
%post
systemctl enable arrera-kiosk.service
systemctl set-default multi-user.target
%end
```

---

## 📄 Licence
Ce projet est distribué sous licence **GPL-3.0-or-later**.
Consultez les fichiers sources pour plus d'informations.
