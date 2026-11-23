import QtQuick
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: panel

    required property var barWindow
    property color barColor: barWindow.color

    property real cardWidth: 650
    property real cardHeight: 500
    property real r: 16
    property real bigR: 50
    property real kStart: 50
    property real leanMax: 0
    property real springK: 250
    property real springC: 24
    property real timeScale: 1 // 1.0 = normal; lower for slow-motion inspection
    property real filletEase: 2 // >1 holds the neck fillet large longer; raise it to slow the morph further
    property real bottomFinish: 1 // fraction of travel where the bottom corners reach their final radius
    property real filletSpeed: 8 // lower = fillet reaches its final shape slower; popup speed is unchanged
    property real filletProg: 0 // time-based follower of prog, drives both fillet curves

    property bool open: false
    property real ext: rest
    property real vel: 0
    property bool animating: false
    property real closedAt: 0

    readonly property real rest: -(kStart + 2)
    readonly property real prog: Math.max(0, Math.min(1,  ext / cardHeight))
    readonly property real neckTension: 1 - Math.pow(filletProg, filletEase) // neck lags the panel, so it changes slowly instead of flashing
    readonly property real bottomTension: 1 - ss(0, bottomFinish, filletProg)

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
        if (!open) {
            closedAt = Date.now()
            searchBar.query = ""
            return
        }
        results.selected = 0
        Qt.callLater(() => searchBar.textInput.forceActiveFocus())
    }

    FrameAnimation {
        running: panel.animating
        onTriggered: {
            const dt = Math.min(frameTime, 0.033) * panel.timeScale

            const target = panel.open ? panel.cardHeight : panel.rest - 40
            panel.vel += (panel.springK * (target - panel.ext) - panel.springC * panel.vel) * dt
            panel.ext += panel.vel * dt

            // fillet follows its own clock in both directions; popup spring is untouched
            panel.filletProg += (panel.prog - panel.filletProg) * Math.min(1, panel.filletSpeed * dt)

            if (panel.open && Math.abs(panel.vel) < 0.5 && Math.abs(panel.ext - panel.cardHeight) < 0.2) {
                panel.ext = panel.cardHeight
                panel.vel = 0
                if (panel.filletProg > 0.99) {
                    panel.filletProg = 1
                    panel.animating = false
                }
            } else if (!panel.open && panel.ext <= panel.rest) {
                panel.ext = panel.rest
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
    implicitHeight: cardHeight * 1.25
    color: "transparent"
    mask: Region {
        x: (panel.width - panel.cardWidth) / 2
        y: 0
        width: panel.cardWidth
        height: Math.max(0, panel.ext)
    }

    ShaderEffect {
        anchors.fill: parent

        property vector2d size: Qt.vector2d(width, height)
        property color color: panel.barColor
        property real cx: panel.width / 2
        property real ext: panel.ext
        property real boxW: panel.cardWidth // fixed width: no width animation during the morph
        property real radius: panel.r + (panel.bigR - panel.r) * panel.bottomTension
        property real k: panel.r + (panel.kStart - panel.r) * panel.neckTension
        property real lean: panel.leanMax * panel.neckTension

        fragmentShader: Qt.resolvedUrl("shaders/liquid.frag.qsb")
    }

    Item {
        x: panel.width / 2 - panel.cardWidth / 2
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
                    onEscaped: panel.open = false
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
                        onLaunched: panel.open = false
                    }
                }
            }
        }
    }

    HyprlandFocusGrab {
        windows: [panel]
        active: panel.open
        onCleared: panel.open = false
    }
}