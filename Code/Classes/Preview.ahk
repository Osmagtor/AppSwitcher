#Requires AutoHotkey v2.0
#SingleInstance Force

class Preview {
    x := ""
    y := ""
    w := ""
    h := ""
    gui := "" ; An object of the AHK "gui" class
    windowID := "" ; The ID of the window this object represents

    /**
     * Constructor
     * @param x The position to draw the window of this object on the x-axis
     * @param y The position to draw the window of this object on the y-axis
     * @param w The width to draw the window of this object
     * @param h The height to draw the window of this object
     * @param position The position of the object of the "PreviewOutline" class
     * @param hwnd The handle of the window of the object of the "PreviewOutline" class
     * @param windowID The handle of the window whose this object represents
     */
    __New(x, y, w, h, position, hwnd, windowID) {
        this.x := x
        this.y := y
        this.w := w
        this.h := h
        this.windowID := windowID

        this.localDraw(position, hwnd)
        this.localDrawMonitorNumber()
    }

    /**
     * Internal method to draw the previews
     * @param PreviewCounter The position of the object of the "PreviewOutline" class
     * @param hwnd The handle of the window of the object of the "PreviewOutline" class
     */
    localDraw(PreviewCounter, hwnd) {
        this.gui := Gui("-Caption +ToolWindow +AlwaysOnTop +Owner" hwnd, "Preview" PreviewCounter)
        this.gui.Show("x" this.x " y" this.y " w" this.w " h" this.h)

        Window.EnableShadow(this.gui.Hwnd)

        DllCall("LoadLibrary", "Str", "Dwmapi.dll", "Ptr")

        hwndDest := this.gui.Hwnd
        DllCall("dwmapi\DwmRegisterThumbnail", "Ptr", hwndDest, "Ptr", this.windowID, "Ptr*", &hThumbId := 0)

        DWM_TNP_RECTDESTINATION := 0x00000001
        DWM_TNP_VISIBLE := 0x00000008

        If (WinGetMinMax("ahk_id" this.windowID) = -1)
        {
            wp := Buffer(44)
            NumPut("UPtr", 44, wp)
            DllCall("GetWindowPlacement", "ptr", this.windowID, "ptr", wp)
            If (NumGet(wp, 3, "int") != 0)
            {
                a := -1
                b := -1
            }
            else
            {
                a := -1
                b := -1
                this.w += 1
                this.h += 1
            }
        }
        else
        {
            a := -1
            b := -1
            this.w += 1
            this.h += 1
        }

        dtp := Buffer(48)
        NumPut("UInt", DWM_TNP_RECTDESTINATION | DWM_TNP_VISIBLE, dtp, 0) ; dwFlags
        NumPut("Int", a, dtp, 4) ; rcDestination.left
        NumPut("Int", b, dtp, 8) ; rcDestination.top
        NumPut("Int", this.w, dtp, 12) ; rcDestination.right
        NumPut("Int", this.h, dtp, 16) ; rcDestination.bottom
        NumPut("Int", true, dtp, 40) ; fVisible

        DllCall("dwmapi\DwmUpdateThumbnailProperties", "Ptr", hThumbId, "Ptr", dtp)
    }

    /**
     * Method to draw the monitor number on the bottom right corner
     * of the window of each object of this class
     */
    localDrawMonitorNumber() {
        try {
            WinGetPos(&x, &y, &w, &h, "ahk_id" this.gui.hwnd)

            monitorNumber := Gui("+AlwaysOnTop -Caption +toolwindow +Owner" this.gui.hwnd, "test")
            monitorNumber.SetFont("s25 q5", "Segoe UI")
            monitorNumber.Add("Text", "x3 y-7 cffffff", "⬜")

            monitorNumber.SetFont("s10 q5 w2000", "Segoe UI")
            monitorNumber.Add("Text", "x14 y9 cffffff", (MonitorGetCount() + 1) - Window.WinGetMonitorIndex(this.windowID))
            monitorNumber.BackColor := "000000"

            Window.EnableShadow(monitorNumber.hwnd)
            monitorNumber.Show("x" x + w - 30 "y" y + h - 30 "w35 h35")
        } catch Error as err {
            showErrorTooltip(err)
        }
    }

    static calculatePreviewWidth(width, height, WindowHeight) {
        return (width * WindowHeight) / height
    }
}