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

        // ---------- feel knobs ----------
        property real r: 16               // final fillet / corner size
        property real cardWidth: 650
        property real cardHeight: 500
        property real bulgeMax: 22        // how far the surface swells before it breaks
        property real bulgeWidth: 110
        property real dwell: 0.35         // seconds of hovering to break through
        property real kStrain: 70         // fillet size while straining (big = very smooth)
        property real kOpen: r * 1.2      // fillet size when fully open
        property real springK: 300
        property real springC: 26         // lower = more wobble


        // ---------- inputs (set from the bar) ----------
        property bool hot: false
        property real hotX: bar.width / 2   // mouse x in bar coordinates

        // ---------- state ----------
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
            armed = !hot
            searchBar.query = ""
            return
        }
            results.selected = 0
            Qt.callLater(() => searchBar.textInput.forceActiveFocus())
        }

        // stay open while the mouse is in the hot zone or on the card
        readonly property bool held: hot || cardHover.hovered
        onHeldChanged: held ? closeTimer.stop() : (open ? closeTimer.start() : 0)
        Timer { id: closeTimer; interval: 180; onTriggered: popup.open = false }

        // ---------- physics ----------
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

        // ---------- window ----------
        visible: open || ext > 0.5
        anchor.window: bar
        anchor.rect.x: bar.width / 2 - width / 2
        anchor.rect.y: bar.height - 1
        implicitWidth: cardWidth + 140
        implicitHeight: cardHeight * 1.25      // room for overshoot
        color: "transparent"
        mask: Region { item: card }            // only the card area takes input

        // ---------- liquid ----------
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

        // ---------- content ----------
        Item {
            id: card
            x: popup.width / 2 - popup.cardWidth / 2
            y: 0
            width: popup.cardWidth
            height: popup.ext
            clip: true
            opacity: Math.max(0, Math.min(1, (popup.prog - 0.55) * 2.5))

            HoverHandler { id: cardHover }

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
        // Whitelist the bar too: with only the popup listed, activating the
        // grab blocks input to the hot zone, hot flips false, and a transient
        // clear then re-arms it into an open/close loop.
        windows: [popup, bar]
        active: popup.open
        // Ignore clears while the pointer is still on the bar/card — a
        // spurious compositor clear (e.g. toplevel activation) would close the
        // popup and make the hot zone reopen it over and over. Only a real
        // click away, with nothing held, should dismiss it.
        onCleared: if (!popup.held) popup.open = false
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "togglePopup"
        onPressed: popup.open = !popup.open
    }
}

