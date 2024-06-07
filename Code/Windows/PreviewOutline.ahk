#Requires AutoHotkey v2.0

class PreviewOutline {
    x := ""
    y := ""
    w := ""
    h := ""
    title := "Super PreviewsOutline.ahk"
    gui := "" ; An object of the AHK "gui" class
    previewCounter := ""
    subWindows := "" ; The object of the "Window" class drawn on the outline window
    owner := "" ; The owner window as an object of the "PreviewMain" class

    /**
     * Constructor
     * @param previewsWindow An object of the "PreviewMain" class
     * @param subWindows An array of objects of the "Window" class
     * @param position The position where the window of an object
     * of this class should be drawn. An empty string (i.e., falsy) if omitted
     */
    __New(previewsWindow, subWindows, position := "") {
        if previewsWindow {
            this.owner := previewsWindow
            this.gui := Gui("+AlwaysOnTop -Caption +toolwindow -Border +Owner" this.owner.gui.hwnd, this.title)
            this.owner.createPreviews(subWindows, this.gui.Hwnd)

            if position {
                this.previewCounter := position < 1 ? 1
                    : position > subWindows.Length ?
                        subWindows.Length
                        : position
            } else {
                this.previewCounter := 1
            }

            try {
                this.gui.BackColor := ThemeValueVariables["AccentColor"]
            }

            this.subWindows := subWindows
            this.draw(false)
        } else {
            throw NoWindowsError()
        }
    }

    /**
     * Method to draw and move the window of an object of this class
     * @param right "True" if it is to be moved to the right, "false" if it is to be moved to the left
     */
    draw(right) {
        try {
            if WinExist("ahk_id" this.gui.hwnd) {
                if (right) {
                    this.previewCounter := this.previewCounter + 1 > this.subWindows.Length ? 1 : this.previewCounter + 1
                } else {
                    this.previewCounter := this.previewCounter - 1 < 1 ? this.subWindows.Length : this.previewCounter - 1
                }

                this.localGetPosData()
                WinMove(this.x, this.y, this.w, this.h, "ahk_id " this.gui.hwnd)
            } else {
                this.localGetPosData()
                Window.EnableShadow(this.gui.Hwnd)
                this.gui.Show("x" this.x " y" this.y " w" this.w " h" this.h)
                WinActivate("Super AltTab.ahk")
            }
        } catch Error as err {
            showErrorTooltip(err)
        }
    }

    /**
     * Internal method to the coordinates and dimensions of the window of an object of this class
     * in relation to the previews already stored in an object of the "PreviewMain" class
     */
    localGetPosData() {
        this.x := this.owner.previewsArray[this.previewCounter].x - 5
        this.y := this.owner.y + 10
        this.w := Preview.calculatePreviewWidth(this.subWindows[this.previewCounter].w, this.subWindows[this.previewCounter].h, this.owner.windowHeight) + 11
        this.h := this.owner.h - 49
    }

    /**
     * Method to retrieve the currently selected object of the "window" class 
     * by an object of the "PreviewOutline" class
     */
    getWindow() {
        return this.subWindows[this.previewCounter]
    }
}