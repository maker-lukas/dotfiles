import QtQuick
import Quickshell.Hyprland

Item {
    id: switcher

    property color dotColor: "white"
    property int dotSize: 8
    property int dotSpacing: 5
    property int panelHeight: 30
    property int pillPadding: 3
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
                radius: 999
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
