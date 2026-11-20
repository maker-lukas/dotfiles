import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bar

    FileView {
        id: settingsFile
        path: Qt.resolvedUrl("workspaces.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: settings
            property int count: 4
        }
    }

    readonly property int wsCount: {
        let max = settings.count
        const focused = Hyprland.focusedWorkspace?.id ?? 1
        if (focused > max) max = focused
        for (const w of Hyprland.workspaces.values)
            if (w.id > max) max = w.id
        return Math.max(max, 1)
    }

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 34
    color: "#1a1b26"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Item {
        anchors.fill: parent

        MouseArea {
            id: wsScroll
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 10
            width: wsRow.implicitWidth

            onWheel: (wheel) => {
                const cur = Hyprland.focusedWorkspace?.id ?? 1
                const target = cur + (wheel.angleDelta.y < 0 ? 1 : -1)
                if (target < 1 || target > bar.wsCount) return
                Hyprland.dispatch('hl.dsp.focus({ workspace = ' + target + ' })')
            }

            Row {
                id: wsRow
                anchors.fill: parent
                spacing: 2

                Repeater {
                    model: bar.wsCount

                    delegate: Item {
                        id: wsItem
                        required property int index
                        readonly property int wsId: index + 1
                        readonly property bool active: Hyprland.focusedWorkspace?.id === wsId
                        readonly property real dotW: active ? 30 : 10
                        readonly property real dotH: active ? 12 : 10

                        width: dotW + 8
                        height: wsRow.height
                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors.centerIn: parent
                            width: wsItem.dotW
                            height: wsItem.dotH
                            radius: Math.min(width, height) / 2
                            color: wsItem.active ? "#7aa2f7" : "#565f89"
                            Behavior on width  { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Hyprland.dispatch('hl.dsp.focus({ workspace = ' + wsItem.wsId + ' })')
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "hh:mm AP")
            color: "#7aa2f7"
            font.pixelSize: 16
            font.bold: true
        }
    }
}
