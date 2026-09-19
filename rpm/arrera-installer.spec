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
Requires:       grub2-tools
Requires:       polkit
Requires:       systemd
Requires:       dnf

Suggests:       openbox

%description
Ce paquet fournit la configuration complète de Calamares pour Arrera Linux,
incluant :
- Le pipeline d'installation adapté à Fedora (x86_64 et aarch64)
- Le branding visuel Arrera (thème QSS sombre/bleu, logo vectoriel, diaporama QML)
- La gestion des utilisateurs (appartenance automatique au groupe wheel)
- La configuration du chargeur d'amorçage GRUB2 (EFI et BIOS)
- Le script post-installation de rafraîchissement des dépôts Arrera et DNF
- La session kiosque légère (cage/Wayland) pour média Live

%description -l en
This package provides the complete Calamares installer configuration for
Arrera Linux, including:
- Optimized Fedora installation pipeline (x86_64 and aarch64)
- Visual Arrera branding (dark/blue QSS theme, vector logo, QML slideshow)
- User account management (automatic wheel group membership)
- GRUB2 bootloader configuration (EFI & BIOS)
- Post-install script for Arrera repositories and DNF update
- Lightweight kiosk session (cage/Wayland) for Live media

%prep
%autosetup

%build
# Aucune étape de compilation requise (scripts et fichiers de configuration)

%install
%make_install PREFIX=%{_prefix} SYSCONFDIR=%{_sysconfdir}

%post
%systemd_post arrera-kiosk.service

%preun
%systemd_preun arrera-kiosk.service

%postun
%systemd_postun_with_restart arrera-kiosk.service

%files
%license
%doc README.md
%dir %{_sysconfdir}/calamares
%dir %{_sysconfdir}/calamares/modules
%config(noreplace) %{_sysconfdir}/calamares/settings.conf
%config(noreplace) %{_sysconfdir}/calamares/modules/*.conf
%dir %{_datadir}/calamares/qml
%{_datadir}/calamares/branding/arrera/
%{_bindir}/arrera-installer-kiosk.sh
%{_unitdir}/arrera-kiosk.service
%{_datadir}/applications/calamares-arrera.desktop

%changelog
* Fri Sep 19 2026 Baptiste P <contact@arrera-software.org> - 2026.beta.1-9
- Fix unpackfs: configure /run/rootfsbase ext4 (Fedora LiveOS layout)
- Ensure /run/rootfsbase is mounted in kiosk script before Calamares starts
- Add squashfs-tools, rsync, dosfstools, e2fsprogs to dependencies
- Silence console output during boot: send logs to journal, clear tty1, hide cursor
- Display exit prompt only if Calamares exits

* Fri Sep 19 2026 Baptiste P <contact@arrera-software.org> - 2026.beta.1-8
- Add required style: block to branding.desc
  Calamares 3.3 requires a style: section with sidebar colors; without it
  yaml-cpp throws YAML::InvalidNode ("first invalid key: style") on startup.

* Fri Sep 19 2026 Baptiste P <contact@arrera-software.org> - 2026.beta.1-7
- Rewrite branding.desc following official Calamares template exactly
- Remove uploadServer block (optional, sizeLimit sub-key caused invalid key FATAL)
- Fix windowSize format: remove space after comma (1060px,680px)
- Add missing windowPlacement and shortVersion keys

* Fri Sep 19 2026 Baptiste P <contact@arrera-software.org> - 2026.beta.1-6
- ROOT FIX: Remove -c /etc/calamares flag from all Calamares invocations
  When -c is passed, Calamares uses that dir as its full app data directory,
  looking for branding/, qml/ etc. inside /etc/calamares/ — causing FATAL errors.
  Without -c, Calamares correctly uses /etc/calamares for settings.conf and
  /usr/share/calamares for data (branding, qml, modules).
- Remove /etc/calamares/qml symlink (no longer needed)
- Remove -c flag from desktop file Exec line

* Fri Sep 19 2026 Baptiste P <contact@arrera-software.org> - 2026.beta.1-5
- Fix FATAL: missing qml/ — Calamares -c /etc/calamares uses /etc/calamares as
  app data dir and looks for /etc/calamares/qml (not /usr/share/calamares/qml)
- Add symlink /etc/calamares/qml → /usr/share/calamares/qml in Makefile and spec
- Add same symlink creation in kiosk script as live fallback

* Sat Sep 19 2026 Baptiste P <contact@arrera-software.org> - 2026.beta.1-4
- Create and include /usr/share/calamares/qml directory required by Calamares
- Copy all QML slideshow components into branding root directory
- Fix sidebar and navigation keys in branding.desc

* Sat Sep 19 2026 Baptiste P <contact@arrera-software.org> - 2026.beta.1-3
- Fix Calamares -c argument to pass configuration directory instead of file

* Sat Sep 19 2026 Baptiste P <contact@arrera-software.org> - 2026.beta.1-2
- Make cage a mandatory dependency
- Ensure XDG_RUNTIME_DIR is initialized for kiosk Wayland/Qt session
- Perform full DNF system upgrade on installation
- Fix slideshow installation path for Calamares
- Enable GDM on installed target system

* Sat Sep 19 2026 Baptiste P <contact@arrera-software.org> - 2026.beta.1-1
- Initial release of arrera-installer for Arrera Linux
- Added Calamares configuration for Fedora
- Added Arrera dark/blue branding, vector logo, and QML slideshow
- Added lightweight kiosk session with cage/wayland
