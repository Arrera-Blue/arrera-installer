Name:           arrera-installer
Version:        2026.beta.1
Release:        1%{?dist}
Summary:        Configuration Calamares et session kiosque pour Arrera Linux
Summary(en):    Calamares installer configuration and kiosk session for Arrera Linux

License:        GPL-3.0-or-later
URL:            https://github.com/Arrera-Software/arrera-installer
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch

BuildRequires:  systemd-rpm-macros
BuildRequires:  make

Requires:       calamares
Requires:       grub2-tools
Requires:       polkit
Requires:       systemd
Requires:       dnf

Recommends:     cage
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
%{_datadir}/calamares/branding/arrera/
%{_bindir}/arrera-installer-kiosk.sh
%{_unitdir}/arrera-kiosk.service
%{_datadir}/applications/calamares-arrera.desktop

%changelog
* Sat Sep 19 2026 Baptiste P <contact@arrera-software.org> - 1.0.0-1
- Initial release of arrera-installer for Arrera Linux
- Added Calamares configuration for Fedora
- Added Arrera dark/blue branding, vector logo, and QML slideshow
- Added lightweight kiosk session with cage/wayland
