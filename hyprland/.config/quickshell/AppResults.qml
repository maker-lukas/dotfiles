import QtQuick
import Quickshell

Item {
    id: root

    property string query: ""
    property int selected: 0
    property int maxResults: 50

    signal launched()

    readonly property var apps: {
        const q = root.query.trim().toLowerCase()
        const all = DesktopEntries.applications.values
        const matches = q === ""
            ? all
            : all.filter(app =>
                app.name.toLowerCase().includes(q) ||
                (app.genericName || "").toLowerCase().includes(q) ||
                (app.comment || "").toLowerCase().includes(q) ||
                app.id.toLowerCase().includes(q))

        return matches.slice(0, root.maxResults)
    }

    function moveUp() {
        if (root.query.trim() === "") return
        root.selected = Math.max(0, root.selected - 1)
    }

    function moveDown() {
        if (root.query.trim() === "") return
        root.selected = Math.min(Math.max(0, root.apps.length - 1), root.selected + 1)
    }

    function launch(index) {
        if (root.query.trim() === "") return
        const app = root.apps[index]
        if (!app) return
        app.execute()
        root.launched()
    }

    function activate() {
        root.launch(root.selected)
    }

    onQueryChanged: root.selected = 0
    onAppsChanged: root.selected = Math.min(root.selected, Math.max(0, root.apps.length - 1))

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        model: root.apps
        currentIndex: root.selected
        highlightMoveDuration: 120

        delegate: Item {
            id: row
            required property var modelData
            required property int index

            width: list.width
            height: 46

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: row.index === root.selected
                    ? Qt.rgba(1, 1, 1, 0.16)
                    : tap.hovered ? Qt.rgba(1, 1, 1, 0.07)
                                  : "transparent"
            }

            Image {
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                source: row.modelData.icon !== ""
                        ? "image://icon/" + row.modelData.icon : ""
            }

            Text {
                x: 46
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.name
                color: "white"
                font.family: "Inter"
                font.pixelSize: 14
            }

            TapHandler {
                id: tap
                cursorShape: Qt.PointingHandCursor
                onTapped: root.launch(row.index)
            }
        }
    }
}