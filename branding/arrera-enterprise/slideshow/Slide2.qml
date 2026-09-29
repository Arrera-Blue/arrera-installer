import QtQuick
import QtQuick.Controls

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
                text: "Intégration Annuaire & Réseau d'Entreprise"
                font.family: "Cantarell"
                font.pixelSize: 26
                font.bold: true
                color: "#1e1e1e"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                text: "Connexion transparente aux infrastructures Microsoft et Linux"
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
                        text: "🏢"
                        font.pixelSize: 32
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Active Directory & IPA"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Jointure de domaine AD via SSSD et gestion centralisée des identités."
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
                        text: "🔑"
                        font.pixelSize: 32
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "SSO & Kerberos"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Authentification unique aux services internes et partages réseau SMB/NFS."
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
                        text: "🔒"
                        font.pixelSize: 32
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "VPN & Télétravail"
                        font.family: "Cantarell"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1e1e1e"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                    Text {
                        text: "Clients VPN OpenConnect, WireGuard et IPsec configurables en 1 clic."
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
