import QtQuick
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: panel

    required property var barWindow
    required property var notifications

    property color barColor: barWindow.color
    property real cardWidth: 650
    property real maxHeight: 320

    property real r: 16
    property real bigR: 50
    property real kStart: 50
    property real filletEase: 2
    property real bottomFinish: 1
    property real filletSpeed: 8

    property real springK: 250
    property real springC: 24
    property real timeScale: 1

    property bool open: notifications.popups.count > 0
    property real ext: rest
    property real vel: 0
    property real filletProg: 0
    property bool animating: false

    readonly property real rest: -(kStart + 2)

    readonly property real neckTension: 1 - Math.pow(filletProg, filletEase)
    readonly property real bottomTension: 1 - ss(0, bottomFinish, filletProg)
    readonly property real currentRadius: r + (bigR - r) * bottomTension
    readonly property real currentK: r + (kStart - r) * neckTension

    function ss(a, b, x) {
        const t = Math.max(0, Math.min(1, (x - a) / (b - a)))
        return t * t * (3 - 2 * t)
    }

    onOpenChanged: animating = true

    Connections {
        target: notifications.popups
        function onCountChanged() {
            panel.animating = true
        }
    }

    FrameAnimation {
        running: panel.animating
        onTriggered: {
            const dt = Math.min(frameTime, 0.033) * panel.timeScale
            const desired = panel.open
                ? Math.min(panel.maxHeight, column.implicitHeight + 4)
                : panel.rest - 40

            panel.vel += (panel.springK * (desired - panel.ext) - panel.springC * panel.vel) * dt
            panel.ext += panel.vel * dt

            const filletTarget = panel.open ? 1 : 0
            panel.filletProg += (filletTarget - panel.filletProg) * Math.min(1, panel.filletSpeed * dt)

            if (panel.open && Math.abs(panel.vel) < 0.5 && Math.abs(panel.ext - desired) < 0.2) {
                panel.ext = desired
                panel.vel = 0
                if (panel.filletProg > 0.99) {
                    panel.filletProg = 1
                    panel.animating = false
                }
            } else if (!panel.open && panel.ext <= panel.rest) {
                panel.ext = panel.rest
                panel.vel = 0
                if (panel.filletProg < 0.01) {
                    panel.filletProg = 0
                    panel.animating = false
                }
            }
        }
    }

    visible: open || ext > rest + 1
    anchor.window: barWindow
    anchor.rect.x: barWindow.width / 2 - width / 2
    anchor.rect.y: barWindow.height - 1
    implicitWidth: cardWidth + 240
    implicitHeight: maxHeight * 1.25
    color: "transparent"

    mask: Region {
        x: (panel.width - panel.cardWidth) / 2
        y: 0
        width: panel.cardWidth
        height: Math.max(0, panel.ext)
    }

    ShaderEffect {
        id: shader
        anchors.fill: parent

        property vector2d size: Qt.vector2d(width, height)
        property color color: panel.barColor
        property real cx: panel.width / 2
        property real ext: panel.ext
        property real boxW: panel.cardWidth
        property real radius: panel.currentRadius
        property real k: panel.currentK
        property real lean: 0

        fragmentShader: Qt.resolvedUrl("shaders/liquid.frag.qsb")
    }

    Item {
        x: panel.width / 2 - panel.cardWidth / 2
        y: 0
        width: panel.cardWidth
        height: Math.max(0, panel.ext)
        clip: true
        opacity: Math.max(0, Math.min(1, panel.ext / 40))

        Column {
            id: column
            width: parent.width
            anchors.top: parent.top
            anchors.topMargin: 0
            spacing: 0

            Repeater {
                model: notifications.popups

                delegate: NotificationCard {
                    width: column.width
                    compact: true
                    showSeparator: index < notifications.popups.count - 1

                    notifKey: entryKey
                    notifApp: app
                    notifSummary: summary
                    notifBody: body
                    notifActionsJson: actionsJson

                    onCloseClicked: key => notifications.dismissPopup(key)
                    onClicked: key => notifications.invokeDefault(key)
                    onActionClicked: (key, identifier) => notifications.invokeAction(key, identifier)
                }
            }
        }
    }
}
