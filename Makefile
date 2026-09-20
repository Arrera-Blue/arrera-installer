# ==============================================================================
# Makefile pour arrera-installer
# Arrera Linux - Installateur Calamares & Session Kiosque
# ==============================================================================

NAME        := arrera-installer
SPEC_FILE   := rpm/$(NAME).spec
VERSION     ?= $(shell awk '/^Version:/ {print $$2; exit}' $(SPEC_FILE))
PREFIX      ?= /usr
SYSCONFDIR  ?= /etc
DATADIR     ?= $(PREFIX)/share
BINDIR      ?= $(PREFIX)/bin
UNITDIR     ?= $(PREFIX)/lib/systemd/system
APPDIR      ?= $(DATADIR)/applications
CALAMARES_DIR ?= $(SYSCONFDIR)/calamares
BRANDING_DIR  ?= $(DATADIR)/calamares/branding/arrera

BUILD_DIR   := build
RPMBUILD_DIR:= $(CURDIR)/build/rpmbuild
OUTPUT_DIR  ?= output
TARBALL     := $(NAME)-$(VERSION).tar.gz

.PHONY: all help test validate install dist srpm rpm clean

all: help

help:
	@echo "Cibles disponibles pour $(NAME) v$(VERSION) :"
	@echo "  make test      - Valide la syntaxe des scripts, configurations et fichiers .spec"
	@echo "  make install   - Installe les fichiers vers DESTDIR (défaut: /)"
	@echo "  make dist      - Génère l'archive tarball source ($(TARBALL))"
	@echo "  make srpm      - Génère le paquet source SRPM pour Fedora / COPR"
	@echo "  make rpm       - Construit le paquet binaire RPM noarch localement"
	@echo "  make clean     - Nettoie les répertoires et fichiers de construction"

test: validate

validate:
	@echo "=== [1/4] Validation syntaxique des scripts Bash ==="
	@bash -n kiosk/arrera-installer-kiosk.sh
	@bash -n kiosk/arrera-postinstall.sh
	@echo "-> Scripts Bash valides."
	@echo "=== [2/4] Validation des fichiers de configuration Calamares (YAML) ==="
	@python3 -c "import yaml, glob; \
		files = glob.glob('config/*.conf') + glob.glob('config/modules/*.conf') + glob.glob('branding/arrera/*.desc'); \
		[yaml.safe_load(open(f)) for f in files]; \
		print(f'-> {len(files)} fichiers YAML/desc validés avec succès.')"
	@echo "=== [3/4] Validation du fichier .desktop ==="
	@if command -v desktop-file-validate >/dev/null 2>&1; then \
		desktop-file-validate desktop/calamares-arrera.desktop && echo "-> Fichier .desktop conforme."; \
	else \
		echo "-> desktop-file-validate non installé, vérification ignorée."; \
	fi
	@echo "=== [4/4] Validation du fichier RPM spec ==="
	@if command -v rpmlint >/dev/null 2>&1; then \
		rpmlint rpm/$(NAME).spec || true; \
	else \
		echo "-> rpmlint non installé, vérification ignorée."; \
	fi
	@echo "=== Tous les tests ont réussi ! ==="

install:
	@echo "Installation vers $(DESTDIR)..."
	# Répertoires cibles
	install -d -m 0755 $(DESTDIR)$(CALAMARES_DIR)/modules
	install -d -m 0755 $(DESTDIR)$(BRANDING_DIR)/slideshow
	install -d -m 0755 $(DESTDIR)$(DATADIR)/calamares/qml
	install -d -m 0755 $(DESTDIR)$(BINDIR)
	install -d -m 0755 $(DESTDIR)$(UNITDIR)
	install -d -m 0755 $(DESTDIR)$(APPDIR)

	# Configuration Calamares
	install -m 0644 config/settings.conf $(DESTDIR)$(CALAMARES_DIR)/settings.conf
	install -m 0644 config/modules/*.conf $(DESTDIR)$(CALAMARES_DIR)/modules/

	install -m 0644 branding/arrera/branding.desc $(DESTDIR)$(BRANDING_DIR)/branding.desc
	install -m 0644 branding/arrera/stylesheet.qss $(DESTDIR)$(BRANDING_DIR)/stylesheet.qss
	install -m 0644 branding/arrera/arrera-logo.svg $(DESTDIR)$(BRANDING_DIR)/arrera-logo.svg
	install -m 0644 branding/arrera/*.png $(DESTDIR)$(BRANDING_DIR)/
	install -m 0644 branding/arrera/slideshow/*.qml $(DESTDIR)$(BRANDING_DIR)/
	cp -a branding/arrera/slideshow/* $(DESTDIR)$(BRANDING_DIR)/slideshow/

	# Mode Kiosque et post-installation
	install -m 0755 kiosk/arrera-installer-kiosk.sh $(DESTDIR)$(BINDIR)/arrera-installer-kiosk.sh
	install -m 0755 kiosk/arrera-postinstall.sh $(DESTDIR)$(BINDIR)/arrera-postinstall.sh
	install -m 0644 kiosk/arrera-kiosk.service $(DESTDIR)$(UNITDIR)/arrera-kiosk.service

	# Raccourci Desktop
	install -m 0644 desktop/calamares-arrera.desktop $(DESTDIR)$(APPDIR)/calamares-arrera.desktop
	@echo "Installation terminée avec succès."

dist: clean
	@echo "Création de l'archive $(TARBALL)..."
	@mkdir -p $(BUILD_DIR)/$(NAME)-$(VERSION)
	@cp -a Makefile README.md config branding kiosk desktop rpm $(BUILD_DIR)/$(NAME)-$(VERSION)/
	@tar -czf $(TARBALL) -C $(BUILD_DIR) $(NAME)-$(VERSION)
	@rm -rf $(BUILD_DIR)/$(NAME)-$(VERSION)
	@echo "Archive créée : $(TARBALL)"

srpm: dist
	@echo "Génération du paquet source (SRPM)..."
	@mkdir -p $(RPMBUILD_DIR)/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
	@mkdir -p $(OUTPUT_DIR)
	@cp $(TARBALL) $(RPMBUILD_DIR)/SOURCES/
	@cp $(SPEC_FILE) $(RPMBUILD_DIR)/SPECS/
	@rpmbuild -bs \
		--define "_topdir $(RPMBUILD_DIR)" \
		$(RPMBUILD_DIR)/SPECS/$(NAME).spec
	@cp $(RPMBUILD_DIR)/SRPMS/*.src.rpm $(OUTPUT_DIR)/
	@cp $(TARBALL) $(OUTPUT_DIR)/
	@echo "SRPM et archive générés dans $(OUTPUT_DIR)/"

rpm: dist
	@echo "Construction du paquet binaire RPM noarch..."
	@mkdir -p $(RPMBUILD_DIR)/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
	@mkdir -p $(OUTPUT_DIR)
	@cp $(TARBALL) $(RPMBUILD_DIR)/SOURCES/
	@cp $(SPEC_FILE) $(RPMBUILD_DIR)/SPECS/
	@rpmbuild -ba \
		--define "_topdir $(RPMBUILD_DIR)" \
		$(RPMBUILD_DIR)/SPECS/$(NAME).spec
	@cp $(RPMBUILD_DIR)/RPMS/noarch/*.rpm $(OUTPUT_DIR)/ || true
	@cp $(RPMBUILD_DIR)/SRPMS/*.src.rpm $(OUTPUT_DIR)/ || true
	@cp $(TARBALL) $(OUTPUT_DIR)/
	@echo "RPMs générés avec succès dans $(OUTPUT_DIR)/"

clean:
	@rm -rf $(BUILD_DIR) $(TARBALL) $(OUTPUT_DIR) *.src.rpm *.noarch.rpm
	@echo "Nettoyage terminé."
