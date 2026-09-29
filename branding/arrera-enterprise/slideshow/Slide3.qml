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
                text: "Déploiement Industriel & Supervision"
                font.family: "Cantarell"
                font.pixelSize: 26
                font.bold: true
                color: "#1e1e1e"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                text: "Automatisation de masse pour administrateurs et responsables de parc"
                font.family: "Cantarell"
                font.pixelSize: 15
                color: "#5e5c64"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }

        // Séparateur décoratif GNOME Purple
        Rectangle {
            width: 120
            height: 3
            radius: 2
            anchors.horizontalCenter: parent.horizontalCenter
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#9141ac" }
                GradientStop { position: 1.0; color: "#c061cb" }
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
                        text: "🤖"
                        font.pixelSize: 32
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Ansible & Kickstart"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Déploiement automatisé sans intervention humaine sur des centaines de postes."
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
                        text: "📊"
                        font.pixelSize: 32
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Inventaire de Parc"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Agents d'inventaire matériel et logiciel pour le suivi GLPI et gestion des assets."
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
                        text: "Stratégies dconf"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Verrouillage granulaire des paramètres utilisateurs via politiques dconf centralisées."
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
