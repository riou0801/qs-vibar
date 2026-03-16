import Quickshell
import Quickshell.Wayland

ShellRoot {
    LockContext {
        id: lockContext
        onUnlocked: {
            lock.locked = false
            Qt.quit()
        }
    }

    WlSessionLock {
        id: lock
        locked: true

        WlSessionLockSurface {
            LockSurface {
                wallpaperSource: "/home/riou/.config/background/catppuccin_ekg_1.png"
                anchors.fill: parent
                context: lockContext
            }
        }
    }
}
