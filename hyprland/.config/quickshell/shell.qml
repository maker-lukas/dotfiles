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

    Desktops {
        anchors {
            left: parent.left
            leftMargin: 0
            verticalCenter: parent.verticalCenter
        }
        pillPadding: bar.pillPadding
        sidePadding: bar.pillSidePadding
        panelHeight: bar.implicitHeight
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

    Item {
        id: hotZone
        width: 260
        height: bar.height
        anchors.horizontalCenter: parent.horizontalCenter

        HoverHandler {
            onHoveredChanged: popup.hot = hovered
            onPointChanged: popup.hotX = point.scenePosition.x
        }
    }

    PopupWindow {
        id: popup

        property real r: 16
        property real cardWidth: 650
        property real cardHeight: 500
        property real bulgeMax: 22
        property real bulgeWidth: 110
        property real dwell: 0.35
        property real kStrain: 70
        property real kOpen: r * 1.2
        property real springK: 300
        property real springC: 26


        property bool hot: false
        property real hotX: bar.width / 2

        property bool open: false
        property real pressure: 0
        property real ext: 0
        property real vel: 0
        property bool armed: true
        readonly property real prog: Math.min(1, ext / cardHeight)

        onHotChanged: if (!hot) armed = true

        function ss(a, b, x) {
            const t = Math.max(0, Math.min(1, (x - a) / (b - a)))
            return t * t * (3 - 2 * t)
        }

        onOpenChanged: {
            if (!open) {
                pressure = 0
                armed = false
                rearmTimer.restart()
                searchBar.query = ""
                return
            }
            results.selected = 0
            Qt.callLater(() => searchBar.textInput.forceActiveFocus())
        }

        Timer {
            id: rearmTimer
            interval: 300
            onTriggered: popup.armed = !popup.hot
        }

        Timer { id: closeTimer; interval: 180; onTriggered: popup.open = false }

        FrameAnimation {
            running: popup.hot || popup.pressure > 0 || popup.ext > 0.5 || popup.open
            onTriggered: {
                const dt = Math.min(frameTime, 0.033)

                if (!popup.open) {
                popup.pressure = (popup.hot && popup.armed)
                    ? Math.min(1, popup.pressure + dt / popup.dwell)
                    : Math.max(0, popup.pressure - dt / 0.2)
                    if (popup.pressure >= 1) popup.open = true
                }

                const target = popup.open
                    ? popup.cardHeight
                    : popup.bulgeMax * Math.pow(popup.pressure, 0.6)

                popup.vel += (popup.springK * (target - popup.ext) - popup.springC * popup.vel) * dt
                popup.ext += popup.vel * dt

                if (popup.ext < 0) { popup.ext = 0; popup.vel = 0 }
                if (!popup.open && popup.pressure === 0 && popup.ext < 0.5) {
                    popup.ext = 0; popup.vel = 0
                }
            }
        }

        visible: open || ext > 0.5
        anchor.window: bar
        anchor.rect.x: bar.width / 2 - width / 2
        anchor.rect.y: bar.height - 1
        implicitWidth: cardWidth + 140
        implicitHeight: cardHeight * 1.25
        color: "transparent"
        mask: Region { item: card }

        ShaderEffect {
            anchors.fill: parent

            // blob follows the mouse while straining, then slides to center
            readonly property real mouseX: popup.hotX - (bar.width / 2 - popup.width / 2)
            readonly property real clampedMouse: Math.max(popup.bulgeWidth, Math.min(popup.width - popup.bulgeWidth, mouseX))

            property vector2d size: Qt.vector2d(width, height)
            property color color: bar.color
            property real cx: clampedMouse + (popup.width / 2 - clampedMouse) * popup.ss(0.03, 0.5, popup.prog)
            property real ext: popup.ext
            property real boxW: popup.bulgeWidth + (popup.cardWidth - popup.bulgeWidth) * popup.ss(0.06, 0.6, popup.prog)
            property real radius: popup.r
            property real k: {
                const tension = 1 - popup.ss(0, 0.5, popup.prog)
                const base = popup.kOpen + (popup.kStrain - popup.kOpen) * tension
                const speed = Math.min(1, Math.abs(popup.vel) / 2500)
                return base * (1 - 0.25 * speed) * Math.min(1, popup.ext / 8)
            }

            fragmentShader: Qt.resolvedUrl("shaders/liquid.frag.qsb")
        }

        Item {
            id: card
            x: popup.width / 2 - popup.cardWidth / 2
            y: 0
            width: popup.cardWidth
            height: popup.ext
            clip: true
            opacity: Math.max(0, Math.min(1, (popup.prog - 0.55) * 2.5))

            HoverHandler {
                id: cardHover
                onHoveredChanged: {
                    if (hovered) cloteTimer.stop()
                    else if (popup.open) closeTimer.start()
                }
                }

            FocusScope {
                width: popup.cardWidth
                height: popup.cardHeight
                focus: true
                Keys.onPressed: event => {
                    if (event.key !== Qt.Key_Escape) return
                    popup.open = false
                    event.accepted = true
                }

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

