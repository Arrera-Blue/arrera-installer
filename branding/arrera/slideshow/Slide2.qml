import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: slide2
    anchors.fill: parent

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 680)
        spacing: 24

        // En-tête
        Column {
            width: parent.width
            spacing: 8

            Text {
                text: "Écosystème & Outils Arrera"
                font.pixelSize: 28
                font.bold: true
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                text: "Paquets optimisés et personnalisations via le dépôt copr-arrera-blue"
                font.pixelSize: 15
                color: "#94a3b8"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }

        // Séparateur décoratif dégradé
        Rectangle {
            width: 140
            height: 3
            radius: 2
            anchors.horizontalCenter: parent.horizontalCenter
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#2563eb" }
                GradientStop { position: 1.0; color: "#38bdf8" }
            }
        }

        // Cartes de caractéristiques
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Rectangle {
                width: 200
                height: 150
                radius: 12
                color: "#1e293b"
                border.color: "#334155"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        text: "📦 Dépôt COPR Dédié"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#38bdf8"
                    }

                    Text {
                        text: "Accès immédiat à la logithèque Arrera : arrera-branding, wallpapers et outils système."
                        font.pixelSize: 12
                        color: "#cbd5e1"
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }

            Rectangle {
                width: 200
                height: 150
                radius: 12
                color: "#1e293b"
                border.color: "#334155"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        text: "⚙️ Centre de Contrôle"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#60a5fa"
                    }

                    Text {
                        text: "Panneau de configuration unifié pour adapter Arrera à vos besoins en un clic."
                        font.pixelSize: 12
                        color: "#cbd5e1"
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }

            Rectangle {
                width: 200
                height: 150
                radius: 12
                color: "#1e293b"
                border.color: "#334155"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        text: "🌐 Flatpak & DNF"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#93c5fd"
                    }

                    Text {
                        text: "Compatibilité totale avec Flathub et les milliers de paquets du catalogue Fedora."
                        font.pixelSize: 12
                        color: "#cbd5e1"
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }
        }
    }
}
