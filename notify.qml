import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.I3
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    readonly property int maxNotifications: 2
    readonly property int timeoutMs: 3000
    readonly property int barPadding: 8
    readonly property int cardRadius: 8
    readonly property int cardPadding: 10
    readonly property int cardSpacing: 8
    readonly property int iconSize: 28

    // Catppuccin Mocha palette
    readonly property color ctpBase: "#1e1e2e"
    readonly property color ctpSurface0: "#313244"
    readonly property color ctpOverlay0: "#6c7086"
    readonly property color ctpText: "#cdd6f4"
    readonly property color ctpSubtext1: "#bac2de"
    readonly property color ctpBlue: "#89b4fa"
    readonly property color ctpRed: "#f38ba8"

    property var notificationTimes: ({})
    property int ticker: 0

    function getCreatedAt(notification) {
        if (!notification || notification.id === undefined) {
            return Date.now();
        }
        if (notificationTimes[notification.id] === undefined) {
            notificationTimes[notification.id] = Date.now();
        }
        return notificationTimes[notification.id];
    }

    function latestNotifications() {
        const list = notificationServer.trackedNotifications.values;
        const start = Math.max(0, list.length - maxNotifications);
        return list.slice(start).reverse();
    }

    NotificationServer {
        id: notificationServer
        imageSupported: true

        onNotification: function (notification) {
            notification.tracked = true;
            root.getCreatedAt(notification);
        }
    }

    Timer {
        interval: 33
        running: true
        repeat: true
        onTriggered: {
            root.ticker++;
            const now = Date.now();
            const list = notificationServer.trackedNotifications.values;
            for (let i = 0; i < list.length; i++) {
                const notif = list[i];
                const created = root.getCreatedAt(notif);
                if (now - created >= root.timeoutMs) {
                    notif.expire();
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            required property var modelData

            anchors {
                top: true
                left: true
                right: true
            }

            screen: modelData
            color: "transparent"
            aboveWindows: true
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Top
            implicitHeight: 1
            visible: I3.focusedMonitor === I3.monitorFor(modelData)

            PopupWindow {
                id: popup
                anchor.window: window
                anchor.rect.x: (window.width - width) / 2
                anchor.rect.y: barPadding
                implicitWidth: Math.min(window.width, 480)
                implicitHeight: stack.implicitHeight
                color: "transparent"
                visible: root.latestNotifications().length > 0

                ColumnLayout {
                    id: stack
                    width: parent.width
                    spacing: cardSpacing

                    Repeater {
                        model: root.latestNotifications()

                        Rectangle {
                            id: card
                            required property Notification modelData

                            property real progress: {
                                root.ticker;
                                const elapsed = Date.now() - root.getCreatedAt(modelData);
                                return Math.max(0, 1 - (elapsed / root.timeoutMs));
                            }

                            radius: cardRadius
                            color: ctpSurface0
                            border.width: 1
                            border.color: modelData.urgency === NotificationUrgency.Critical ? ctpRed : ctpBlue

                            Layout.fillWidth: true
                            implicitHeight: Math.max(iconSize, summaryText.implicitHeight + bodyText.implicitHeight + 6) + (cardPadding * 2)

                            MouseArea {
                                anchors.fill: parent
                                onClicked: modelData.dismiss()
                            }

                            RowLayout {
                                id: cardRow
                                anchors.fill: parent
                                anchors.margins: cardPadding
                                spacing: 10

                                Item {
                                    width: iconSize
                                    height: iconSize
                                    visible: iconImage.visible || appIcon.visible

                                    Image {
                                        id: iconImage
                                        anchors.centerIn: parent
                                        width: iconSize
                                        height: iconSize
                                        source: modelData.image
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        visible: modelData.image && modelData.image !== ""
                                    }

                                    IconImage {
                                        id: appIcon
                                        anchors.centerIn: parent
                                        implicitSize: iconSize
                                        source: modelData.appIcon
                                        visible: !iconImage.visible && modelData.appIcon && modelData.appIcon !== ""
                                    }
                                }

                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true

                                    Text {
                                        id: summaryText
                                        text: modelData.summary || modelData.appName
                                        color: ctpText
                                        font.pixelSize: 15
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        id: bodyText
                                        text: modelData.body
                                        color: ctpSubtext1
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        height: 2
                                        color: ctpOverlay0
                                        Layout.fillWidth: true

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: parent.width * card.progress
                                            color: modelData.urgency === NotificationUrgency.Critical ? ctpRed : ctpBlue
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
