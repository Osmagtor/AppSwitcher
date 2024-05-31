#Requires AutoHotkey v2.0
#SingleInstance Force

class Main {
    HMAIN := ThemeValueVariables["IconSize"] + 40
    title := "Super AltTab.ahk"
    gui := "" ; An object of the AHK "Gui" class
    x := ""
    y := ""
    windowsArray := [] ; An array of objects of the "Window" class
    outline := "" ; An object of the "Outline" class

    /**
     * Constructor
     * @param position The "position" value to be passed to the "Outline".
     * If omitted, it defaults to a falsy empty string
     */
    __New(position := "") {
        ; Retrieve all the windows whose icons will be displayed
        this.windowsArray := Window.WinGetListAlt()

        if (this.windowsArray.Length > 0) {
            ; Prepare the Gui of the main window
            this.gui := Gui("+AlwaysOnTop -Caption +toolwindow +LastFound -Border", this.title)
            try {
                this.gui.BackColor := ThemeValueVariables["BackgroundColor"]
            }

            ; Listen to any loss in focus of the app's main window
            this.listenToFocus()

            ; Create the window
            this.localDrawWindow()

            ; Adding the outline window
            this.outline := Outline(this, position)
        } else {
            throw NoWindowsError()
        }
    }

    __Delete() {
        AnimateWindow(this.gui.hwnd, 50, "0x90000")
        this.gui.Destroy()
    }

    /**
     * Method to start listening to any loss of foucs by a window of this class
     */
    listenToFocus() {
        DllCall("RegisterShellHookWindow", "ptr", A_ScriptHwnd)
        OnMessage(DllCall("RegisterWindowMessage", "Str", "SHELLHOOK"), FocusLost)
    }

    /**
     * Method to draw the main window of the app
     * @param windowsArray
     */
    localDrawWindow() {
        if (this.windowsArray.Length > 0) {
            for i in this.windowsArray {
                i.icon.draw(this.gui)
            }

            loop this.windowsArray.Length {
                if (this.windowsArray[A_Index].badge) {
                    this.windowsArray[A_Index].badge.draw(
                        this.gui,
                        this.windowsArray[A_Index].windowSubWindows.Length,
                        this.windowsArray[A_Index].icon.x,
                        this.windowsArray[A_Index].icon.y,
                        this.windowsArray[1].icon.size,
                        false
                    )
                }
            }

            EnableShadow(this.gui.hwnd)

            this.gui.Show("w" (((this.windowsArray[1].icon.padding + this.windowsArray[1].icon.size) * this.windowsArray.Length) - WindowsVersionVariables["MainOffset"]) + 20 " h" this.HMAIN " Hide") ;The "20" at the end adds 20 more pixels to the total width to make sure the last image is 20 pixels away from the window border
            AnimateWindow(this.gui.hwnd, 50, "0xa0000")

            WinGetPos(&xPos, &yPos, , , "ahk_id" this.gui.Hwnd)
            this.x := xPos
            this.y := yPos
        }
    }
}