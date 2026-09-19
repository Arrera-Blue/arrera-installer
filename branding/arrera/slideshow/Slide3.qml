import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: slide3
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
                text: "Performance, Stabilité & Sécurité"
                font.family: "Cantarell"
                font.pixelSize: 26
                font.bold: true
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                text: "La puissance d'une base Fedora moderne supportant x86_64 et aarch64"
                font.family: "Cantarell"
                font.pixelSize: 15
                color: "#9a9996"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }

        // Séparateur décoratif Libadwaita Blue
        Rectangle {
            width: 120
            height: 3
            radius: 2
            anchors.horizontalCenter: parent.horizontalCenter
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#3584e4" }
                GradientStop { position: 1.0; color: "#62a0ea" }
            }
        }

        // Cartes de caractéristiques (Style Libadwaita Cards @card_bg_color #2e2e2e)
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Rectangle {
                width: 200
                height: 150
                radius: 12
                color: "#2e2e2e"
                border.color: "rgba(255, 255, 255, 0.08)"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        text: "🛡️ Sécurité SELinux"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#62a0ea"
                    }

                    Text {
                        text: "Protection maximale du système avec SELinux actif par défaut et pare-feu firewalld."
                        font.family: "Cantarell"
                        font.pixelSize: 12
                        color: "#deddda"
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }

            Rectangle {
                width: 200
                height: 150
                radius: 12
                color: "#2e2e2e"
                border.color: "rgba(255, 255, 255, 0.08)"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        text: "💻 x86_64 & aarch64"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#3584e4"
                    }

                    Text {
                        text: "Prise en charge complète des processeurs PC traditionnels et des plateformes ARM64."
                        font.family: "Cantarell"
                        font.pixelSize: 12
                        color: "#deddda"
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }

            Rectangle {
                width: 200
                height: 150
                radius: 12
                color: "#2e2e2e"
                border.color: "rgba(255, 255, 255, 0.08)"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        text: "⚡ Noyau Moderne"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#62a0ea"
                    }

                    Text {
                        text: "Support étendu du matériel le plus récent : GPU, écrans HiDPI, Wi-Fi 6/7 et Bluetooth."
                        font.family: "Cantarell"
                        font.pixelSize: 12
                        color: "#deddda"
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }
        }
    }
}
