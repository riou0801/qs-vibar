//@ pragma UseQApplication
pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.I3
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.DBusMenu

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData

            anchors {
                top: true
                left: true
                right: true
            }

            screen: modelData

            implicitHeight: 36
            color: "transparent"

            // Catppuccin Mocha palette
            readonly property color ctpBase: "#1e1e2e"
            readonly property color ctpSurface0: "#313244"
            readonly property color ctpSurface1: "#45475a"
            readonly property color ctpOverlay0: "#6c7086"
            readonly property color ctpText: "#cdd6f4"
            readonly property color ctpSubtext1: "#bac2de"
            readonly property color ctpLavender: "#b4befe"
            readonly property color ctpRed: "#f38ba8"

            readonly property real phi: 1.618
            readonly property int baseFontSize: 14
            readonly property int barPadding: Math.round(baseFontSize / phi)
            readonly property int colPaddingX: Math.round(baseFontSize / phi)
            readonly property int colPaddingY: Math.round(baseFontSize / (phi * phi))
            readonly property int colRadius: 8
            readonly property int iconSize: Math.round(baseFontSize * phi)
            readonly property int colSpacing: Math.round(baseFontSize / (phi * phi))
            readonly property int trayClockGap: Math.round(baseFontSize / phi)

            readonly property string fontName: "NotoSans Nerd Font"

            property string dateText: ""
            property string timeText: ""
            function updateTime() {
                dateText = Qt.formatDateTime(new Date(), "yyyy/MM/dd");
                timeText = Qt.formatDateTime(new Date(), "HH:mm");
            }

            Component.onCompleted: updateTime()
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: root.updateTime()
            }
            Item {
                id: content
                anchors.fill: parent
                anchors.margins: root.barPadding

                // Left column: Workspaces
                Rectangle {
                    id: workspaceCol
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.ctpSurface0
                    radius: root.colRadius
                    border.width: 1
                    border.color: root.ctpOverlay0

                    implicitHeight: Math.max(root.iconSize, workspaceRow.implicitHeight) + (root.colPaddingY * 2)
                    implicitWidth: workspaceRow.implicitWidth + (root.colPaddingX * 2)

                    RowLayout {
                        id: workspaceRow
                        anchors.fill: parent
                        anchors.leftMargin: root.colPaddingX
                        anchors.rightMargin: root.colPaddingX
                        anchors.topMargin: root.colPaddingY
                        anchors.bottomMargin: root.colPaddingY
                        spacing: root.colSpacing

                        Repeater {
                            model: I3.workspaces

                            Rectangle {
                                id: wsItem
                                required property I3Workspace modelData

                                radius: 4
                                color: modelData.focused ? root.ctpLavender : modelData.active ? root.ctpSurface1 : "transparent"

                                border.width: modelData.urgent ? 1 : 0
                                border.color: modelData.urgent ? root.ctpRed : "transparent"

                                implicitHeight: 18
                                implicitWidth: 22

                                Text {
                                    anchors.centerIn: parent
                                    text: wsItem.modelData.name
                                    color: wsItem.modelData.focused ? root.ctpBase : root.ctpText
                                    font.family: root.fontName
                                    font.pixelSize: root.baseFontSize
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: wsItem.modelData.activate()
                                }
                            }
                        }
                    }
                }

                // Right column: System tray
                Rectangle {
                    id: trayCol
                    anchors.right: clockCol.left
                    anchors.rightMargin: root.trayClockGap
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.ctpSurface0
                    radius: root.colRadius
                    border.width: 1
                    border.color: root.ctpOverlay0

                    implicitHeight: Math.max(root.iconSize, trayRow.implicitHeight) + (root.colPaddingY * 2)
                    implicitWidth: trayRow.implicitWidth + (root.colPaddingX * 2)

                    RowLayout {
                        id: trayRow
                        anchors.fill: parent
                        anchors.leftMargin: root.colPaddingX
                        anchors.rightMargin: root.colPaddingX
                        anchors.topMargin: root.colPaddingY
                        anchors.bottomMargin: root.colPaddingY
                        spacing: root.colSpacing

                        Repeater {
                            model: SystemTray.items

                            Item {
                                id: trayItemRoot
                                required property SystemTrayItem modelData

                                width: root.iconSize
                                height: root.iconSize

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: root.iconSize
                                    source: trayItemRoot.modelData.icon
                                }

                                QsMenuAnchor {
                                    id: trayMenu
                                    menu: trayItemRoot.modelData.menu
                                    anchor.window: root
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                                    onClicked: function (mouse) {
                                        if (mouse.button === Qt.RightButton && trayItemRoot.modelData.hasMenu) {
                                            const pos = trayItemRoot.mapToItem(content, 0, 0);
                                            trayMenu.anchor.rect.x = pos.x;
                                            trayMenu.anchor.rect.y = pos.y + trayItemRoot.height;
                                            trayMenu.anchor.rect.width = trayItemRoot.width;
                                            trayMenu.anchor.rect.height = trayItemRoot.height;
                                            trayMenu.open();
                                        } else if (!trayItemRoot.modelData.onlyMenu) {
                                            trayItemRoot.modelData.activate();
                                        } else if (trayItemRoot.modelData.hasMenu) {
                                            const pos = trayItemRoot.mapToItem(content, 0, 0);
                                            trayMenu.anchor.rect.x = pos.x;
                                            trayMenu.anchor.rect.y = pos.y + trayItemRoot.height;
                                            trayMenu.anchor.rect.width = trayItemRoot.width;
                                            trayMenu.anchor.rect.height = trayItemRoot.height;
                                            trayMenu.open();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    id: clockCol
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.ctpSurface0
                    radius: root.colRadius
                    border.width: 1
                    border.color: root.ctpOverlay0

                    implicitHeight: Math.max(root.iconSize, clockRow.implicitHeight) + (root.colPaddingY * 2)
                    implicitWidth: clockRow.implicitWidth + (root.colPaddingX * 2)

                    RowLayout {
                        id: clockRow
                        anchors.fill: parent
                        anchors.leftMargin: root.colPaddingX
                        anchors.rightMargin: root.colPaddingX
                        anchors.topMargin: root.colPaddingY
                        anchors.bottomMargin: root.colPaddingY
                        spacing: root.colSpacing

                        Text {
                            color: root.ctpSubtext1
                            font.family: root.fontName
                            font.pixelSize: root.baseFontSize
                            text: ` ${root.dateText} 󰇙  ${root.timeText}`
                        }
                    }
                }
                // Center column: MPRIS (hidden when not playing)
                Rectangle {
                    id: mediaCol
                    anchors.centerIn: parent
                    color: root.ctpSurface0
                    radius: root.colRadius
                    border.width: 1
                    border.color: root.ctpOverlay0

                    property var activePlayer: {
                        const players = Mpris.players.values;
                        for (let i = 0; i < players.length; i++) {
                            if (players[i].isPlaying)
                                return players[i];
                        }
                        return players.length ? players[0] : null;
                    }

                    visible: !!activePlayer && activePlayer.isPlaying

                    readonly property string mediaTitle: activePlayer ? `${activePlayer.trackArtist || "Unknown Artist"} - ${activePlayer.trackTitle || "Unknown Title"}` : ""

                    readonly property string mediaStatusIcon: activePlayer ? (activePlayer.isPlaying ? "" : "") : ""

                    TextMetrics {
                        id: mediaTitleMetrics
                        text: mediaCol.mediaTitle
                        font.family: root.fontName
                        font.pixelSize: root.baseFontSize
                    }

                    TextMetrics {
                        id: mediaStatusMetrics
                        text: mediaCol.mediaStatusIcon
                        font.family: root.fontName
                        font.pixelSize: root.baseFontSize
                    }

                    implicitHeight: Math.max(mediaTitleMetrics.height, mediaStatusMetrics.height, root.iconSize) + (root.colPaddingY * 2)
                    readonly property int mediaMaxWidth: Math.round(root.width * 0.35)
                    implicitWidth: Math.min(mediaRow.implicitWidth + (root.colPaddingX * 2), mediaMaxWidth)

                    RowLayout {
                        id: mediaRow
                        anchors.fill: parent
                        anchors.leftMargin: root.colPaddingX
                        anchors.rightMargin: root.colPaddingX
                        anchors.topMargin: root.colPaddingY
                        anchors.bottomMargin: root.colPaddingY
                        spacing: root.colSpacing

                        Text {
                            color: root.ctpSubtext1
                            font.family: root.fontName
                            font.pixelSize: root.baseFontSize
                            text: mediaCol.mediaStatusIcon
                        }

                        Text {
                            Layout.fillWidth: true
                            color: root.ctpText
                            font.family: root.fontName
                            font.pixelSize: root.baseFontSize
                            elide: Text.ElideRight
                            text: mediaCol.mediaTitle
                        }
                    }
                }
            }
        }
    }
}
