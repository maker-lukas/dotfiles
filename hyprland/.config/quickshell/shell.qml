import QtQuick
import Quickshell
import Quickshell.Hyprland
import QtQuick.Shapes

PanelWindow {
    id: bar
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 30
    color: "#000000"

    readonly property int pillPadding: 3
    readonly property int pillSidePadding: 18

    component HoverPill: Rectangle {
        id: pill

        property bool hovered: false

        anchors {
            fill: parent
            margins: bar.pillPadding
        }
        radius: 999
        color: pill.hovered ? Qt.rgba(1, 1, 1, 0.17) : "transparent"
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    component AppSearchBar: Rectangle {
        id: searchBar

        property alias textInput: searchField
        property alias query: searchField.text

        signal up()
        signal down()
        signal activate()

        radius: 12
        color: Qt.rgba(1, 1, 1, 0.08)

        Text {
            anchors.fill: searchField
            anchors.leftMargin: 16
            anchors.rightMargin: 16
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

            Keys.onUpPressed: {
                searchBar.up()
                event.accepted = true
            }
            Keys.onDownPressed: {
                searchBar.down()
                event.accepted = true
            }
            Keys.onReturnPressed: {
                searchBar.activate()
                event.accepted = true
            }
            Keys.onEscapePressed: {
                popup.open = false
                event.accepted = true
            }
        }
    }

    component AppResults: Item {
        id: results

        property string query: ""
        property int selected: 0
        property int maxResults: 50

        readonly property var apps: {
            const q = results.query.trim().toLowerCase()
            const all = DesktopEntries.applications.values
            const matches = q === ""
                ? all
                : all.filter(app =>
                    app.name.toLowerCase().includes(q) ||
                    (app.genericName || "").toLowerCase().includes(q) ||
                    (app.comment || "").toLowerCase().includes(q) ||
                    app.id.toLowerCase().includes(q))

            return matches.slice(0, results.maxResults)
        }

        function moveUp() {
            if (results.query.trim() === "")
                return
            results.selected = Math.max(0, results.selected - 1)
        }

        function moveDown() {
            if (results.query.trim() === "")
                return
            results.selected = Math.min(
                Math.max(0, results.apps.length - 1), results.selected + 1)
        }

        function launch(index) {
            if (results.query.trim() === "")
                return
            const app = results.apps[index]
            if (!app)
                return
            app.execute()
            popup.open = false
        }

        function activate() {
            results.launch(results.selected)
        }

        onQueryChanged: results.selected = 0
        onAppsChanged: results.selected = Math.min(
            results.selected, Math.max(0, results.apps.length - 1))

        ListView {
            id: list
            anchors.fill: parent
            clip: true
            model: results.apps
            currentIndex: results.selected
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
                    color: row.index === results.selected
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
                    onTapped: results.launch(row.index)
                }
            }
        }
    }

    component WorkspaceSwitcher: Item {
        id: switcher

        property color dotColor: "white"
        property int dotSize: 8
        property int dotSpacing: 5
        property int panelHeight: 30
        property int sidePadding: bar.pillSidePadding
        property int duration: 250
        property int scrollTimeout: 150
        property bool canScroll: true
        property bool hovered: false

        Timer {
            id: scrollCooldown
            interval: switcher.scrollTimeout
            repeat: false
            onTriggered: switcher.canScroll = true
        }

        property var occupiedIds: {
            const ids = []
            for (const toplevel of Hyprland.toplevels.values) {
                const ws = toplevel.workspace
                if (ws !== null && ws.id > 0 && !ids.includes(ws.id))
                    ids.push(ws.id)
            }
            ids.sort((a, b) => a - b)
            return ids
        }

        property int lastOccupied: switcher.occupiedIds.length > 0
                                   ? switcher.occupiedIds[switcher.occupiedIds.length - 1]
                                   : 1


        property var workspaceIds: {
            const ids = switcher.occupiedIds.slice()
            const trailing = switcher.lastOccupied + 1
            if (!ids.includes(trailing))
                ids.push(trailing)
            const focused = Hyprland.focusedWorkspace !== null
                            ? Hyprland.focusedWorkspace.id : 0
            if (focused > 0 && !ids.includes(focused))
                ids.push(focused)
            if (ids.length === 1)
                ids.push(ids[0] === 1 ? 2 : 1)
            ids.sort((a, b) => a - b)
            return ids
        }

        property int workspaceCount: switcher.workspaceIds.length

        function adjacentWorkspaceId(current, step) {
            const ids = switcher.workspaceIds
            if (step > 0) {
                for (const id of ids)
                    if (id > current)
                        return id
                return ids[ids.length - 1]
            }
            for (let i = ids.length - 1; i >= 0; i--)
                if (ids[i] < current)
                    return ids[i]
            return ids[0]
        }

        property real widthMultiplier: switcher.workspaceCount <= 2 ? 3.625
                                     : switcher.workspaceCount <= 5 ? 3.25
                                     : 2.75

        implicitWidth: dotsRow.implicitWidth + switcher.sidePadding * 2
        implicitHeight: switcher.panelHeight

        HoverPill {
            hovered: switcher.hovered
        }

        Row {
            id: dotsRow
            x: switcher.sidePadding
            y: (switcher.panelHeight - switcher.dotSize) / 2
            spacing: switcher.dotSpacing

            Repeater {
                model: switcher.workspaceIds

                Rectangle {
                    id: dot
                    required property int modelData

                    width: switcher.dotSize * (1 + (switcher.widthMultiplier - 1) * dot.expansion)
                    height: switcher.dotSize
                    radius: 999                   // GNOME: border-radius: 999px
                    color: switcher.dotColor

                    property bool isActive: Hyprland.focusedWorkspace !== null
                                            && Hyprland.focusedWorkspace.id === dot.modelData

                    property real expansion: dot.isActive ? 1 : 0
                    property real targetScale: dot.isActive ? 1 : 0.75

                    opacity: 0.5 + 0.5 * dot.expansion
                    scale: dot.targetScale

                    Behavior on width {
                        NumberAnimation {
                            duration: switcher.duration
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: switcher.duration
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                    }

                    Component.onCompleted: {
                        scale = 0
                        scale = Qt.binding(() => dot.targetScale)
                    }

                    TapHandler {
                        cursorShape: Qt.PointingHandCursor
                        onTapped: Hyprland.dispatch('hl.dsp.focus({ workspace = "' + dot.modelData + '" })')
                    }
                }
            }
        }

        HoverHandler {
            id: hoverHandler
            onHoveredChanged: switcher.hovered = hoverHandler.hovered
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                if (event.angleDelta.y === 0)
                    return

                if (!switcher.canScroll) {
                    event.accepted = true
                    return
                }

                const current = Hyprland.focusedWorkspace !== null
                                ? Hyprland.focusedWorkspace.id : 1
                const step = event.angleDelta.y < 0 ? 1 : -1
                const target = switcher.adjacentWorkspaceId(current, step)
                Hyprland.dispatch('hl.dsp.focus({ workspace = "' + target + '" })')
                event.accepted = true

                switcher.canScroll = false
                scrollCooldown.restart()
            }
        }
    }

    WorkspaceSwitcher {
        anchors {
            left: parent.left
            leftMargin: 0
            verticalCenter: parent.verticalCenter
        }
    }

    Item {
        id: clockArea
        anchors.centerIn: parent
        width: clockText.implicitWidth + bar.pillSidePadding * 2
        height: parent.height

        property bool hovered: false

        HoverPill {
            hovered: clockArea.hovered
        }

        Text {
            id: clockText
            anchors.centerIn: parent

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            text: Qt.formatDateTime(clock.date, "MMM d    h:mm AP")
            color: "white"
            font.pixelSize: 14
            font.family: "Inter"
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: popup.open = !popup.open
        }

        HoverHandler {
            id: clockHoverHandler
            onHoveredChanged: clockArea.hovered = clockHoverHandler.hovered
        }
    }

    PopupWindow {
        id: popup

        property real r: 16
        property real cardWidth: 650
        property real cardHeight: 500
        property bool open: false

        onOpenChanged: {
            if (!popup.open) {
                searchBar.query = ""
                return
            }
            results.selected = 0
            Qt.callLater(() => searchBar.textInput.forceActiveFocus())
        }

        property real hProg: open ? 1 : 0
        Behavior on hProg {
            NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
        }

        readonly property real cx: width / 2
        readonly property real w: cardWidth
        readonly property real h: Math.max(0, cardHeight * hProg)
        readonly property real fr: Math.max(0, Math.min(h / 2, r))
        readonly property real br: Math.max(0, Math.min(w / 2, h / 2,
                                r + (1 - Math.min(hProg, 1)) * r * 1.5))

        visible: open || h > 0.5
        anchor.window: bar
        anchor.rect.x: bar.width / 2 - width / 2
        anchor.rect.y: bar.height - 1
        // extra room so the overshoot never gets clipped
        implicitWidth: cardWidth + 140
        implicitHeight: cardHeight * 1.25
        color: "transparent"

        FocusScope {
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                if (event.key !== Qt.Key_Escape)
                    return

                popup.open = false
                event.accepted = true
            }
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: bar.color
                strokeColor: "transparent"
                startX: popup.cx - popup.w / 2 - popup.fr
                startY: 0

                PathLine { x: popup.cx + popup.w / 2 + popup.fr; y: 0 }

                PathArc {
                    x: popup.cx + popup.w / 2; y: popup.fr
                    radiusX: popup.fr; radiusY: popup.fr
                    direction: PathArc.Counterclockwise
                }

                PathLine { x: popup.cx + popup.w / 2; y: popup.h - popup.br }

                PathArc {
                    x: popup.cx + popup.w / 2 - popup.br; y: popup.h
                    radiusX: popup.br; radiusY: popup.br
                    direction: PathArc.Clockwise
                }

                PathLine { x: popup.cx - popup.w / 2 + popup.br; y: popup.h }

                PathArc {
                    x: popup.cx - popup.w / 2; y: popup.h - popup.br
                    radiusX: popup.br; radiusY: popup.br
                    direction: PathArc.Clockwise
                }

                PathLine { x: popup.cx - popup.w / 2; y: popup.fr }

                PathArc {
                    x: popup.cx - popup.w / 2 - popup.fr; y: 0
                    radiusX: popup.fr; radiusY: popup.fr
                    direction: PathArc.Counterclockwise
                }
            }
        }

        Item {
            x: popup.cx - popup.cardWidth / 2
            y: 0
            width: popup.cardWidth
            height: popup.cardHeight
            opacity: Math.max(0, Math.min(1, (popup.hProg - 0.55) * 2.5))
            clip: true

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                AppSearchBar {
                    id: searchBar
                    width: parent.width
                    height: 48

                    onUp: results.moveUp()
                    onDown: results.moveDown()
                    onActivate: results.activate()
                }

                Item {
                    width: parent.width
                    height: parent.height - searchBar.height - parent.spacing

                    Item {
                        id: widgetArea
                        anchors.fill: parent
                        visible: searchBar.query.trim() === ""

                        Text {
                            anchors.centerIn: parent
                            text: "Widgets go here"
                            color: Qt.rgba(1, 1, 1, 0.35)
                            font.family: "Inter"
                            font.pixelSize: 14
                        }
                    }

                    AppResults {
                        id: results
                        anchors.fill: parent
                        visible: !widgetArea.visible
                        query: searchBar.query
                    }
                }
            }
        }
    }

    HyprlandFocusGrab {
        windows: [popup]
        active: popup.open
        onCleared: popup.open = false
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "togglePopup"
        onPressed: popup.open = !popup.open
    }
}

