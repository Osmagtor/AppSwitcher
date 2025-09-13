#Requires AutoHotkey v2.0
#SingleInstance Force

class Window {
    windowTitle := ""
    windowClass := ""
    windowID := ""
    windowPID := ""
    windowSubWindows := []
    windowUWP := "" ; true/false
    windowBadge := ""
    windowbadgeOnTop := ""
    onTop := "" ; true/false
    icon := "" ; An object of the "Icon" class
    badge := "" ; An object of the "Badge" class
    w := ""
    h := ""

    /**
     * Constructor
     * @param title The window's title
     * @param class The window's class
     * @param id The window's handle
     * @param pid The window's process ID
     * @param subWindows An array of all other windows with the same PID (for Win32 apps) or title (for UWP apps)
     * @param position The position of the window in the "main" object
     */
    __New(title, class, id, pid, subWindows, position) {
        if (WinExist("ahk_id" id)) {
            try {
                this.windowTitle := title
                this.windowClass := class
                this.windowID := id
                this.windowPID := pid
                this.windowSubWindows := subWindows
                this.windowUWP := class = "ApplicationFrameWindow" ? true : false
                this.onTop := this.isOnTop()
                this.icon := Icon(title, id, class, this.windowUWP, position)
                this.badge := Badge(this.onTop)
                this.localGetDimensions()
            } catch {
                throw NoWindowsError()
            }
        } else {
            throw NoWindowsError()
        }
    }

    /**
     * Method to render a drop shadow in the window of a given handle
     * @param gHwnd 
     */
    static EnableShadow(gHwnd) {
        _MARGINS := Buffer(16)
        NumPut("UInt", 1, _MARGINS, 0)
        NumPut("UInt", 1, _MARGINS, 4)
        NumPut("UInt", 1, _MARGINS, 8)
        NumPut("UInt", 1, _MARGINS, 12)
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", gHwnd, "UInt", 2, "Int*", 2, "UInt", 4)
        DllCall("dwmapi\DwmExtendFrameIntoClientArea", "Ptr", gHwnd, "Ptr", _MARGINS)
    }

    /**
     * Internal method to get the width (i.e., "w") and the height (i.e., "h")
     */
    localGetDimensions() {
        If (WinGetMinMax("ahk_id " this.windowID) = -1)
        {
            wp := Buffer(44)
            NumPut("UPtr", 44, wp)
            DllCall("GetWindowPlacement", "ptr", this.windowID, "ptr", wp)

            If (NumGet(wp, 3, "int") != 0)
            {
                monitorIndex := Window.WinGetMonitorIndex(this.windowID)

                MonitorGetWorkArea monitorIndex, &Left, &Top, &Right, &Bottom
                Width := Right - Left
                Height := Bottom - Top
            }
            else
            {
                Width := NumGet(wp, 36, "int") - NumGet(wp, 28, "int")
                Height := NumGet(wp, 40, "int") - NumGet(wp, 32, "int")
            }
        }
        Else
        {
            WinGetPos , , &Width, &Height, "ahk_id" this.windowID
        }

        this.w := Width
        this.h := Height
    }

    /**
     * Method to retrieve a list of all open windows that the user can interact with
     * @returns {Array} An array with all the objects of the class "Window"
     */
    static WinGetListAlt() {
        try {
            subWindows := []
            validWindows := []

            ; GETTING AN ARRAY (i.e., ValidWindowsList) WITH ALL VALID WINDOWS

            SetTitleMatchMode("RegEx")
            global WindowsList := WinGetList("\w", ,) ;"\w" include anything that has a word (i.e., a title)
            SetTitleMatchMode(3)

            ; CREATING AN ARRAY OF "WINDOW" CLASS OBJECTS FROM THE ARRAY OF VALID WINDOWS (i.e., ValidWindowsList)

            loop WindowsList.Length
            {
                title := WinGetTitle("ahk_id" WindowsList[A_Index])
                class := WinGetClass("ahk_id" WindowsList[A_Index])
                id := WindowsList[A_Index]
                pid := WinGetPID("ahk_id" WindowsList[A_Index])
                found := ""

                If (this.localValidateWindow(title, class)) {
                    for i in validWindows {

                        haystackValue := i.windowUWP ? i.windowTitle : i.windowPID
                        needle := i.windowUWP ? title : pid

                        if (needle = haystackValue) {
                            found := i
                            break
                        }
                    }

                    ; The windowSubWindows array of each window starts with itself, hence why we sent an empty array when creating "createdWindow" in the previous line
                    try {
                        createdWindow := Window(
                            title,
                            class,
                            id,
                            pid,
                            [],
                            found ? validWindows.Length : validWindows.Length + 1
                        )

                        ; Minimized windows have an approximate size of 160×31 pixels
                        ; Thus, this check essentially serves as a general filter to weed out windows that are too small to be considered valid

                        if (createdWindow.w > 10 AND createdWindow.h > 10) {

                            createdWindow.windowSubWindows.Push(createdWindow)

                            if (found) {
                                found.windowSubWindows.Push(createdWindow)
                            } else {
                                validWindows.Push(createdWindow)
                            }
                        }
                    } catch NoWindowsError {
                        ; Nothing. Just catching an error specifically thrown to prevent any rogue windows
                        ; missing some of the required parameters in the constructor from causing any mayhem
                    }
                }
            }

            return validWindows
        } catch Error as err {
            showErrorTooltip(err)
            return []
        }
    }

    /**
     * Method to find out if the window is on top of all other windows
     * @returns {Number} Greater than 0 if it is
     */
    isOnTop() {
        return WinGetExStyle("ahk_id" this.windowID) & 0x8 ; https://www.autohotkey.com/docs/v2/lib/WinGetStyle.htm
    }

    /**
     * Private method that checks if a window is valid (i.e., a desktop app). It does so by contrasting against some window title and class values that are known not to belong to desktop apps
     * @param title The title of the window
     * @param class The class of the window
     * @returns {Boolean} "True" if the window is valid, "false" if not 
     */
    static localValidateWindow(title, class) {
        return (title != "Start" AND class != "Button") AND (title != "Program Manager" AND class != "Progman") AND (title != "Setup" AND class != "TApplication") AND (class != "Windows.UI.Core.CoreWindow" AND title != "Search") AND (title != "PopupHost" AND class != "Xaml_WindowedPopupClass") AND (class != "tooltips_class32") AND (title != "Super AltTab.ahk" AND title != "Super Previews.ahk") AND (title != "Drag Placeholder Window")
    }

    /**
     * Method to switch between windows with the same PID (win32 apps) or title (UWP apps)
     */
    static AlternateWindows() {
        try {
            Class := WinGetClass("A")
            If (Class = "ApplicationFrameWindow")
            {
                Title := WinGetTitle("A")
                If (WinGetCount(Title " ahk_class" Class) > 1)
                {
                    WinMoveBottom("A")
                    WinActivate(Title " ahk_class" Class)
                }
            }
            else
            {
                PID := WinGetPID("A")
                If (WinGetCount("ahk_pid" PID) > 1)
                {
                    WinMoveBottom("A")
                    WinActivate("ahk_pid" PID " ahk_class" Class)
                }
            }
        }
    }

    /**
     * Static method to get the number of the monitor where a window with a given handle is located
     * @param windowID The handle of the window
     * @returns {Integer} The number of the monitor where the window is located
     */
    static WinGetMonitorIndex(windowID) {
        monitorInfo := Buffer(40)
        NumPut("UPtr", 40, monitorInfo)

        monitorIndex := 0

        if (monitorHandle := DllCall("MonitorFromWindow", "uint", windowID, "uint", 0x2)) AND DllCall("GetMonitorInfo", "uint", monitorHandle, "ptr", monitorInfo)
        {
            monitorLeft := NumGet(monitorInfo, 4, "Int")
            monitorTop := NumGet(monitorInfo, 8, "Int")
            monitorRight := NumGet(monitorInfo, 12, "Int")
            monitorBottom := NumGet(monitorInfo, 16, "Int")

            Loop MonitorGetCount()
            {
                MonitorGet(A_Index, &tempMonLeft, &tempMonTop, &tempMonRight, &tempMonBottom)

                ; Compare location to determine the monitor index.
                if ((monitorLeft = tempMonLeft) and (monitorTop = tempMonTop) AND (monitorRight = tempMonRight) and (monitorBottom = tempMonBottom))
                {
                    monitorIndex := A_Index
                    break
                }
            }
        }

        return monitorIndex
    }

    /**
     * Method to turn an object of this class into a string
     * @returns {String} 
     */
    toString() {
        return "title: " . this.windowTitle . "`n"
            . "class: " . this.windowClass . "`n"
            . "id: " . this.windowID . "`n"
            . "pid: " . this.windowPID . "`n"
            . "subWindows: " . this.windowSubWindows.Length . "`n"
            . "uwp: " . this.windowUWP . "`n"
            . "onTop: " . this.onTop . "`n"
            . "icon: " . this.icon.filepath
    }
}