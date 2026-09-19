#!/usr/bin/env python3
"""
Générateur d'illustrations professionnelles pour le choix du mode d'installation
(Online vs Offline) dans Calamares pour Arrera Blue 2026.
Style : GNOME 46+ / GTK 4 / Libadwaita Dark
"""

from PIL import Image, ImageDraw, ImageFont
import os

FONT_BOLD = "/usr/share/fonts/liberation-sans-fonts/LiberationSans-Bold.ttf"
FONT_REG = "/usr/share/fonts/liberation-sans-fonts/LiberationSans-Regular.ttf"

def get_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except:
        return ImageFont.load_default()

def draw_rounded_rect(draw, bbox, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(bbox, radius=radius, fill=fill, outline=outline, width=width)

def generate_online_image(filename):
    W, H = 600, 420
    scale = 2
    img = Image.new("RGBA", (W * scale, H * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Carte principale Libadwaita (@card_bg_color #2e2e2e)
    card_margin = 16 * scale
    card_bbox = (card_margin, card_margin, (W - 16) * scale, (H - 16) * scale)
    draw_rounded_rect(draw, card_bbox, 16 * scale, fill=(46, 46, 46, 255), outline=(255, 255, 255, 26), width=1 * scale)

    # 2. Badge supérieur Libadwaita Pill
    badge_w, badge_h = 240 * scale, 34 * scale
    badge_x = (W * scale - badge_w) // 2
    badge_y = 36 * scale
    draw_rounded_rect(draw, (badge_x, badge_y, badge_x + badge_w, badge_y + badge_h), 17 * scale, fill=(53, 132, 228, 40), outline=(53, 132, 228, 180), width=1 * scale)
    
    font_badge = get_font(FONT_BOLD, 12 * scale)
    draw.text((badge_x + 22 * scale, badge_y + 9 * scale), "CONNECTÉ • MODE EN LIGNE", fill=(98, 160, 234, 255), font=font_badge)

    # 3. Illustration centrale : Nuage & Réseau GNOME Adwaita
    cx, cy = (W * scale) // 2, 175 * scale

    for r, alpha in [(105 * scale, 25), (80 * scale, 45), (55 * scale, 70)]:
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(53, 132, 228, alpha), width=2 * scale)

    # Nuage Adwaita Bleu (#3584e4)
    cloud_color = (53, 132, 228, 255)
    draw.ellipse((cx - 65 * scale, cy - 30 * scale, cx + 5 * scale, cy + 30 * scale), fill=cloud_color)
    draw.ellipse((cx - 25 * scale, cy - 50 * scale, cx + 45 * scale, cy + 20 * scale), fill=(98, 160, 234, 255))
    draw.ellipse((cx + 10 * scale, cy - 25 * scale, cx + 65 * scale, cy + 30 * scale), fill=cloud_color)
    draw_rounded_rect(draw, (cx - 55 * scale, cy - 5 * scale, cx + 55 * scale, cy + 30 * scale), 12 * scale, fill=cloud_color)

    # Flèche de téléchargement centrale blanche
    arrow_color = (255, 255, 255, 255)
    draw.rectangle((cx - 10 * scale, cy - 35 * scale, cx + 10 * scale, cy + 8 * scale), fill=arrow_color)
    arrow_pts = [
        (cx - 26 * scale, cy + 5 * scale),
        (cx + 26 * scale, cy + 5 * scale),
        (cx, cy + 35 * scale)
    ]
    draw.polygon(arrow_pts, fill=arrow_color)
    draw_rounded_rect(draw, (cx - 36 * scale, cy + 42 * scale, cx + 36 * scale, cy + 48 * scale), 3 * scale, fill=(98, 160, 234, 255))

    # 4. Titre de présentation
    font_title = get_font(FONT_BOLD, 18 * scale)
    title_text = "Installation & Mises à Jour en Direct"
    bbox_title = draw.textbbox((0, 0), title_text, font=font_title)
    draw.text(((W * scale - (bbox_title[2] - bbox_title[0])) // 2, 260 * scale), title_text, fill=(255, 255, 255, 255), font=font_title)

    # 5. Points clés / Caractéristiques
    font_items = get_font(FONT_REG, 13 * scale)
    items = [
        "✓  Dépôts Fedora et COPR copr-arrera-blue synchronisés",
        "✓  Derniers correctifs de sécurité et logiciels récents installés",
        "✓  Système prêt à l'emploi et 100% à jour dès le premier démarrage"
    ]
    start_y = 300 * scale
    for i, item in enumerate(items):
        bbox_it = draw.textbbox((0, 0), item, font=font_items)
        it_x = (W * scale - (bbox_it[2] - bbox_it[0])) // 2
        draw.text((it_x, start_y + i * 26 * scale), item, fill=(222, 221, 218, 255), font=font_items)

    img_final = img.resize((W, H), Image.Resampling.LANCZOS)
    img_final.save(filename, "PNG")
    print(f"Généré : {filename}")

def generate_offline_image(filename):
    W, H = 600, 420
    scale = 2
    img = Image.new("RGBA", (W * scale, H * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Carte principale Libadwaita (@card_bg_color #2e2e2e)
    card_margin = 16 * scale
    card_bbox = (card_margin, card_margin, (W - 16) * scale, (H - 16) * scale)
    draw_rounded_rect(draw, card_bbox, 16 * scale, fill=(46, 46, 46, 255), outline=(255, 255, 255, 26), width=1 * scale)

    # 2. Badge supérieur Libadwaita Pill
    badge_w, badge_h = 240 * scale, 34 * scale
    badge_x = (W * scale - badge_w) // 2
    badge_y = 36 * scale
    draw_rounded_rect(draw, (badge_x, badge_y, badge_x + badge_w, badge_y + badge_h), 17 * scale, fill=(53, 132, 228, 40), outline=(53, 132, 228, 180), width=1 * scale)
    
    font_badge = get_font(FONT_BOLD, 12 * scale)
    draw.text((badge_x + 18 * scale, badge_y + 9 * scale), "AUTONOME • MODE HORS-LIGNE", fill=(98, 160, 234, 255), font=font_badge)

    # 3. Illustration centrale : Clé Live USB / Disque Haute Vitesse
    cx, cy = (W * scale) // 2, 175 * scale

    for r, alpha in [(105 * scale, 25), (80 * scale, 45), (55 * scale, 70)]:
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(53, 132, 228, alpha), width=2 * scale)

    # Corps de la clé USB
    usb_w, usb_h = 80 * scale, 50 * scale
    usb_x, usb_y = cx - usb_w // 2, cy - usb_h // 2
    draw_rounded_rect(draw, (usb_x, usb_y, usb_x + usb_w, usb_y + usb_h), 8 * scale, fill=(36, 36, 36, 255), outline=(53, 132, 228, 255), width=2 * scale)

    # Connecteur métallique USB
    conn_w, conn_h = 32 * scale, 24 * scale
    conn_x, conn_y = cx + usb_w // 2, cy - conn_h // 2
    draw_rounded_rect(draw, (conn_x, conn_y, conn_x + conn_w, conn_y + conn_h), 3 * scale, fill=(154, 153, 150, 255), outline=(222, 221, 218, 255), width=2 * scale)
    draw.line((conn_x + 8 * scale, conn_y + 6 * scale, conn_x + 24 * scale, conn_y + 6 * scale), fill=(60, 60, 60, 255), width=2 * scale)
    draw.line((conn_x + 8 * scale, conn_y + 16 * scale, conn_x + 24 * scale, conn_y + 16 * scale), fill=(60, 60, 60, 255), width=2 * scale)

    # Éclair bleu Libadwaita (#3584e4 / #62a0ea)
    lightning_pts = [
        (cx - 2 * scale, cy - 20 * scale),
        (cx - 16 * scale, cy + 2 * scale),
        (cx - 3 * scale, cy + 2 * scale),
        (cx - 8 * scale, cy + 20 * scale),
        (cx + 14 * scale, cy - 4 * scale),
        (cx + 2 * scale, cy - 4 * scale)
    ]
    draw.polygon(lightning_pts, fill=(98, 160, 234, 255))
    draw.ellipse((usb_x + 12 * scale, cy - 4 * scale, usb_x + 20 * scale, cy + 4 * scale), fill=(46, 194, 126, 255))

    # 4. Titre de présentation
    font_title = get_font(FONT_BOLD, 18 * scale)
    title_text = "Installation Rapide depuis l'Image Live"
    bbox_title = draw.textbbox((0, 0), title_text, font=font_title)
    draw.text(((W * scale - (bbox_title[2] - bbox_title[0])) // 2, 260 * scale), title_text, fill=(255, 255, 255, 255), font=font_title)

    # 5. Points clés / Caractéristiques
    font_items = get_font(FONT_REG, 13 * scale)
    items = [
        "⚡  Décompression ultra-rapide directement depuis le média d'installation",
        "⚡  Aucune connexion Internet ou réseau requise pour terminer l'installation",
        "⚡  Environnement Arrera Blue complet et autonome garanti"
    ]
    start_y = 300 * scale
    for i, item in enumerate(items):
        bbox_it = draw.textbbox((0, 0), item, font=font_items)
        it_x = (W * scale - (bbox_it[2] - bbox_it[0])) // 2
        draw.text((it_x, start_y + i * 26 * scale), item, fill=(222, 221, 218, 255), font=font_items)

    img_final = img.resize((W, H), Image.Resampling.LANCZOS)
    img_final.save(filename, "PNG")
    print(f"Généré : {filename}")

if __name__ == "__main__":
    out_dir = os.path.dirname(os.path.abspath(__file__))
    generate_online_image(os.path.join(out_dir, "online-mode.png"))
    generate_offline_image(os.path.join(out_dir, "offline-mode.png"))
