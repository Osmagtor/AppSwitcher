#Requires AutoHotkey v2.0
#SingleInstance Force

class Preview {
    x1 := ""
    y1 := ""
    x2 := ""
    y2 := ""
    h := ""
    w := ""
    hThumbId := ""
    previewMain := "" ; An object of the "PreviewMain" class
    windowID := "" ; The ID of the window this object represents

    /**
     * Constructor
     * @param x The position to draw the window of this object on the x-axis
     * @param y The position to draw the window of this object on the y-axis
     * @param w The width to draw the window of this object
     * @param h The height to draw the window of this object
     * @param windowID The handle of the window whose this object represents
     * @param previewMain The object of the "PreviewMain" class that it belongs to
     */
    __New(x, y, w, h, windowID, previewMain) {
        this.x1 := x
        this.y1 := y
        this.x2 := w + this.x1
        this.y2 := this.h := h
        this.w := w
        this.windowID := windowID
        this.previewMain := previewMain

        this.localDraw()
    }

    /**
     * Internal method to draw the previews
     */
    localDraw() {
        DllCall("LoadLibrary", "Str", "Dwmapi.dll", "Ptr")

        hwndDest := this.previewMain.gui.hwnd
        DllCall("dwmapi\DwmRegisterThumbnail", "Ptr", hwndDest, "Ptr", this.windowID, "Ptr*", &hThumbId := 0)

        DWM_TNP_RECTDESTINATION := 0x00000001
        DWM_TNP_VISIBLE := 0x00000008

        dtp := Buffer(48)
        NumPut("UInt", DWM_TNP_RECTDESTINATION | DWM_TNP_VISIBLE, dtp, 0) ; dwFlags
        NumPut("Int", this.x1, dtp, 4) ; rcDestination.left
        NumPut("Int", this.y1, dtp, 8) ; rcDestination.top
        NumPut("Int", this.x2, dtp, 12) ; rcDestination.right
        NumPut("Int", this.y2, dtp, 16) ; rcDestination.bottom
        NumPut("Int", true, dtp, 40) ; fVisible

        DllCall("dwmapi\DwmUpdateThumbnailProperties", "Ptr", hThumbId, 
        "Ptr", dtp)

        this.hThumbId := hThumbId
    }

    /**
     * Method to erase a preview that has already been drawn to a GUI
     */
    erase() {
        DllCall("dwmapi\DwmUnregisterThumbnail", "Ptr", this.hThumbId)
    }

    static calculatePreviewWidth(width, height, WindowHeight) {
        return (width * WindowHeight) / height
    }
}