import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: presentation
    color: "#0f172a"
    anchors.fill: parent

    property int currentSlide: 0
    property int totalSlides: 3

    // Conteneur des diapositives
    Item {
        id: slidesContainer
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: indicatorsRow.top
        anchors.margins: 20

        Slide1 {
            id: s1
            anchors.fill: parent
            opacity: presentation.currentSlide === 0 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 500 } }
        }

        Slide2 {
            id: s2
            anchors.fill: parent
            opacity: presentation.currentSlide === 1 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 500 } }
        }

        Slide3 {
            id: s3
            anchors.fill: parent
            opacity: presentation.currentSlide === 2 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 500 } }
        }
    }

    // Minuteur automatique de rotation des diapositives (toutes les 9 secondes)
    Timer {
        id: slideTimer
        interval: 9000
        running: true
        repeat: true
        onTriggered: {
            presentation.currentSlide = (presentation.currentSlide + 1) % presentation.totalSlides;
        }
    }

    // Indicateurs de pagination en bas
    Row {
        id: indicatorsRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        spacing: 12

        Repeater {
            model: presentation.totalSlides
            Rectangle {
                width: index === presentation.currentSlide ? 28 : 10
                height: 10
                radius: 5
                color: index === presentation.currentSlide ? "#38bdf8" : "#334155"
                Behavior on width { NumberAnimation { duration: 250 } }
                Behavior on color { ColorAnimation { duration: 250 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        presentation.currentSlide = index;
                        slideTimer.restart();
                    }
                }
            }
        }
    }
}
