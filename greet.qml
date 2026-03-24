import Quickshell
import QtQuick

ShellRoot {
    GreetContext {
        id: greetContext
        sessionCommand: ["sway"]
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
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
                context: greetContext
                wallpaperSource: "/home/riou/.config/background/catppuccin_ekg_1.png"
            }
        }
    }
}
