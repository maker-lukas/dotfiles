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

    component WorkspaceSwitcher: Item {
        id: switcher

        property color dotColor: "white"
        property int dotSize: 8
        property int dotSpacing: 5
        property int pillPadding: 3
        property int panelHeight: 30
        property int sidePadding: 18
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

        Rectangle {
            anchors {
                fill: parent
                margins: switcher.pillPadding
            }
            radius: 999
            color: switcher.hovered ? Qt.rgba(1, 1, 1, 0.17) : "transparent"
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
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

    // clock
    Item {
        id: clockArea
        anchors.centerIn: parent
        width: clockText.implicitWidth + 24
        height: parent.height

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
    }

    PopupWindow {
        id: popup

        property real r: 16
        property real cardWidth: 300
        property real cardHeight: 340
        property bool open: false

        // two springs with different feel -> liquid lag
        property real hProg: open ? 1 : 0
        Behavior on hProg {
            NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
        }

        // derived geometry
        readonly property real cx: width / 2
        readonly property real w: cardWidth
        readonly property real h: Math.max(0, cardHeight * hProg)
        readonly property real stretch: Math.max(-0.5, Math.min(1, hProg - wProg))
        readonly property real fr: Math.max(0, Math.min(h / 2, r * Math.min(hProg, 1)))
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

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: bar.color
                strokeColor: "transparent"

                // start at the top-left, where the left fillet meets the bar
                startX: popup.cx - popup.w / 2 - popup.fr
                startY: 0

                // along the bar edge
                PathLine { x: popup.cx + popup.w / 2 + popup.fr; y: 0 }

                // right fillet (concave)
                PathArc {
                    x: popup.cx + popup.w / 2; y: popup.fr
                    radiusX: popup.fr; radiusY: popup.fr
                    direction: PathArc.Counterclockwise
                }

                // right side down
                PathLine { x: popup.cx + popup.w / 2; y: popup.h - popup.br }

                // bottom-right corner
                PathArc {
                    x: popup.cx + popup.w / 2 - popup.br; y: popup.h
                    radiusX: popup.br; radiusY: popup.br
                    direction: PathArc.Clockwise
                }

                // bottom edge
                PathLine { x: popup.cx - popup.w / 2 + popup.br; y: popup.h }

                // bottom-left corner
                PathArc {
                    x: popup.cx - popup.w / 2; y: popup.h - popup.br
                    radiusX: popup.br; radiusY: popup.br
                    direction: PathArc.Clockwise
                }

                // left side up
                PathLine { x: popup.cx - popup.w / 2; y: popup.fr }

                // left fillet (concave), back to the start
                PathArc {
                    x: popup.cx - popup.w / 2 - popup.fr; y: 0
                    radiusX: popup.fr; radiusY: popup.fr
                    direction: PathArc.Counterclockwise
                }
            }
        }

        // content: fixed size, fades in once the shape is mostly open
        Item {
            x: popup.cx - popup.cardWidth / 2
            y: 0
            width: popup.cardWidth
            height: popup.cardHeight
            opacity: Math.max(0, Math.min(1, (popup.hProg - 0.55) * 2.5))

            Text {
                anchors.centerIn: parent
                text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                color: "white"
                font.pixelSize: 16
                font.family: "Inter"
            }
        }
    }

    // click outside to close
    HyprlandFocusGrab {
        windows: [popup]
        active: popup.open
        onCleared: popup.open = false
    }
}
