import QtQuick
import Quickshell
import Quickshell.Services.Greetd

Scope {
    id: root

    property string password: ""
    property list<string> sessionCommand: ["sway"]
    property bool authInProgress: false
    property bool readyToLaunch: false
    property string errorMessage: ""
    property bool waitingResponse: false
    property bool showFailure: false

    onPasswordChanged: showFailure = false

    function startAuth() {
        if (root.password === "")
            return;
        root.authInProgress = true;
        root.errorMessage = "";
        root.showFailure = false;
        Greetd.createSession("riou");
    }

    function sendResponse(response) {
        root.waitingResponse = false;
        Greetd.respond(response);
    }

    function launch() {
        Greetd.launch(root.sessionCommand);
    }

    function cancel() {
        Greetd.cancelSession();
        root.authInProgress = false;
        root.readyToLaunch = false;
        root.waitingResponse = false;
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (error) {
                root.errorMessage = message;
                return;
            }
            if (responseRequired) {
                root.sendResponse(root.password);
            }
        }

        function onReadyToLaunch() {
            root.readyToLaunch = true;
            root.launch();
        }

        function onAuthFailure(message) {
            root.errorMessage = message || "Authentication failed";
            root.password = "";
            root.showFailure = true;
            root.authInProgress = false;
            root.readyToLaunch = false;
            root.waitingResponse = false;
        }

        function onError(message) {
            root.errorMessage = message || "An error occurred";
            root.authInProgress = false;
            root.waitingResponse = false;
        }
    }
}
