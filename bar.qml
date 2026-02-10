import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.I3
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 30
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

    readonly property int barPadding: 6
    readonly property int colPaddingX: 8
    readonly property int colPaddingY: 4
    readonly property int colRadius: 8
    readonly property int iconSize: 18
    readonly property int colSpacing: 6

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

            implicitHeight: workspaceRow.implicitHeight + (colPaddingY * 2)
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
                            font.pixelSize: 12
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
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: ctpSurface0
            radius: colRadius
            border.width: 1
            border.color: ctpOverlay0

            implicitHeight: trayRow.implicitHeight + (colPaddingY * 2)
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

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onClicked: function (mouse) {
                                if (mouse.button === Qt.RightButton && trayItemRoot.modelData.hasMenu) {
                                    const pos = trayItemRoot.mapToItem(root, mouse.x, mouse.y);
                                    trayItemRoot.modelData.display(root, pos.x, pos.y);
                                } else if (!trayItemRoot.modelData.onlyMenu) {
                                    trayItemRoot.modelData.activate();
                                } else if (trayItemRoot.modelData.hasMenu) {
                                    const pos = trayItemRoot.mapToItem(root, mouse.x, mouse.y);
                                    trayItemRoot.modelData.display(root, pos.x, pos.y);
                                }
                            }
                        }
                    }
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
                font.pixelSize: 12
            }

            TextMetrics {
                id: mediaStatusMetrics
                text: mediaCol.mediaStatusIcon
                font.pixelSize: 12
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
                    font.pixelSize: 12
                    text: mediaCol.mediaStatusIcon
                }

                Text {
                    Layout.fillWidth: true
                    color: ctpText
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    text: mediaCol.mediaTitle
                }
            }
        }
    }
}
