import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    anchors {
        top: true
        left: true
        bottom: true
    }
    implicitWidth: 40
    color: "#1a1b26"

    Item {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onWheel: (wheel) => {
                const ids = Hyprland.workspaces.values
                    .map(w =>  w.id)
                    .sort((a, b) => a - b)
                
                const cur = Hyprland.focusedWorkspace?.id
                const i = ids.indexOf(cur)
                if (i == -1) return

                const next = i + (wheel.angleDelta.y < 0 ? 1 : -1)
                if (next < 0 || next >= ids.length) return

                Hyprland.dispatch('hl.dsp.focus({ workspace = ' + ids[next] +' })')
            }
        }

        ColumnLayout {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 10
            spacing: 1

            Repeater {
                model: Hyprland.workspaces.values

                delegate: Item {
                    required property HyprlandWorkspace modelData

                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 24
                    implicitHeight: 24

                    Rectangle {
                        anchors.centerIn: parent
                        width: modelData.active ? 10 : 8
                        height: modelData.active ? 20 : 8
                        radius: width / 2
                        color: modelData.active ? "#7aa2f7" : "#565f89"

                        Behavior on width {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }

                        Behavior on height {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: modelData.activate()
                    }
                }
            }
        }
    }
}