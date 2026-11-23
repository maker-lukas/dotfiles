import QtQuick

Rectangle {
    id: root

    property alias textInput: searchField
    property alias query: searchField.text

    signal up()
    signal down()
    signal activate()
    signal escaped()

    radius: 12
    color: Qt.rgba(1, 1, 1, 0.08)

    Text {
        anchors.fill: searchField
        verticalAlignment: Text.AlignVCenter
        text: "Type to search "
        color: Qt.rgba(1, 1, 1, 0.45)
        font.family: "Inter"
        font.pixelSize: 16
        visible: searchField.text === ""
    }

    TextInput {
        id: searchField
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        verticalAlignment: TextInput.AlignVCenter
        color: "white"
        font.family: "Inter"
        font.pixelSize: 16
        selectByMouse: true

        Keys.onUpPressed: event => { root.up(); event.accepted = true }
        Keys.onDownPressed: event => { root.down(); event.accepted = true }
        Keys.onReturnPressed: event => { root.activate(); event.accepted = true }
        Keys.onEscapePressed: event => { root.escaped(); event.accepted = true }
    }
}