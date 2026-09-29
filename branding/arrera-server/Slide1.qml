import QtQuick
import QtQuick.Controls

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
                text: "Bienvenue dans Arrera Blue Édition Serveur 2026"
                font.family: "Cantarell"
                font.pixelSize: 26
                font.bold: true
                color: "#1e1e1e"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                text: "Infrastructure moderne, console Cockpit et stabilité éprouvée"
                font.family: "Cantarell"
                font.pixelSize: 15
                color: "#5e5c64"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }

        // Séparateur décoratif GNOME Black
        Rectangle {
            width: 120
            height: 3
            radius: 2
            anchors.horizontalCenter: parent.horizontalCenter
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#303030" }
                GradientStop { position: 1.0; color: "#5e5c64" }
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
                color: "#ffffff"
                border.color: "rgba(0, 0, 0, 0.08)"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    spacing: 10

                    Text {
                        text: "🎛️"
                        font.pixelSize: 32
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Console Cockpit"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Supervisez disques, métriques et réseaux depuis votre navigateur."
                        font.family: "Cantarell"
                        font.pixelSize: 12
                        color: "#5e5c64"
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                }
            }

            Rectangle {
                width: 200
                height: 150
                radius: 12
                color: "#ffffff"
                border.color: "rgba(0, 0, 0, 0.08)"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    spacing: 10

                    Text {
                        text: "⚡"
                        font.pixelSize: 32
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Performances Brutes"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Empreinte mémoire minimale et latence réseau optimisée."
                        font.family: "Cantarell"
                        font.pixelSize: 12
                        color: "#5e5c64"
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                }
            }

            Rectangle {
                width: 200
                height: 150
                radius: 12
                color: "#ffffff"
                border.color: "rgba(0, 0, 0, 0.08)"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    spacing: 10

                    Text {
                        text: "🛡️"
                        font.pixelSize: 32
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Sécurité Durcie"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "SELinux natif, pare-feu réseau et journalisation centralisée."
                        font.family: "Cantarell"
                        font.pixelSize: 12
                        color: "#5e5c64"
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                }
            }
        }
    }
}
