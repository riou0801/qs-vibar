import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    signal unlocked()

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    onCurrentTextChanged: showFailure = false

    function tryUnlock() {
        if (root.currentText === "") return
        root.unlockInProgress = true
        pam.start()
    }

    PamContext {
        id: pam
        configDirectory: "pam"
        config: "quickshell"
        onPamMessage: (message) => {
            if (message.responseRequired) message.respond(root.currentText)
        }
        onCompleted: (result) => {
            if (result === PamResult.Success) {
                root.unlocked()
            } else {
                root.currentText = ""
                root.showFailure = true
            }
            root.unlockInProgress = false
        }
    }
}
