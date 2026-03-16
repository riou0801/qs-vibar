import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland

Rectangle {
    id: root

    required property LockContext context

    readonly property color ctpBase: "#1e1e2e"
    readonly property color ctpSurface0: "#313244"
    readonly property color ctpOverlay0: "#6c7086"
    readonly property color ctpText: "#cdd6f4"
    readonly property color ctpSubtext1: "#bac2de"
    readonly property color ctpLavender: "#b4befe"
    readonly property color ctpRed: "#f38ba8"
    readonly property string fontName: "NotoSans Nerd Font"

    color: ctpBase

    Image {
        anchors.fill: parent
        source: "/home/riou/.config/background/catppuccin_ekg_1.png"
        fillMode: Image.PreserveAspectCrop
    }

    Column {
        id: clockArea
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 96
            color: root.ctpText
            font.family: root.fontName
            text: Qt.formatDateTime(new Date(), "HH:mm")
            Timer { running: true; repeat: true; interval: 1000; onTriggered: parent.text = Qt.formatDateTime(new Date(), "HH:mm") }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 20
            color: root.ctpSubtext1
            font.family: root.fontName
            text: Qt.formatDateTime(new Date(), "yyyy/MM/dd")
            Timer { running: true; repeat: true; interval: 1000; onTriggered: parent.text = Qt.formatDateTime(new Date(), "yyyy/MM/dd") }
        }
    }

    ColumnLayout {
        anchors.top: clockArea.bottom
        anchors.topMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 320
            height: 44
            radius: 22
            color: root.ctpSurface0
            border.width: 1
            border.color: passwordInput.activeFocus ? root.ctpLavender : root.ctpOverlay0

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: root.ctpText
                font.family: root.fontName
                font.pixelSize: 16
                enabled: !root.context.unlockInProgress
                focus: true
                inputMethodHints: Qt.ImhSensitiveData
                onTextChanged: root.context.currentText = text
                onAccepted: root.context.tryUnlock()

                Connections {
                    target: root.context
                    function onCurrentTextChanged() {
                        if (passwordInput.text !== root.context.currentText)
                            passwordInput.text = root.context.currentText
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.context.showFailure
            text: "パスワードが正しくありません"
            color: root.ctpRed
            font.family: root.fontName
            font.pixelSize: 14
        }
    }
}
