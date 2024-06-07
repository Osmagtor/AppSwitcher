#Requires AutoHotkey v2.0
#SingleInstance Force

class Icon {
    ; The filepath of the default Windows ".exe" icon
    ; It is used for windows whose icon filepath causes issues
    fallbackIconPath := A_WinDir "\system32\SHELL32.dll"
    size := ThemeValueVariables["IconSize"]
    static padding := 30
    ctrl := "" ; The AHK control object of the "Gui" class
    parameters := ""
    filepath := 0
    x := ""
    y := ""
    static uwpIconSizes := Array(96, 80, 72, 64, 60, 48)

    /**
     * Constructor
     * @param title The window's title 
     * @param id The window's handle
     * @param class The window's class
     * @param uwp Whether the window is a UWP app
     * @param position The position of the window in the "Main" object
     */
    __New(title, id, class, uwp, position) {
        this.filepath := uwp OR InStr(WinGetProcessPath("ahk_id" id), "C:\Program Files\WindowsApps\") ? this.localGetUWPIcon(title, id) : WinGetProcessPath("ahk_id" id)

        this.parameters := position = 1 ?
            "x21 y20 h" . this.size . " w" . this.size . " BackgroundTrans"
                : "x+m xp" . this.size + Icon.padding . " y20 h" . this.size . " w" . this.size . " BackgroundTrans"
    }

    /**
     * Method to draw the icon to a given Gui
     * @param gui An object of the AHK class "Gui" to draw the icon to
     */
    draw(gui) {
        try {
            this.ctrl := gui.Add("Picture", this.parameters, this.filepath)
        } catch {
            this.filepath := this.fallbackIconPath
            this.ctrl := gui.Add("Picture", this.parameters, this.filepath)
        }

        ControlGetPos(&xPos, &yPos, , , this.ctrl, "ahk_id " gui.Hwnd)
        this.x := xPos
        this.y := yPos
    }

    /**
     * Private method to retrieve the filepath of the icon of a UWP app window
     * @param title The title of the window
     * @param id The handle of the window
     * @returns {String} The filepath to the icon of the UWP app
     */
    localGetUWPIcon(title, id) {
        try {
            b := ""
            iconSize := 0

            for ArrayIndex in Icon.uwpIconSizes
            {
                if (ArrayIndex <= ThemeValueVariables["IconSize"])
                {
                    iconSize := ArrayIndex
                    break
                }
            }

            if (FileExist("settings.ini")) {
                ParsedWindowTitle := SubStr(title, InStr(title, "-", false, -1) + 1)

                b := IniRead("settings.ini", "uwp icon paths", ParsedWindowTitle, False)
                b := StrReplace(b, "XXXX", iconsize)
                b := FileExist(b) ? b : ""
            }

            If (b)
            {
                return b
            }
            else
            {
                If (WinGetMinMax("ahk_id" id) = -1)
                {
                    return A_WinDir "\system32\SHELL32.dll"
                }
                else
                {
                    if (!InStr(WinGetProcessPath("ahk_id" id), "C:\Program Files\WindowsApps\")) {
                        HWND := ControlGetHwnd("Windows.UI.Core.CoreWindow1", "ahk_id" id)
                        FinalPath := WinGetProcessPath("ahk_id" HWND)
                        FinalPathTrim := SubStr(FinalPath, 1, InStr(FinalPath, "\", false, -1))
                    } else {
                        path := WinGetProcessPath("ahk_id" id)
                        FinalPathTrim := SubStr(path, 1, InStr(path, "\", false, -1))
                    }

                    ; To account for UWP Apps that have the correct file path but have no app manifest (e.g., Snipping Tool)
                    try {
                        SearchString := "Square44x44Logo="
                        images := [".targetsize-" . iconSize . "_altform-lightunplated.png", ".altform-lightunplated_targetsize-" . iconSize . ".png", ".targetsize-" . iconSize . "_altform-unplated.png", ".png"]

                        Loop Read FinalPathTrim "AppxManifest.xml"
                        {
                            If InStr(A_LoopReadLine, SearchString)
                            {
                                StringTrim := SubStr(A_LoopReadLine, 1, InStr(A_LoopReadLine, ".png", false, -1) - 1)
                                StringTrim2 := SubStr(StringTrim, InStr(StringTrim, "=", false, -1) + 2)
                                StringTrim2v2 := SubStr(StringTrim, InStr(StringTrim, ">", false, -1) + 1)
                                Break
                            }
                        }

                        for ArrayIndex in images
                        {
                            if FileExist(FinalPathTrim StringTrim2 ArrayIndex)
                            {
                                IniWrite(StrReplace(FinalPathTrim StringTrim2 ArrayIndex, iconSize, "XXXX"), "settings.ini", "uwp icon paths", ParsedWindowTitle)
                                return FinalPathTrim StringTrim2 ArrayIndex
                            }
                        }

                        for ArrayIndex in images
                        {
                            if FileExist(FinalPathTrim StringTrim2v2 ArrayIndex)
                            {
                                IniWrite(StrReplace(FinalPathTrim StringTrim2v2 ArrayIndex, iconSize, "XXXX"), "settings.ini", "uwp icon paths", ParsedWindowTitle)
                                return FinalPathTrim StringTrim2v2 ArrayIndex
                            }
                        }
                    } catch {
                        return WinGetProcessPath("ahk_id" id)
                    }
                }

                return A_WinDir "\system32\SHELL32.dll"
            }
        } catch Error as err {
            showErrorTooltip(err)
        }
    }

    /**
     * Method to turn the icon object into a string
     * @returns {String} 
     */
    toString() {
        return "size: " . this.size . "`n"
            . "padding: " . Icon.padding . "`n"
            . "control: " . this.ctrl.hwnd . "`n"
            . "parameters: " . this.parameters . "`n"
            . "filepath: " . this.filepath . "`n"
            . "x: " . this.x . "`n"
            . "y: " . this.y
    }
}