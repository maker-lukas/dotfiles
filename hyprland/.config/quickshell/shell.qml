//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Networking
import Quickshell.Services.SystemTray

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

    DesktopSwitcher {
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
            onClicked: {
                quickPanel.open = false
                panel.toggle()
            }
        }

        HoverHandler {
            id: clockHoverHandler
            onHoveredChanged: clockArea.hovered = clockHoverHandler.hovered
        }
    }

    Item {
        id: statusArea
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        width: statusRow.implicitWidth + bar.pillSidePadding * 2
        height: parent.height

        property bool hovered: false

        HoverPill {
            hovered: statusArea.hovered
        }

        Row {
            id: statusRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: bar.pillSidePadding
            spacing: 8

            Image {
                width: 15
                height: 15
                anchors.verticalCenter: parent.verticalCenter
                source: statusArea.networkIcon
            }

            Image {
                width: 15
                height: 15
                anchors.verticalCenter: parent.verticalCenter
                source: statusArea.volumeIcon
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: statusArea.batteryText
                color: "white"
                font.family: "Inter"
                font.pixelSize: 12
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "▾"
                color: Qt.rgba(1, 1, 1, 0.65)
                font.family: "Inter"
                font.pixelSize: 10
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                panel.open = false
                quickPanel.toggle()
            }
        }

        HoverHandler {
            id: statusHoverHandler
            onHoveredChanged: statusArea.hovered = statusHoverHandler.hovered
        }
    }

    Item {
        id: trayArea
        anchors {
            right: statusArea.left
            rightMargin: 4
            verticalCenter: parent.verticalCenter
        }
        width: trayRow.implicitWidth
        height: parent.height

        Row {
            id: trayRow
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: 6

            Repeater {
                model: SystemTray.items

                delegate: Item {
                    id: trayDelegate
                    required property var modelData
                    width: 16
                    height: 16

                    Image {
                        anchors.fill: parent
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
                                if (modelData.hasMenu) {
                                    const p = trayDelegate.mapToItem(
                                        bar.contentItem,
                                        trayDelegate.width / 2,
                                        trayDelegate.height
                                    )
                                    trayMenu.show(modelData.menu, p.x)
                                }
                            } else {
                                modelData.activate()
                            }
                        }
                    }
                }
            }
        }
    }

    NotificationsService {
        id: notifications
    }

    LiquidPanel {
        id: panel
        barWindow: bar
    }

    LiquidNotifications {
        id: notificationPopup
        barWindow: bar
        notifications: notifications
    }

    QuickPanel {
        id: quickPanel
        barWindow: bar
    }

    TrayMenu {
        id: trayMenu
        barWindow: bar
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "togglePopup"
        onPressed: {
            quickPanel.open = false
            panel.toggle()
        }
    }
}
