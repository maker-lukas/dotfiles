import QtQuick
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: panel

    required property var barWindow
    property color barColor: barWindow.color

    property real cardWidth: 420
    property real cardHeight: 380
    property real leftGutter: 120
    property real edgeOverhang: 16

    property real r: 16
    property real bigR: 50
    property real kStart: 50
    property real leanMax: 0
    property real springK: 250
    property real springC: 24
    property real timeScale: 1
    property real filletEase: 2
    property real bottomFinish: 1

    property bool open: false
    property real ext: rest
    property real vel: 0
    property bool animating: false
    property real closedAt: 0

    readonly property real rest: -(kStart + 2)
    readonly property real prog: Math.max(0, Math.min(1, ext / cardHeight))
    readonly property real neckTension: 1 - Math.pow(prog, filletEase)
    readonly property real bottomTension: 1 - ss(0, bottomFinish, prog)

    function ss(a, b, x) {
        const t = Math.max(0, Math.min(1, (x - a) / (b - a)))
        return t * t * (3 - 2 * t)
    }

    function toggle() {
        if (open) open = false
        else if (Date.now() - closedAt > 250) open = true
    }

    onOpenChanged: {
        animating = true
        if (!open)
            closedAt = Date.now()
    }

    FrameAnimation {
        running: panel.animating
        onTriggered: {
            const dt = Math.min(frameTime, 0.033) * panel.timeScale
            const target = panel.open ? panel.cardHeight : panel.rest - 40

            panel.vel += (panel.springK * (target - panel.ext) - panel.springC * panel.vel) * dt
            panel.ext += panel.vel * dt

            if (panel.open && Math.abs(panel.vel) < 0.5 && Math.abs(panel.ext - panel.cardHeight) < 0.2) {
                panel.ext = panel.cardHeight
                panel.vel = 0
                panel.animating = false
            } else if (!panel.open && panel.ext <= panel.rest) {
                panel.ext = panel.rest
                panel.vel = 0
                panel.animating = false
            }
        }
    }

    visible: open || ext > rest + 1
    anchor.window: barWindow
    anchor.adjustment: PopupAdjustment.None
    anchor.rect.x: barWindow.width - width
    anchor.rect.y: barWindow.height - 1
    implicitWidth: leftGutter + cardWidth
    implicitHeight: cardHeight * 1.25
    color: "transparent"

    mask: Region {
        x: panel.leftGutter
        y: 0
        width: panel.cardWidth
        height: Math.max(0, panel.ext)
    }

    ShaderEffect {
        anchors.fill: parent

        property vector2d size: Qt.vector2d(width, height)
        property color color: panel.barColor
        property real cx: panel.leftGutter + (panel.cardWidth + panel.edgeOverhang) / 2
        property real ext: panel.ext
        property real boxW: panel.cardWidth + panel.edgeOverhang
        property real radius: panel.r + (panel.bigR - panel.r) * panel.bottomTension
        property real k: panel.r + (panel.kStart - panel.r) * panel.neckTension
        property real lean: panel.leanMax * panel.neckTension

        fragmentShader: Qt.resolvedUrl("shaders/liquid.frag.qsb")
    }

    Item {
        x: panel.leftGutter
        y: 0
        width: panel.cardWidth
        height: Math.max(0, panel.ext)
        clip: true
        opacity: Math.max(0, Math.min(1, (panel.prog - 0.55) * 2.5))

        FocusScope {
            width: panel.cardWidth
            height: panel.cardHeight
            focus: true

            Keys.onPressed: event => {
                if (event.key !== Qt.Key_Escape) return
                panel.open = false
                event.accepted = true
            }

            Item {
                id: content
                anchors.fill: parent
                anchors.margins: 20
            }
        }
    }

    HyprlandFocusGrab {
        windows: [panel]
        active: panel.open
        onCleared: panel.open = false
    }
}
