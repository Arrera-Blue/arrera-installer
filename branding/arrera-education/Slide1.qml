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
                text: "Bienvenue dans Arrera Blue Édition Éducation 2026"
                font.family: "Cantarell"
                font.pixelSize: 26
                font.bold: true
                color: "#1e1e1e"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                text: "L'informatique libre, intuitive et adaptée au milieu scolaire"
                font.family: "Cantarell"
                font.pixelSize: 15
                color: "#5e5c64"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }

        // Séparateur décoratif GNOME Turquoise
        Rectangle {
            width: 120
            height: 3
            radius: 2
            anchors.horizontalCenter: parent.horizontalCenter
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#21a48c" }
                GradientStop { position: 1.0; color: "#35bca2" }
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
                        text: "🎓"
                        font.pixelSize: 32
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Conçu pour l'École"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Interface claire et accessible pour les élèves et enseignants."
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
                        text: "💡"
                        font.pixelSize: 32
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Apprentissage Actif"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Encourage la curiosité, l'autonomie et la créativité numérique."
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
                        text: "Protection & RGPD"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Protection des données scolaires sans profilage publicitaire."
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
