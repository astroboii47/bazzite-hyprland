pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

ShellRoot {
    id: root
    readonly property color paper: "#e8e1d5"
    readonly property color ink: "#20221f"
    readonly property color inkDim: "#66665f"
    readonly property color line: "#8b887f"
    readonly property color red: "#b74c3d"
    SystemClock { id: clock; precision: SystemClock.Minutes }

    Variants {
        model: Quickshell.screens
        Scope {
            id: perScreen
            required property var modelData

            PanelWindow {
                screen: perScreen.modelData
                anchors { top: true; left: true; right: true }
                implicitHeight: 46
                color: root.paper
                WlrLayershell.namespace: "bazzite-ryoku-top"
                WlrLayershell.layer: WlrLayer.Top
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.ink }
                Row {
                    anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                    spacing: 12
                    Rectangle { width: 22; height: 22; color: root.ink; Text { anchors.centerIn: parent; text: "緑"; color: root.paper; font.pixelSize: 13 } }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "RYOKU"; color: root.ink; font.family: "monospace"; font.bold: true; font.letterSpacing: 4; font.pixelSize: 12 }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 54; height: 1; color: root.line }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : "DESKTOP"; color: root.inkDim; font.family: "monospace"; font.pixelSize: 11; width: 420; elide: Text.ElideRight }
                }
                Row {
                    anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
                    spacing: 14
                    Text { text: "SUPER + K  KEYS"; color: root.inkDim; font.family: "monospace"; font.pixelSize: 10 }
                    Rectangle { width: 1; height: 18; color: root.line }
                    Text { text: Qt.formatDateTime(clock.date, "ddd  dd MMM   HH:mm").toUpperCase(); color: root.ink; font.family: "monospace"; font.bold: true; font.pixelSize: 11 }
                }
            }

            PanelWindow {
                screen: perScreen.modelData
                anchors { top: true; bottom: true; left: true }
                implicitWidth: 46
                color: root.paper
                WlrLayershell.namespace: "bazzite-ryoku-left"
                WlrLayershell.layer: WlrLayer.Top
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: root.ink }
                Column {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 72 }
                    spacing: 10
                    Repeater {
                        model: 10
                        Rectangle {
                            id: workspaceButton
                            required property int index
                            width: 28; height: 28; radius: 2
                            readonly property bool active: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === index + 1
                            color: active ? root.ink : "transparent"
                            border.width: active ? 0 : 1
                            border.color: root.line
                            Text { anchors.centerIn: parent; text: workspaceButton.index === 9 ? "0" : String(workspaceButton.index + 1); color: workspaceButton.active ? root.paper : root.inkDim; font.family: "monospace"; font.pixelSize: 10 }
                            TapHandler { onTapped: Hyprland.dispatch("workspace " + (workspaceButton.index + 1)) }
                        }
                    }
                }
                Text { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 66 }; rotation: -90; text: "BAZZITE  /  LATITUDE"; color: root.inkDim; font.family: "monospace"; font.letterSpacing: 3; font.pixelSize: 9 }
            }

            PanelWindow {
                screen: perScreen.modelData
                anchors { bottom: true; left: true; right: true }
                implicitHeight: 24
                color: root.ink
                WlrLayershell.namespace: "bazzite-ryoku-bottom"
                WlrLayershell.layer: WlrLayer.Top
                Text { anchors { left: parent.left; leftMargin: 62; verticalCenter: parent.verticalCenter }; text: "力  FLOW WITH INTENT"; color: root.paper; font.family: "monospace"; font.letterSpacing: 2; font.pixelSize: 9 }
                Rectangle { anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }; width: 7; height: 7; radius: 4; color: root.red }
            }
        }
    }
}
