//@ pragma UseQApplication
pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.I3
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray

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
                onTriggered: updateTime()
            }
            Item {
                id: content
                anchors.fill: parent
                anchors.margins: barPadding

                // Left column: Workspaces
                Rectangle {
                    id: workspaceCol
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: ctpSurface0
                    radius: colRadius
                    border.width: 1
                    border.color: ctpOverlay0

                    implicitHeight: Math.max(iconSize, workspaceRow.implicitHeight) + (colPaddingY * 2)
                    implicitWidth: workspaceRow.implicitWidth + (colPaddingX * 2)

                    RowLayout {
                        id: workspaceRow
                        anchors.fill: parent
                        anchors.leftMargin: colPaddingX
                        anchors.rightMargin: colPaddingX
                        anchors.topMargin: colPaddingY
                        anchors.bottomMargin: colPaddingY
                        spacing: colSpacing

                        Repeater {
                            model: I3.workspaces

                            Rectangle {
                                id: wsItem
                                required property I3Workspace modelData

                                radius: 4
                                color: modelData.focused ? ctpLavender : modelData.active ? ctpSurface1 : "transparent"

                                border.width: modelData.urgent ? 1 : 0
                                border.color: modelData.urgent ? ctpRed : "transparent"

                                implicitHeight: 18
                                implicitWidth: 22

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    color: modelData.focused ? ctpBase : ctpText
                                    font.family: fontName
                                    font.pixelSize: baseFontSize
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
                    anchors.rightMargin: trayClockGap
                    anchors.verticalCenter: parent.verticalCenter
                    color: ctpSurface0
                    radius: colRadius
                    border.width: 1
                    border.color: ctpOverlay0

                    implicitHeight: Math.max(iconSize, trayRow.implicitHeight) + (colPaddingY * 2)
                    implicitWidth: trayRow.implicitWidth + (colPaddingX * 2)

                    RowLayout {
                        id: trayRow
                        anchors.fill: parent
                        anchors.leftMargin: colPaddingX
                        anchors.rightMargin: colPaddingX
                        anchors.topMargin: colPaddingY
                        anchors.bottomMargin: colPaddingY
                        spacing: colSpacing

                        Repeater {
                            model: SystemTray.items

                            Item {
                                id: trayItemRoot
                                required property SystemTrayItem modelData

                                width: iconSize
                                height: iconSize

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: iconSize
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
                    color: ctpSurface0
                    radius: colRadius
                    border.width: 1
                    border.color: ctpOverlay0

                    implicitHeight: Math.max(iconSize, clockRow.implicitHeight) + (colPaddingY * 2)
                    implicitWidth: clockRow.implicitWidth + (colPaddingX * 2)

                    RowLayout {
                        id: clockRow
                        anchors.fill: parent
                        anchors.leftMargin: colPaddingX
                        anchors.rightMargin: colPaddingX
                        anchors.topMargin: colPaddingY
                        anchors.bottomMargin: colPaddingY
                        spacing: colSpacing

                        Text {
                            color: ctpSubtext1
                            font.family: fontName
                            font.pixelSize: baseFontSize
                            text: ` ${root.dateText} 󰇙  ${root.timeText}`
                        }
                    }
                }
                // Center column: MPRIS (hidden when not playing)
                Rectangle {
                    id: mediaCol
                    anchors.centerIn: parent
                    color: ctpSurface0
                    radius: colRadius
                    border.width: 1
                    border.color: ctpOverlay0

                    property var activePlayer: {
                        const players = Mpris.players.values;
                        for (let i = 0; i < players.length; i++) {
                            if (players[i].isPlaying)
                                return players[i];
                        }
                        return players.length ? players[0] : null;
                    }

                    visible: !!activePlayer

                    readonly property string mediaTitle: activePlayer ? `${activePlayer.trackArtist || "Unknown Artist"} - ${activePlayer.trackTitle || "Unknown Title"}` : ""

                    readonly property string mediaStatusIcon: activePlayer ? (activePlayer.isPlaying ? "" : "") : ""

                    readonly property int availableWidth: Math.max(0, parent.width - workspaceCol.width - trayCol.width - (colPaddingX * 2) - 24)

                    TextMetrics {
                        id: mediaTitleMetrics
                        text: mediaCol.mediaTitle
                        font.family: fontName
                        font.pixelSize: baseFontSize
                    }

                    TextMetrics {
                        id: mediaStatusMetrics
                        text: mediaCol.mediaStatusIcon
                        font.family: fontName
                        font.pixelSize: baseFontSize
                    }

                    implicitHeight: Math.max(mediaTitleMetrics.height, mediaStatusMetrics.height, iconSize) + (colPaddingY * 2)
                    width: Math.min(availableWidth, mediaStatusMetrics.width + colSpacing + mediaTitleMetrics.width + (colPaddingX * 2))

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: colPaddingX
                        anchors.rightMargin: colPaddingX
                        anchors.topMargin: colPaddingY
                        anchors.bottomMargin: colPaddingY
                        spacing: colSpacing

                        Text {
                            color: ctpSubtext1
                            font.family: fontName
                            font.pixelSize: baseFontSize
                            text: mediaCol.mediaStatusIcon
                        }

                        Text {
                            Layout.fillWidth: true
                            color: ctpText
                            font.family: fontName
                            font.pixelSize: baseFontSize
                            elide: Text.ElideRight
                            text: mediaCol.mediaTitle
                        }
                    }
                }
            }
        }
    }
}
