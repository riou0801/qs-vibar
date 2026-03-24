pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
    id: shell
    property alias greetContext: greetContext

    GreetContext {
        id: greetContext
        sessionCommand: ["sway"]
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData
            readonly property GreetContext greetContext: shell.greetContext
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"

            GreetSurface {
                anchors.fill: parent
                context: root.greetContext
                wallpaperSource: "/home/riou/.config/background/catppuccin_ekg_1.png"
            }
        }
    }
}
