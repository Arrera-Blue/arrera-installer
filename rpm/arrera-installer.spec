Name:           arrera-installer
Version:        2026.beta.1
Release:        9%{?dist}
Summary:        Configuration Calamares et session kiosque pour Arrera Linux
Summary(en):    Calamares installer configuration and kiosk session for Arrera Linux

License:        GPL-3.0-or-later
URL:            https://github.com/Arrera-Software/arrera-installer
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch

BuildRequires:  systemd-rpm-macros
BuildRequires:  make

Requires:       calamares
Requires:       cage
Requires:       squashfs-tools
Requires:       rsync
Requires:       dosfstools
Requires:       e2fsprogs
Requires:       efibootmgr
Requires:       systemd-udev
Requires:       polkit
Requires:       systemd
Requires:       dnf

Recommends:     (grub2-tools if grub2-common)
Recommends:     (grub2-tools-extra if grub2-common)
Recommends:     (systemd-boot-unsigned if systemd-boot)
Recommends:     abattis-cantarell-fonts
Recommends:     adwaita-cursor-theme
Recommends:     qt6-qtwayland-adwaita-decoration
Suggests:       openbox

%description
Ce paquet fournit le moteur et les scripts communs de Calamares pour Arrera Linux,
incluant :
- Le pipeline d'installation adapté à Fedora (x86_64 et aarch64)
- La gestion des utilisateurs (appartenance automatique au groupe wheel)
- L'amorçage hybride : GRUB2 + Shim (Secure Boot officiel x86_64) et systemd-boot (aarch64)
- Le script post-installation de finalisation et nettoyage
- La session kiosque légère (cage/Wayland) pour média Live

%description -l en
This package provides common Calamares engine and scripts for Arrera Linux,
including:
- Optimized Fedora installation pipeline (x86_64 and aarch64)
- User account management (automatic wheel group membership)
- Hybrid bootloader: GRUB2 + Shim (Microsoft Secure Boot on x86_64) and systemd-boot (aarch64)
- Post-install finalization and cleanup script
- Lightweight kiosk session (cage/Wayland) for Live media

# ==============================================================================
# Sous-paquets par Édition
# ==============================================================================

%package home
Summary:        Installateur Calamares pour Arrera Blue Édition Home
Requires:       %{name} = %{version}-%{release}
Provides:       %{name}-branding = %{version}-%{release}
Conflicts:      %{name}-education %{name}-server %{name}-enterprise

%description home
Configuration visuelle, branding et diaporama Calamares pour Arrera Blue Édition Home 2026.

%package education
Summary:        Installateur Calamares pour Arrera Blue Édition Éducation
Requires:       %{name} = %{version}-%{release}
Provides:       %{name}-branding = %{version}-%{release}
Conflicts:      %{name}-home %{name}-server %{name}-enterprise

%description education
Configuration visuelle, branding et diaporama Calamares pour Arrera Blue Édition Éducation 2026.

%package server
Summary:        Installateur Calamares pour Arrera Blue Édition Serveur
Requires:       %{name} = %{version}-%{release}
Provides:       %{name}-branding = %{version}-%{release}
Conflicts:      %{name}-home %{name}-education %{name}-enterprise

%description server
Configuration visuelle, branding et diaporama Calamares pour Arrera Blue Édition Serveur 2026.

%package enterprise
Summary:        Installateur Calamares pour Arrera Blue Édition Entreprise
Requires:       %{name} = %{version}-%{release}
Provides:       %{name}-branding = %{version}-%{release}
Conflicts:      %{name}-home %{name}-education %{name}-server

%description enterprise
Configuration visuelle, branding et diaporama Calamares pour Arrera Blue Édition Entreprise 2026.

# ==============================================================================
# Préparation, Construction & Installation
# ==============================================================================

%prep
%autosetup

%build
# Aucune étape de compilation requise (scripts et fichiers de configuration)

%install
%make_install PREFIX=%{_prefix} SYSCONFDIR=%{_sysconfdir}

# Création du fichier settings.conf par défaut pointant sur l'édition Home
cp %{buildroot}%{_sysconfdir}/calamares/settings-home.conf %{buildroot}%{_sysconfdir}/calamares/settings.conf

%post
%systemd_post arrera-kiosk.service
# Créer les symlinks après installation de calamares pour éviter les conflits
# de fichiers RPM (calamares possède /etc/calamares/branding en tant que répertoire)
if [ -d %{_sysconfdir}/calamares/branding ] && [ ! -L %{_sysconfdir}/calamares/branding ]; then
    rm -rf %{_sysconfdir}/calamares/branding
fi
ln -sfn %{_datadir}/calamares/branding %{_sysconfdir}/calamares/branding 2>/dev/null || true
if [ -d %{_sysconfdir}/calamares/qml ] && [ ! -L %{_sysconfdir}/calamares/qml ]; then
    rm -rf %{_sysconfdir}/calamares/qml
fi
ln -sfn %{_datadir}/calamares/qml %{_sysconfdir}/calamares/qml 2>/dev/null || true

%preun
%systemd_preun arrera-kiosk.service

%postun
%systemd_postun_with_restart arrera-kiosk.service

%post home
cp -f %{_sysconfdir}/calamares/settings-home.conf %{_sysconfdir}/calamares/settings.conf 2>/dev/null || true

%post education
cp -f %{_sysconfdir}/calamares/settings-education.conf %{_sysconfdir}/calamares/settings.conf 2>/dev/null || true

%post server
cp -f %{_sysconfdir}/calamares/settings-server.conf %{_sysconfdir}/calamares/settings.conf 2>/dev/null || true

%post enterprise
cp -f %{_sysconfdir}/calamares/settings-enterprise.conf %{_sysconfdir}/calamares/settings.conf 2>/dev/null || true

# ==============================================================================
# Liste des fichiers par paquet
# ==============================================================================

%files
%license LICENSE
%doc README.md
%dir %{_sysconfdir}/calamares
%dir %{_sysconfdir}/calamares/modules
%config(noreplace) %{_sysconfdir}/calamares/settings.conf
%config(noreplace) %{_sysconfdir}/calamares/settings-*.conf
%config(noreplace) %{_sysconfdir}/calamares/modules/*.conf
%dir %{_datadir}/calamares/qml
%dir %{_datadir}/calamares/branding
%{_datadir}/calamares/branding/arrera/
%{_bindir}/arrera-installer-kiosk.sh
%{_bindir}/arrera-postinstall.sh
%{_bindir}/arrera-wifi-setup.sh
%{_bindir}/arrera-wifi-setup.py
%{_bindir}/arrera-session-runner.sh
%{_unitdir}/arrera-kiosk.service
%{_datadir}/applications/calamares-arrera.desktop

%files home
%{_datadir}/calamares/branding/arrera-home/

%files education
%{_datadir}/calamares/branding/arrera-education/

%files server
%{_datadir}/calamares/branding/arrera-server/

%files enterprise
%{_datadir}/calamares/branding/arrera-enterprise/

%changelog
* Sat Oct 03 2026 Baptiste P <contact@arrera-software.org> - 2026.beta.1-9
- Add preventive bootloader sanitization in arrera-installer-kiosk.sh
- Add binary restoration and cleanup in arrera-postinstall.sh

* Fri Oct 02 2026 Baptiste P <contact@arrera-software.org> - 2026.beta.1-8
- Delegate bootloader installation entirely to arrera-postinstall.sh
- Enable createHybridBootloaderLayout in partition.conf for BIOS Legacy on GPT
- Add BIOS Legacy GRUB installation support in arrera-postinstall.sh
- Make bootloader packages (grub2-tools, systemd-boot-unsigned) conditional to avoid cross-arch conflicts
- Update uninstallation in postinstall to remove all edition subpackages

* Fri Oct 02 2026 Baptiste P <contact@arrera-software.org> - 2026.beta.1-7
- Fix file conflict with calamares package on /etc/calamares/branding:
  * Remove symlinks from %files (were conflicting with calamares directory)
  * Create symlinks in %post scriptlet instead
  * Update Makefile to not create symlinks during install

* Tue Sep 29 2026 Baptiste P <contact@arrera-software.org> - 2026.beta.1-6
- Add multi-edition branding and subpackages:
  * arrera-installer-home: Home edition with Libadwaita Blue branding
  * arrera-installer-education: Education edition with Emerald branding
  * arrera-installer-server: Server edition with Datacenter Dark and Cyan branding
  * arrera-installer-enterprise: Enterprise edition with Corporate Navy branding
- Add dedicated slideshows and settings configs for each edition
- Update debug launcher with --edition selector and safe dry-run mode

* Sat Sep 26 2026 Baptiste P <contact@arrera-software.org> - 2026.beta.1-15
- Implement hybrid bootloader architecture:
  * x86_64: GRUB2 + Shim (Microsoft signed UEFI CA for out-of-the-box Secure Boot)
  * aarch64: systemd-boot (UEFI native, bypasses Calamares ARM64 shimx64 bug)
- Update arrera-postinstall.sh with architecture detection for UEFI/NVRAM configuration
- Add both grub2-tools and systemd-boot-unsigned to requirements
