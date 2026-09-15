pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland

ShellRoot {
    id: root
    readonly property color paper: "#e8e1d5"
    readonly property color ink: "#20221f"
    readonly property color inkDim: "#66665f"
    readonly property color line: "#8b887f"
    readonly property color red: "#b74c3d"
    property bool sidebarOpen: false
    readonly property var battery: UPower.displayDevice
    readonly property int batteryPercent: battery ? Math.round(battery.percentage * 100) : 0
    SystemClock { id: clock; precision: SystemClock.Minutes }

    GlobalShortcut {
        appid: "bazzite-ryoku"
        name: "quicksettings"
        description: "Toggle the Bazzite Ryoku control sidebar"
        onPressed: root.sidebarOpen = !root.sidebarOpen
    }

    Variants {
        model: Quickshell.screens
        Scope {
            id: perScreen
            required property var modelData

            PanelWindow {
                screen: perScreen.modelData
                anchors { top: true; left: true; right: true }
                implicitHeight: 34
                color: root.ink
                WlrLayershell.namespace: "bazzite-ryoku-top"
                WlrLayershell.layer: WlrLayer.Top
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.line }
                Row {
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 7
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "力"; color: root.red; font.pixelSize: 15 }
                    Repeater {
                        model: 10
                        Rectangle {
                            id: topWorkspace
                            required property int index
                            width: 22; height: 22; radius: 3
                            readonly property bool active: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === index + 1
                            color: active ? root.paper : "transparent"
                            Text { anchors.centerIn: parent; text: topWorkspace.index === 9 ? "0" : String(topWorkspace.index + 1); color: topWorkspace.active ? root.ink : root.paper; opacity: topWorkspace.active ? 1 : 0.55; font.family: "monospace"; font.pixelSize: 9 }
                            TapHandler { onTapped: Hyprland.dispatch("workspace " + (topWorkspace.index + 1)) }
                        }
                    }
                }
                Text { anchors.centerIn: parent; width: 440; horizontalAlignment: Text.AlignHCenter; text: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : "RYOKU / BAZZITE"; color: root.paper; opacity: 0.72; font.family: "monospace"; font.pixelSize: 10; elide: Text.ElideRight }
                Row {
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 11
                    Text { text: "NET"; color: root.paper; opacity: 0.62; font.family: "monospace"; font.pixelSize: 9 }
                    Text { text: "VOL"; color: root.paper; opacity: 0.62; font.family: "monospace"; font.pixelSize: 9 }
                    Text { text: root.battery ? (root.batteryPercent + "%") : "AC"; color: root.paper; opacity: 0.82; font.family: "monospace"; font.pixelSize: 9 }
                    Rectangle { width: 1; height: 15; color: root.line }
                    Text { text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm").toUpperCase(); color: root.paper; font.family: "monospace"; font.bold: true; font.pixelSize: 10 }
                    Rectangle { width: 22; height: 22; radius: 3; color: root.red; Text { anchors.centerIn: parent; text: "≡"; color: root.paper; font.pixelSize: 13 } TapHandler { onTapped: root.sidebarOpen = !root.sidebarOpen } }
                }
            }

            PanelWindow {
                id: sidebar
                screen: perScreen.modelData
                anchors {
                    top: true
                    bottom: true
                    right: true
                }
                implicitWidth: root.sidebarOpen ? 390 : 0
                visible: implicitWidth > 0
                color: root.paper
                exclusiveZone: 0
                WlrLayershell.namespace: "bazzite-ryoku-sidebar"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: root.sidebarOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                Behavior on implicitWidth {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }

                Rectangle { anchors.left: parent.left; width: 1; height: parent.height; color: root.ink }

                Column {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 28
                    }
                    spacing: 20

                    Row {
                        width: parent.width
                        Text { text: "力"; color: root.red; font.pixelSize: 32 }
                        Item { width: parent.width - 76; height: 1 }
                        Text { text: "×"; color: root.ink; font.pixelSize: 24; TapHandler { onTapped: root.sidebarOpen = false } }
                    }

                    Text { text: Qt.formatDateTime(clock.date, "HH:mm"); color: root.ink; font.family: "monospace"; font.pixelSize: 56; font.weight: Font.Light }
                    Text { text: Qt.formatDateTime(clock.date, "dddd, d MMMM").toUpperCase(); color: root.inkDim; font.family: "monospace"; font.letterSpacing: 2; font.pixelSize: 11 }
                    Rectangle { width: parent.width; height: 1; color: root.line }

                    Text { text: "SYSTEM"; color: root.inkDim; font.family: "monospace"; font.letterSpacing: 3; font.pixelSize: 10 }
                    Grid {
                        columns: 2
                        spacing: 10
                        Repeater {
                            model: [
                                { mark: "◉", label: "NETWORK", command: "nm-connection-editor" },
                                { mark: "♪", label: "AUDIO", command: "pavucontrol" },
                                { mark: "☼", label: "DISPLAY", command: "systemsettings kcm_kscreen" },
                                { mark: "◫", label: "NOTIFICATIONS", command: "swaync-client -t -sw" }
                            ]
                            Rectangle {
                                id: tile
                                required property var modelData
                                width: 162; height: 82; radius: 3
                                color: tileHover.hovered ? root.ink : "transparent"
                                border.width: 1; border.color: root.line
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text { anchors { left: parent.left; top: parent.top; margins: 12 } text: tile.modelData.mark; color: tileHover.hovered ? root.paper : root.red; font.pixelSize: 20 }
                                Text { anchors { left: parent.left; bottom: parent.bottom; margins: 12 } text: tile.modelData.label; color: tileHover.hovered ? root.paper : root.ink; font.family: "monospace"; font.pixelSize: 9; font.letterSpacing: 1 }
                                HoverHandler { id: tileHover }
                                TapHandler { onTapped: Quickshell.execDetached(["sh", "-lc", tile.modelData.command]) }
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: root.line }
                    Text { text: root.battery ? ("BATTERY  " + root.batteryPercent + "%") : "POWER  AC"; color: root.ink; font.family: "monospace"; font.pixelSize: 12 }
                    Rectangle {
                        width: parent.width; height: 6; color: "#c6bfb3"
                        Rectangle { width: parent.width * (root.battery ? root.battery.percentage : 1); height: parent.height; color: root.batteryPercent <= 20 ? root.red : root.ink }
                    }

                    Text { text: "SESSION"; color: root.inkDim; font.family: "monospace"; font.letterSpacing: 3; font.pixelSize: 10 }
                    Row {
                        spacing: 10
                        Repeater {
                            model: [
                                { label: "LOCK", command: "hyprlock" },
                                { label: "POWER", command: "hyprshutdown" }
                            ]
                            Rectangle {
                                id: sessionButton
                                required property var modelData
                                width: 162; height: 42; radius: 3; color: root.ink
                                Text { anchors.centerIn: parent; text: sessionButton.modelData.label; color: root.paper; font.family: "monospace"; font.letterSpacing: 2; font.pixelSize: 10 }
                                TapHandler { onTapped: Quickshell.execDetached(["sh", "-lc", sessionButton.modelData.command]) }
                            }
                        }
                    }
                }
            }
        }
    }
}
