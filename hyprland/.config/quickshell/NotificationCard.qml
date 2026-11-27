import QtQuick

Item {
    id: card

    property string notifKey: ""
    property string notifApp: ""
    property string notifSummary: ""
    property string notifBody: ""
    property string notifActionsJson: "[]"
    property bool compact: true
    property bool showSeparator: false

    readonly property var notifActions: {
        try {
            const parsed = JSON.parse(notifActionsJson)
            return Array.isArray(parsed) ? parsed : []
        } catch (error) {
            return []
        }
    }

    signal closeClicked(string entryKey)
    signal clicked(string entryKey)
    signal actionClicked(string entryKey, string identifier)

    implicitWidth: 650
    implicitHeight: Math.max(52, content.implicitHeight + 16)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked(card.notifKey)
    }

    Column {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 14
            rightMargin: 14
        }
        spacing: 2
        z: 1

        Text {
            anchors {
                left: parent.left
                right: parent.right
                rightMargin: 18
            }
            text: card.notifSummary
            color: "white"
            font.family: "Inter"
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            id: bodyText
            anchors {
                left: parent.left
                right: parent.right
                rightMargin: 18
            }
            text: card.notifBody
            color: Qt.rgba(1, 1, 1, 0.70)
            font.family: "Inter"
            font.pixelSize: 12
            wrapMode: Text.Wrap
            maximumLineCount: card.compact ? 2 : 6
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        Row {
            spacing: 8
            visible: card.notifActions.length > 0

            Repeater {
                model: card.notifActions

                delegate: Text {
                    required property var modelData

                    text: modelData.text || modelData.identifier
                    color: Qt.rgba(1, 1, 1, 0.75)
                    font.family: "Inter"
                    font.pixelSize: 11

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            mouse.accepted = true
                            card.actionClicked(card.notifKey, modelData.identifier)
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        visible: card.showSeparator
        color: Qt.rgba(1, 1, 1, 0.10)
    }

    Text {
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        text: "×"
        color: Qt.rgba(1, 1, 1, 0.55)
        font.family: "Inter"
        font.pixelSize: 18
        z: 2

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                mouse.accepted = true
                card.closeClicked(card.notifKey)
            }
        }
    }
}
