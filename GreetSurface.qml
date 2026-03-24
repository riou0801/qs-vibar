import QtQuick
import Quickshell.Io

Rectangle {
    id: root

    required property GreetContext context
    required property string wallpaperSource

    readonly property color ctpBase: "#1e1e2e"
    readonly property color ctpSurface0: "#313244"
    readonly property color ctpOverlay0: "#6c7086"
    readonly property color ctpText: "#cdd6f4"
    readonly property color ctpSubtext1: "#bac2de"
    readonly property color ctpLavender: "#b4befe"
    readonly property color ctpRed: "#f38ba8"
    readonly property string fontName: "NotoSans Nerd Font"

    color: ctpBase

    // --- セッション一覧 ---
    // /usr/share/wayland-sessions/*.desktop から動的に読み取る
    ListModel {
        id: sessionModel
    }
    property int sessionIndex: 0

    Process {
        id: sessionLoader
        running: true
        command: ["sh", "-c", "for f in /usr/share/wayland-sessions/*.desktop; do " + "name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); " + "ex=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2-); " + "[ -n \"$name\" ] && [ -n \"$ex\" ] && printf '%s\\t%s\\n' \"$name\" \"$ex\"; " + "done"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split("\t");
                    if (parts.length >= 2) {
                        sessionModel.append({
                            name: parts[0],
                            exec: parts[1]
                        });
                    }
                }
                if (sessionModel.count > 0) {
                    root.context.sessionCommand = sessionModel.get(0).exec.split(" ");
                }
            }
        }
    }

    // 選択セッションの Exec を context にバインド
    onSessionIndexChanged: {
        if (sessionModel.count > 0) {
            var entry = sessionModel.get(sessionIndex);
            root.context.sessionCommand = entry.exec.split(" ");
        }
    }

    // --- 認証失敗時にパスワードフィールドをクリア ---
    Connections {
        target: root.context
        function onShowFailureChanged() {
            if (root.context.showFailure) {
                passwordInput.text = "";
            }
        }
    }

    // --- 壁紙 ---
    Image {
        anchors.fill: parent
        source: root.wallpaperSource
        fillMode: Image.PreserveAspectCrop
    }

    // --- ガラスパネル ---
    Rectangle {
        id: glassPanel
        anchors.centerIn: parent
        width: 380
        height: glassContent.height + 64
        radius: 16
        color: Qt.rgba(0.118, 0.118, 0.180, 0.75)
        border.width: 1
        border.color: root.ctpOverlay0

        Column {
            id: glassContent
            anchors.centerIn: parent
            spacing: 0

            // ── 時計 (HH:mm) ──
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 64
                color: root.ctpText
                font.family: root.fontName
                text: Qt.formatDateTime(new Date(), "HH:mm")
                Timer {
                    running: true
                    repeat: true
                    interval: 1000
                    onTriggered: parent.text = Qt.formatDateTime(new Date(), "HH:mm")
                }
            }

            // ── 日付 (yyyy/MM/dd) ──
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                bottomPadding: 32
                font.pixelSize: 20
                color: root.ctpSubtext1
                font.family: root.fontName
                text: Qt.formatDateTime(new Date(), "yyyy/MM/dd")
                Timer {
                    running: true
                    repeat: true
                    interval: 1000
                    onTriggered: parent.text = Qt.formatDateTime(new Date(), "yyyy/MM/dd")
                }
            }

            // ── パスワード入力 ──
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
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
                    enabled: !root.context.authInProgress
                    focus: true
                    inputMethodHints: Qt.ImhSensitiveData

                    onAccepted: {
                        root.context.password = text;
                        root.context.startAuth();
                    }

                    // プレースホルダー
                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "パスワード"
                        color: root.ctpOverlay0
                        font.family: root.fontName
                        font.pixelSize: 16
                        visible: !passwordInput.text && !passwordInput.activeFocus
                    }
                }
            }

            // ── セッション選択 ──
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 320
                height: 36
                topPadding: 0

                // パネル内の実際のレイアウト行
                Row {
                    anchors.centerIn: parent
                    spacing: 16

                    // 左矢印
                    Text {
                        text: "◀"
                        color: root.sessionIndex > 0 ? root.ctpSubtext1 : root.ctpOverlay0
                        font.family: root.fontName
                        font.pixelSize: 18
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.sessionIndex > 0)
                                    root.sessionIndex--;
                            }
                        }
                    }

                    // セッション名
                    Text {
                        id: sessionLabel
                        text: sessionModel.count > 0 ? sessionModel.get(root.sessionIndex).name : ""
                        color: root.ctpText
                        font.family: root.fontName
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: 120
                    }

                    // 右矢印
                    Text {
                        text: "▶"
                        color: root.sessionIndex < sessionModel.count - 1 ? root.ctpSubtext1 : root.ctpOverlay0
                        font.family: root.fontName
                        font.pixelSize: 18
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.sessionIndex < sessionModel.count - 1)
                                    root.sessionIndex++;
                            }
                        }
                    }
                }

                // キーボード左右でセッション切り替え
                Keys.onLeftPressed: {
                    if (root.sessionIndex > 0)
                        root.sessionIndex--;
                }
                Keys.onRightPressed: {
                    if (root.sessionIndex < sessionModel.count - 1)
                        root.sessionIndex++;
                }
            }

            // ── エラーメッセージ ──
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 8
                opacity: root.context.showFailure ? 1.0 : 0.0
                text: root.context.errorMessage || "認証に失敗しました"
                color: root.ctpRed
                font.family: root.fontName
                font.pixelSize: 14

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }
        }
    }
}
