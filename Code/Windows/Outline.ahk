#Requires AutoHotkey v2.0
#SingleInstance Force

class Outline {
    title := "Super Outline.ahk"
    gui := ""
    main := "" ; An object of the "Main" class
    tabCounter := "" ; The position where the outline is
    window := "" ; The object of the "Window" class drawn on the outline window

    /**
     * Constructor
     * @param main The owner window. An object of the "Main" class
     * @param position The position where the window of an object
     * of this class should be drawn. An empty string (i.e., falsy) if omitted
     */
    __New(main, position := "") {
        if main {
            ; main
            this.main := main

            ; gui
            this.gui := Gui("+AlwaysOnTop -Caption +toolwindow +LastFound -Border +Owner" main.gui.hwnd, this.title)
            try {
                this.gui.BackColor := ThemeValueVariables["AccentColor"]
            }

            ; tabCounter
            if (main.windowsArray.Length > 1) {
                if position {
                    this.tabCounter := position < 1 ? 1
                        : position > main.windowsArray.Length ?
                            main.windowsArray.Length
                            : position
                } else {
                    loop main.windowsArray.Length {
                        if (!main.windowsArray[A_Index].onTop) {
                            this.tabCounter := A_Index + 1 <= main.windowsArray.Length ? A_Index + 1 : A_Index
                            break
                        }
                    }
                }
            } else {
                this.tabCounter := 1
            }

            ; window
            this.window := this.localGetWindow(this.main.windowsArray[this.tabCounter])

            ; Drawing the outline
            this.localDraw()
        } else {
            throw NoWindowsError()
        }
    }

    /**
     * Internal method to make a modified copy of the currently selected window
     * @param win An object of the "Window" class
     * @return The modified copy of the currently selected object of the "Window" class
     */
    localGetWindow(win) {
        previousIcon := ""
        previousBadge := ""

        if (this.window) {
            previousIcon := this.window.icon
            previousBadge := this.window.badge
        }

        tempWin := Window(
            win.windowTitle,
            win.windowClass,
            win.windowID,
            win.windowPID,
            win.windowSubWindows,
            1
        )

        if (previousIcon AND previousBadge) {
            tempWin.icon := previousIcon
            tempWin.icon.filepath := win.icon.filepath
            tempWin.icon.ctrl.Value := tempWin.icon.filepath
            tempWin.badge := previousBadge
        } else {
            tempWin.icon.parameters := "x10 y10 h" . tempWin.icon.size . " w" . tempWin.icon.size . " BackgroundTrans"
        }

        return tempWin
    }

    /**
     * Method to move the outline
     * @param right "True" to move right, "false" to move left
     */
    move(right) {
        if (right) {
            this.tabCounter := this.tabCounter + 1 > this.main.windowsArray.Length ? 1 : this.tabCounter + 1
        } else {
            this.tabCounter := this.tabCounter - 1 < 1 ? this.main.windowsArray.Length : this.tabCounter - 1
        }

        this.window := this.localGetWindow(this.main.windowsArray[this.tabCounter])
        this.window.badge.update(this.window)

        WinMove(this.main.x + this.main.windowsArray[this.tabCounter].icon.x - 10, , , , "ahk_id " this.gui.Hwnd)
    }

    /**
     * Method to draw the outline window
     */
    localDraw() {
        try {
            ; Preparing the window
            this.window.icon.draw(this.gui)
            this.window.badge.draw(
                this.gui,
                this.window.windowSubWindows.Length,
                this.window.icon.x,
                this.window.icon.y,
                this.window.icon.size,
                true
            )
            this.window.badge.update(this.window)

            EnableShadow(this.gui.Hwnd)
            AnimateWindow(this.gui.Hwnd, 100, "0xa0000")
            this.gui.Show("x" this.main.x + this.main.windowsArray[this.tabCounter].icon.x - 10 " y" this.main.y + 10 " w" this.window.icon.size + 20 " h" this.window.icon.size + 20)
        } catch Error as err {
            showErrorTooltip(err)
        }
    }
}