#Requires AutoHotkey v2.0

class PreviewsMain {
    windowHeight := 242
    x := ""
    w := 0
    h := ""
    gui := "" ; An object of the AHK "gui" class
    title := "Super Previews.ahk"
    previewsArray := []
    outline := "" ; An object of the "PreviewOutline" class

    /**
     * Constructor
     * @param main An object of the "Main" class
     * @param window The currently selected window as an object of the "Window" class
     * @param TaskbarLeft
     * @param TaskbarRight
     * @param position The "position" value to be passed to the "Outline".
     * If omitted, it defaults to a falsy empty string
     */
    __New(main, window, TaskbarLeft, TaskbarRight, position := "") {
        if (main AND window.windowSubWindows.length > 1) {
            this.h := this.windowHeight + (main.windowsArray[1].icon.padding * 2)
            this.gui := Gui("+AlwaysOnTop -Caption +toolwindow -Border +Owner" main.gui.hwnd, this.title)

            try {
                this.gui.BackColor := ThemeValueVariables["BackgroundColor"]
                this.gui.SetFont("s10 q5 c" ThemeValueVariables["TextColor"], "Segoe UI")
            }

            this.localDraw(window, TaskbarLeft, TaskbarRight, main.HMAIN)
            this.outline := PreviewOutline(this, main.outline.window.windowSubWindows, position)
        } else {
            throw NoWindowsError()
        }
    }

    __Delete() {
        AnimateWindow(this.gui.hwnd, 50, "0x90000")
        this.gui.Destroy()
    }

    /**
     * Internal method to draw the window of this object
     * @param window The currently selected object of the "Window" class
     * @param TaskbarLeft The width of the taskbar if it is located vertically on the left
     * @param TaskbarRight The width of the taskbar if it is located vertically on the right
     * @param hmain The height of the object of the "main" class
     */
    localDraw(window, TaskbarLeft, TaskbarRight, hmain) {
        try {
            If (window.windowSubWindows.length > 1) {
                while (this.w > (A_ScreenWidth - TaskbarLeft - TaskbarRight - 100) || this.w = 0) {
                    ; If the final width of all the previews is too large, then we go to "FinalwTooBig" and try again with a smaller "PreviewWindowHeight"

                    this.windowHeight := this.w = 0 ?
                        this.windowHeight :
                            (this.windowHeight * (A_ScreenWidth - TaskbarLeft - TaskbarRight - 100)) / this.w
                    this.h := this.w = 0 ?
                        this.h :
                            this.windowHeight + 60
                    this.w := 0

                    for i in window.windowSubWindows {
                        this.w += (Preview.calculatePreviewWidth(i.w, i.h, this.windowHeight) + window.icon.padding) ; Some simple Cross-multiplication
                    }
                }

                ; Some calculations that do not require to be in the upcoming loop

                this.x := ((A_ScreenWidth / 2) + (TaskbarRight / 2) + (TaskbarLeft / 2)) - (this.w / 2)
                this.y := (A_ScreenHeight / 2) + (hmain / 2) + WindowsVersionVariables["Gap"]

                ; Creating the main preview window

                EnableShadow(this.gui.hwnd)

                this.gui.Show("x" this.x " y" this.y " w" this.w " h" this.h " Hide")
                AnimateWindow(this.gui.hwnd, 50, "0xa0000")
            }
        } catch Error as err {
            showErrorTooltip(err)
        }
    }

    /**
     * Method to create all the previews located in the attribute "previewsArray"
     * @param subWindows An array of objects of the "Window" class
     * @param hwnd The handle of the owner window of the previews
     */
    createPreviews(subWindows, hwnd) {
        Loop subWindows.length {
            try {
                this.previewsArray.Push(
                    Preview(
                        A_Index = 1 ?
                            this.x + 15 :
                            this.previewsArray[A_Index - 1].x + this.previewsArray[A_Index - 1].w + subWindows[1].icon.padding,
                        this.y + 15,
                        Preview.calculatePreviewWidth(
                            subWindows[A_Index].w,
                            subWindows[A_Index].h,
                            this.windowHeight
                        ),
                        this.windowHeight,
                        A_Index,
                        hwnd,
                        subWindows[A_Index].windowID
                    )
                )

                ; Adding the text to the gui of this object
                this.gui.Add(
                    "Text",
                    "x" this.previewsArray[A_Index].x - this.x
                    " y" this.h - subWindows[1].icon.padding
                    " w" this.previewsArray[A_Index].w
                    " h17",
                    subWindows[A_Index].windowTitle
                )
            } catch {
                MsgBox(
                    "this.x: " . this.x .
                    "`nthis.previewsArray[A_Index-1]: " . this.previewsArray[A_Index-1] .
                    "`nsubWindows[A_Index].w: " . subWindows[A_Index].w .
                    "`nnsubWindows[A_Index].h: " . subWindows[A_Index].h .
                    "`nthis.windowHeight: " . this.windowHeight
                    "`nhwnd: " . hwnd .
                    "`nsubWindows[A_Index].windowID: " . subWindows[A_Index].windowID
                )
            }
        }
    }
}