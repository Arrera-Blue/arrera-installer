#!/usr/bin/env python3
# ==============================================================================
# Arrera Linux - Assistant graphique de connexion Wi-Fi
# Détecte le matériel Wi-Fi, scanne les réseaux et permet la connexion
# avant le lancement de Calamares en session Kiosque ou Bureau.
# ==============================================================================

import os
import sys
import subprocess
import socket
import re
import threading

def is_online():
    """Vérifie rapidement si la machine a déjà un accès Internet fonctionnel."""
    for host in [("1.1.1.1", 53), ("8.8.8.8", 53), ("9.9.9.9", 53)]:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1.5)
            sock.connect(host)
            sock.close()
            return True
        except Exception:
            continue
    return False

def get_wifi_devices():
    """Retourne la liste des cartes Wi-Fi disponibles via NetworkManager."""
    try:
        out = subprocess.check_output(
            ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device"],
            stderr=subprocess.DEVNULL,
            universal_newlines=True
        )
        devices = []
        for line in out.strip().splitlines():
            parts = line.split(":")
            if len(parts) >= 3 and parts[1] == "wifi":
                devices.append({"device": parts[0], "state": parts[2]})
        return devices
    except Exception:
        return []

def scan_wifi_networks():
    """Scanne les réseaux Wi-Fi aux alentours et retourne une liste dédoublonnée."""
    networks = []
    seen_ssids = set()
    try:
        # Forcer un scan rapide NetworkManager
        subprocess.run(["nmcli", "device", "wifi", "rescan"], stderr=subprocess.DEVNULL, timeout=4)
    except Exception:
        pass

    try:
        out = subprocess.check_output(
            ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"],
            stderr=subprocess.DEVNULL,
            universal_newlines=True
        )
        for line in out.strip().splitlines():
            # nmcli -t sépare par ':' mais attention aux ':' échappés
            parts = line.split(":")
            if len(parts) < 4:
                continue
            in_use = (parts[0] == "*")
            ssid = parts[1].replace("\\:", ":").strip()
            signal_str = parts[2].strip()
            security = parts[3].strip()

            if not ssid:
                continue  # Réseau masqué

            try:
                signal = int(signal_str)
            except ValueError:
                signal = 50

            if ssid in seen_ssids:
                continue
            seen_ssids.add(ssid)

            is_secured = bool(security and security != "--")
            networks.append({
                "ssid": ssid,
                "signal": signal,
                "security": security if is_secured else "Ouvert",
                "is_secured": is_secured,
                "in_use": in_use
            })
    except Exception:
        pass

    # Trier par signal décroissant (les réseaux les plus proches en premier)
    networks.sort(key=lambda x: x["signal"], reverse=True)
    return networks

def connect_network(ssid, password=None):
    """Tente la connexion au réseau Wi-Fi sélectionné via nmcli."""
    try:
        cmd = ["nmcli", "device", "wifi", "connect", ssid]
        if password:
            cmd.extend(["password", password])
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, timeout=25)
        if res.returncode == 0:
            return True, "Connexion établie avec succès."
        else:
            err = res.stderr.strip() or res.stdout.strip() or "Erreur inconnue."
            return False, err
    except subprocess.TimeoutExpired:
        return False, "Délai de connexion dépassé. Vérifiez le mot de passe."
    except Exception as e:
        return False, str(e)


# ==============================================================================
# Interface Graphique GTK (PyGObject - Libadwaita / GTK3)
# ==============================================================================
def run_gtk_ui():
    import gi
    try:
        gi.require_version("Gtk", "3.0")
        from gi.repository import Gtk, Gdk, GLib
        init_res = Gtk.init_check()
        init_ok = init_res[0] if isinstance(init_res, (tuple, list)) else bool(init_res)
        if not init_ok:
            print("Aucun serveur d'affichage graphique (Wayland ou X11) actif pour GTK.", file=sys.stderr)
            return False
    except Exception as e:
        print(f"GTK3 non disponible : {e}", file=sys.stderr)
        return False

    class WifiSetupWindow(Gtk.Window):
        def __init__(self):
            super().__init__(title="Arrera Linux - Connexion Wi-Fi")
            self.set_default_size(520, 600)
            self.set_position(Gtk.WindowPosition.CENTER)
            self.set_border_width(0)

            # Style CSS épuré inspiré de Libadwaita Light
            css = b"""
            window {
                background-color: #fafafa;
                font-family: 'Cantarell', 'Segoe UI', 'Ubuntu', sans-serif;
            }
            .header-box {
                background-color: #ffffff;
                border-bottom: 1px solid rgba(0, 0, 0, 0.08);
                padding: 24px 24px 20px 24px;
            }
            .title {
                font-size: 20px;
                font-weight: 700;
                color: #1e1e1e;
            }
            .subtitle {
                font-size: 13px;
                color: #5e5c64;
                margin-top: 4px;
            }
            .content-box {
                padding: 20px 24px;
            }
            .list-frame {
                background-color: #ffffff;
                border: 1px solid rgba(0, 0, 0, 0.10);
                border-radius: 12px;
            }
            .wifi-row {
                padding: 10px 14px;
                border-bottom: 1px solid rgba(0, 0, 0, 0.05);
            }
            .wifi-row:selected {
                background-color: #21a48c;
                color: #ffffff;
            }
            .wifi-ssid {
                font-size: 14px;
                font-weight: 600;
            }
            .wifi-meta {
                font-size: 12px;
                color: #5e5c64;
            }
            .btn-primary {
                background-color: #21a48c;
                color: #ffffff;
                font-weight: 600;
                border-radius: 8px;
                padding: 10px 20px;
                border: none;
            }
            .btn-primary:hover {
                background-color: #198470;
            }
            .btn-secondary {
                background-color: #ffffff;
                color: #1e1e1e;
                font-weight: 500;
                border-radius: 8px;
                padding: 10px 18px;
                border: 1px solid rgba(0, 0, 0, 0.15);
            }
            .btn-secondary:hover {
                background-color: #f6f6f6;
            }
            .password-entry {
                background-color: #ffffff;
                border: 1px solid rgba(0, 0, 0, 0.15);
                border-radius: 8px;
                padding: 8px 12px;
                font-size: 14px;
            }
            .password-entry:focus {
                border-color: #21a48c;
            }
            """
            style_provider = Gtk.CssProvider()
            style_provider.load_from_data(css)
            Gtk.StyleContext.add_provider_for_screen(
                Gdk.Screen.get_default(),
                style_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )

            # Structure principale
            main_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
            self.add(main_vbox)

            # En-tête
            header_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            header_box.get_style_context().add_class("header-box")

            title_lbl = Gtk.Label(label="Connexion Wi-Fi", xalign=0)
            title_lbl.get_style_context().add_class("title")
            header_box.pack_start(title_lbl, False, False, 0)

            sub_lbl = Gtk.Label(
                label="Connectez-vous à un réseau sans fil pour bénéficier des dernières mises à jour,\nou passez cette étape pour une installation hors-ligne autonome.",
                xalign=0
            )
            sub_lbl.set_line_wrap(True)
            sub_lbl.get_style_context().add_class("subtitle")
            header_box.pack_start(sub_lbl, False, False, 0)

            main_vbox.pack_start(header_box, False, False, 0)

            # Corps
            content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
            content_box.get_style_context().add_class("content-box")
            main_vbox.pack_start(content_box, True, True, 0)

            # Barre d'état de la liste avec bouton Actualiser
            list_header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            list_title = Gtk.Label(label="Réseaux détectés :", xalign=0)
            list_title.set_hexpand(True)
            list_header.pack_start(list_title, True, True, 0)

            self.btn_refresh = Gtk.Button(label="⟳ Actualiser")
            self.btn_refresh.get_style_context().add_class("btn-secondary")
            self.btn_refresh.connect("clicked", self.on_refresh_clicked)
            list_header.pack_start(self.btn_refresh, False, False, 0)
            content_box.pack_start(list_header, False, False, 0)

            # Liste déroulante des réseaux
            scrolled = Gtk.ScrolledWindow()
            scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
            scrolled.set_min_content_height(180)
            scrolled.get_style_context().add_class("list-frame")

            self.listbox = Gtk.ListBox()
            self.listbox.set_selection_mode(Gtk.SelectionMode.SINGLE)
            self.listbox.connect("row-selected", self.on_row_selected)
            scrolled.add(self.listbox)
            content_box.pack_start(scrolled, True, True, 0)

            # Zone mot de passe
            self.pwd_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
            pwd_lbl = Gtk.Label(label="Mot de passe du réseau :", xalign=0)
            self.pwd_box.pack_start(pwd_lbl, False, False, 0)

            pwd_input_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            self.entry_pwd = Gtk.Entry()
            self.entry_pwd.set_visibility(False)
            self.entry_pwd.set_hexpand(True)
            self.entry_pwd.get_style_context().add_class("password-entry")
            self.entry_pwd.connect("activate", lambda w: self.on_connect_clicked(None))
            pwd_input_box.pack_start(self.entry_pwd, True, True, 0)

            self.btn_show_pwd = Gtk.Button(label="👁")
            self.btn_show_pwd.set_tooltip_text("Afficher / Masquer le mot de passe")
            self.btn_show_pwd.get_style_context().add_class("btn-secondary")
            self.btn_show_pwd.connect("clicked", self.on_toggle_password)
            pwd_input_box.pack_start(self.btn_show_pwd, False, False, 0)

            self.pwd_box.pack_start(pwd_input_box, False, False, 0)
            content_box.pack_start(self.pwd_box, False, False, 0)

            # Label de statut (message d'erreur ou succès)
            self.lbl_status = Gtk.Label(label="", xalign=0)
            self.lbl_status.set_line_wrap(True)
            content_box.pack_start(self.lbl_status, False, False, 0)

            # Barre inférieure d'actions
            btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
            btn_box.set_margin_top(10)

            self.btn_skip = Gtk.Button(label="Installer hors-ligne")
            self.btn_skip.get_style_context().add_class("btn-secondary")
            self.btn_skip.connect("clicked", self.on_skip_clicked)
            btn_box.pack_start(self.btn_skip, False, False, 0)

            spacer = Gtk.Box()
            spacer.set_hexpand(True)
            btn_box.pack_start(spacer, True, True, 0)

            self.btn_connect = Gtk.Button(label="Se connecter")
            self.btn_connect.get_style_context().add_class("btn-primary")
            self.btn_connect.set_sensitive(False)
            self.btn_connect.connect("clicked", self.on_connect_clicked)
            btn_box.pack_start(self.btn_connect, False, False, 0)

            content_box.pack_start(btn_box, False, False, 0)

            self.networks = []
            self.selected_network = None
            self.load_networks_async()

        def load_networks_async(self):
            self.lbl_status.set_text("Recherche des réseaux Wi-Fi disponibles...")
            self.btn_refresh.set_sensitive(False)

            def worker():
                nets = scan_wifi_networks()
                GLib.idle_add(self.update_networks_list, nets)

            threading.Thread(target=worker, daemon=True).start()

        def update_networks_list(self, networks):
            self.networks = networks
            self.btn_refresh.set_sensitive(True)

            # Vider la liste existante
            for child in self.listbox.get_children():
                self.listbox.remove(child)

            if not networks:
                self.lbl_status.set_text("Aucun réseau Wi-Fi détecté à proximité.")
                self.pwd_box.set_sensitive(False)
                self.btn_connect.set_sensitive(False)
                return

            self.lbl_status.set_text("")
            for net in networks:
                row = Gtk.ListBoxRow()
                row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
                row_box.get_style_context().add_class("wifi-row")

                # Icône de signal stylisée
                sig = net["signal"]
                if sig >= 75:
                    sig_icon = "▂▄▆█"
                elif sig >= 50:
                    sig_icon = "▂▄▆_"
                elif sig >= 25:
                    sig_icon = "▂▄__"
                else:
                    sig_icon = "▂___"

                sig_lbl = Gtk.Label(label=sig_icon)
                row_box.pack_start(sig_lbl, False, False, 0)

                # Nom du réseau
                ssid_lbl = Gtk.Label(label=net["ssid"], xalign=0)
                ssid_lbl.get_style_context().add_class("wifi-ssid")
                ssid_lbl.set_hexpand(True)
                row_box.pack_start(ssid_lbl, True, True, 0)

                # Sécurité
                sec_text = "🔒 " + net["security"] if net["is_secured"] else "Libre"
                if net["in_use"]:
                    sec_text = "✓ Connecté"
                sec_lbl = Gtk.Label(label=sec_text)
                sec_lbl.get_style_context().add_class("wifi-meta")
                row_box.pack_start(sec_lbl, False, False, 0)

                row.add(row_box)
                row.network_data = net
                self.listbox.add(row)

            self.listbox.show_all()

        def on_row_selected(self, listbox, row):
            if row is None:
                self.selected_network = None
                self.btn_connect.set_sensitive(False)
                return

            self.selected_network = row.network_data
            self.btn_connect.set_sensitive(True)
            self.lbl_status.set_text("")

            if self.selected_network["is_secured"]:
                self.pwd_box.set_sensitive(True)
                self.entry_pwd.grab_focus()
            else:
                self.pwd_box.set_sensitive(False)
                self.entry_pwd.set_text("")

        def on_toggle_password(self, btn):
            vis = self.entry_pwd.get_visibility()
            self.entry_pwd.set_visibility(not vis)

        def on_refresh_clicked(self, btn):
            self.load_networks_async()

        def on_skip_clicked(self, btn):
            print("Utilisateur a choisi d'ignorer la connexion Wi-Fi.", file=sys.stderr)
            Gtk.main_quit()
            sys.exit(0)

        def on_connect_clicked(self, btn):
            if not self.selected_network:
                return

            ssid = self.selected_network["ssid"]
            pwd = self.entry_pwd.get_text().strip() if self.selected_network["is_secured"] else None

            if self.selected_network["is_secured"] and not pwd:
                self.lbl_status.set_markup("<span color='#c01c28'>Veuillez saisir la clé de sécurité pour ce réseau.</span>")
                self.entry_pwd.grab_focus()
                return

            self.lbl_status.set_text(f"Connexion en cours à « {ssid} »...")
            self.btn_connect.set_sensitive(False)
            self.btn_skip.set_sensitive(False)
            self.btn_refresh.set_sensitive(False)

            def worker():
                ok, msg = connect_network(ssid, pwd)
                GLib.idle_add(self.on_connect_done, ok, msg, ssid)

            threading.Thread(target=worker, daemon=True).start()

        def on_connect_done(self, ok, msg, ssid):
            self.btn_connect.set_sensitive(True)
            self.btn_skip.set_sensitive(True)
            self.btn_refresh.set_sensitive(True)

            if ok:
                self.lbl_status.set_markup(f"<span color='#21a48c'><b>✓ Connecté avec succès à « {ssid} » !</b></span>")
                # Fermer automatiquement après 1.2s et continuer vers Calamares
                GLib.timeout_add(1200, lambda: (Gtk.main_quit(), sys.exit(0)))
            else:
                self.lbl_status.set_markup(f"<span color='#c01c28'>Échec de la connexion : {msg}</span>")

    win = WifiSetupWindow()
    win.connect("destroy", lambda w: (Gtk.main_quit(), sys.exit(0)))
    win.show_all()
    Gtk.main()
    return True


# ==============================================================================
# Interface Console Texte Interactif (Fallback sans serveur d'affichage)
# ==============================================================================
def run_cli_ui():
    print("\n" + "=" * 58)
    print("      Arrera Linux - Assistant Wi-Fi (Mode Console)")
    print("=" * 58)
    print("Recherche des réseaux Wi-Fi disponibles...")
    networks = scan_wifi_networks()
    if not networks:
        print("Aucun réseau Wi-Fi détecté.")
        return False

    print("\nRéseaux sans fil détectés :")
    for idx, net in enumerate(networks, 1):
        sec = "🔒 " + net["security"] if net["is_secured"] else "Ouvert"
        active = " (Actuellement connecté)" if net["in_use"] else ""
        print(f"  {idx}) {net['ssid']} [{net['signal']}%] [{sec}]{active}")
    print("  0) Passer / Installer hors-ligne")
    print("=" * 58)

    try:
        raw = input(f"Votre choix [0-{len(networks)}] (défaut: 0) : ").strip()
        if not raw or raw == "0":
            print("Installation hors-ligne sélectionnée.")
            return True
        choice = int(raw) - 1
        if 0 <= choice < len(networks):
            target = networks[choice]
            pwd = None
            if target["is_secured"]:
                import getpass
                pwd = getpass.getpass(f"Mot de passe pour « {target['ssid']} » : ")
            print(f"Connexion en cours à « {target['ssid']} »...")
            ok, msg = connect_network(target["ssid"], pwd)
            if ok:
                print(f"✓ Connecté avec succès à « {target['ssid']} » !")
                return True
            else:
                print(f"✗ Échec de connexion : {msg}")
                return False
    except (KeyboardInterrupt, EOFError):
        print("\nPassé.")
        return True
    return False


# ==============================================================================
# Point d'Entrée Principal
# ==============================================================================
def main():
    force_gui = ("--force" in sys.argv or "-f" in sys.argv)

    # 1. Vérifier si Internet est déjà disponible
    if not force_gui and is_online():
        print("Internet est déjà actif (câble Ethernet ou Wi-Fi connecté). Assistant ignoré.")
        sys.exit(0)

    # 2. Vérifier si un périphérique Wi-Fi physique est présent
    wifi_devs = get_wifi_devices()
    if not force_gui and not wifi_devs:
        print("Aucune carte Wi-Fi détectée. Assistant ignoré.")
        sys.exit(0)

    # 3. Lancer l'interface GTK
    print(f"Lancement de l'assistant Wi-Fi (Cartes trouvées : {[d['device'] for d in wifi_devs]})...")
    ok = run_gtk_ui()
    if not ok:
        print("Serveur graphique non disponible, basculement en mode console...")
        run_cli_ui()
        sys.exit(0)

if __name__ == "__main__":
    main()
