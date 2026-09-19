import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: slide1
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
                text: "Bienvenue dans Arrera Linux"
                font.pixelSize: 28
                font.bold: true
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                text: "Une expérience bureau moderne, fluide et élégante propulsée par Fedora"
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
                        text: "🎨 Design Soigné"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#38bdf8"
                    }

                    Text {
                        text: "Identité visuelle Arrera Blue, fonds d'écran exclusifs et thème sombre harmonieux."
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
                        text: "⚡ GNOME Épuré"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#60a5fa"
                    }

                    Text {
                        text: "Bureau optimisé avec extensions préconfigurées pour un confort d'usage immédiat."
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
                        text: "🚀 Prêt à l'Emploi"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#93c5fd"
                    }

                    Text {
                        text: "Tous les outils essentiels préinstallés pour la création, le web et le multimédia."
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
