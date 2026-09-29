import QtQuick
import QtQuick.Controls

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
                text: "Fiabilité & Écosystème Arrera"
                font.family: "Cantarell"
                font.pixelSize: 26
                font.bold: true
                color: "#1e1e1e"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                text: "La puissance d'une base Fedora stable avec le raffinement Arrera"
                font.family: "Cantarell"
                font.pixelSize: 15
                color: "#5e5c64"
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
                        text: "🛡️"
                        font.pixelSize: 32
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Sécurité Native"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Protection SELinux et pare-feu actif dès le premier démarrage."
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
                        text: "🔄"
                        font.pixelSize: 32
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Mises à Jour Douces"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Mises à niveau système transparentes sans interruption."
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
                        text: "x86_64 & ARM64"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Parfaitement optimisé pour PC fixes, portables et puces ARM."
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
