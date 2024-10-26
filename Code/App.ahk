#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Functions.ahk
#Include Classes/Icon.ahk
#Include Classes/Badge.ahk
#Include Windows/Main.ahk
#Include Classes/Window.ahk
#Include Windows/Outline.ahk
#Include Windows/PreviewOutline.ahk
#Include Windows/PreviewMain.ahk
#Include Classes/Preview.ahk
#Include NoWindowsError.ahk
#Include RunAsTask.ahk
ProcessSetPriority "A"
DetectHiddenWindows False ; This way I can more easily discard a good deal of invisible and title-less windows
InstallKeybdHook ; This is necessary to detect the system messages that the "NotActive" function relies on
SetWinDelay -1
SetControlDelay -1
SetKeyDelay -1

StartupComplete := false

RunAsTask()
;checkUpdates()
initializeMenus()
startupChecks()

; Global variables

/*
It is worth pointing out that these variables are only global so they can be accessed
from all the different hotkeys. They are never called from any other script
*/
global MainWindow := ""
global PreviewsWindow := ""

MonitorGet(MonitorGetPrimary(), &FullMonitorSizeLeft, , &FullMonitorSizeRight,) ; "1" for the primary monitor
MonitorGetWorkArea(MonitorGetPrimary(), &RealMonitorSizeLeft, , &RealMonitorSizeRight,) ; "1" for the primary monitor

TaskbarLeft := Abs(RealMonitorSizeLeft) - Abs(FullMonitorSizeLeft)
TaskbarRight := Abs(RealMonitorSizeRight) - Abs(FullMonitorSizeRight)
isPreviewsWindowOpen := false

StartupComplete := true

; Shortcuts

#HotIf StartupComplete AND ThemeValueVariables["Modifier"] = "alt"
!Tab:: {
    altTab()
}
!+Tab:: {
    altShiftTab()
}
!SC029:: {
    altTilde()
}
!+SC029:: {
    altShiftTilde()
}
!Esc:: {
    altEscape()
}
#HotIf StartupComplete AND ThemeValueVariables["Modifier"] = "control"
^Tab:: {
    altTab()
}
^+Tab:: {
    altShiftTab()
}
^SC029:: {
    altTilde()
}
^+SC029:: {
    altShiftTilde()
}
^Esc:: {
    altEscape()
}

#HotIf (MainWindow AND MainWindow.windowsArray.Length > 0) AND StartupComplete AND ThemeValueVariables["Modifier"] = "alt"
LAlt Up:: {
    altUp()
}
#HotIf (MainWindow AND MainWindow.windowsArray.Length > 0) AND StartupComplete AND ThemeValueVariables["Modifier"] = "control"
LControl Up:: {
    altUp()
}

; Shortcut functions

altTab() {
    global MainWindow
    global PreviewsWindow

    try {
        If (!MainWindow) {
            try {
                ; The user can be very quick to release the "Alt" key, triggering the "LAlt Up" hotkey and interrupting the normal creation of the App Switcher windows.
                ;The solution is to suspend all hotkeys until the App Switcher windows have been created, check whether "LAlt" is still held down and then act accordingly.

                Suspend(true)
                MainWindow := Main()
                Suspend(false)

                if (ThemeValueVariables["Modifier"] = "alt" ? !GetKeyState("LAlt") : !GetKeyState("LControl")) {
                    WinActivate("ahk_id" MainWindow.windowsArray[MainWindow.outline.tabCounter].windowID)
                }
            } catch NoWindowsError {
                MainWindow := ""
            }
        } else {
            if (MainWindow.windowsArray.Length > 0) {
                if (PreviewsWindow) {
                    PreviewsWindow.__Delete()
                    PreviewsWindow := ""
                }

                MainWindow.outline.move(true)
            }
        }
    } catch Error as err {
        showErrorTooltip(err)
    }
}

altShiftTab() {
    global MainWindow
    global PreviewsWindow

    try {
        If (!MainWindow) {
            try {
                ; The user can be very quick to release the "Alt" key, triggering the "LAlt Up" hotkey and interrupting the normal creation of the App Switcher windows.
                ;The solution is to suspend all hotkeys until the App Switcher windows have been created, check whether "LAlt" is still held down and then act accordingly.

                Suspend(true)
                MainWindow := Main(1000) ; "1000" just so that it will start at the end of the list
                Suspend(false)

                if (ThemeValueVariables["Modifier"] = "alt" ? !GetKeyState("LAlt") : !GetKeyState("LControl")) {
                    WinActivate("ahk_id" MainWindow.windowsArray[MainWindow.outline.tabCounter].windowID)
                }
            } catch NoWindowsError {
                MainWindow := ""
            }
        } else {
            if (MainWindow.windowsArray.Length > 0) {
                if (PreviewsWindow) {
                    PreviewsWindow.__Delete()
                    PreviewsWindow := ""
                }

                MainWindow.outline.move(false)
            }
        }
    } catch Error as err {
        showErrorTooltip(err)
    }
}

altTilde() {
    global MainWindow
    global PreviewsWindow

    try {
        If !MainWindow AND !PreviewsWindow {
            Window.AlternateWindows()
        } else if MainWindow AND !PreviewsWindow {
            try {
                PreviewsWindow := PreviewsMain(MainWindow, MainWindow.outline.window, TaskbarLeft, TaskbarRight)
            } catch NoWindowsError {
                PreviewsWindow := ""
            }
        } else if MainWindow AND PreviewsWindow {
            PreviewsWindow.outline.draw(true)
        }
    } catch Error as err {
        showErrorTooltip(err)
    }
}

altShiftTilde() {
    global MainWindow
    global PreviewsWindow

    try {
        if MainWindow AND PreviewsWindow {
            PreviewsWindow.outline.draw(false)
        }
    } catch Error as err {
        showErrorTooltip(err)
    }
}

altUp() {
    global MainWindow
    global PreviewsWindow

    try {
        If PreviewsWindow
        {
            try
            {
                WinActivate("ahk_id" PreviewsWindow.outline.getWindow().windowID)

                MainWindow.__Delete()
                MainWindow := ""
                PreviewsWindow := ""
            }
        }
        Else
        {
            try
            {
                WinActivate("ahk_id" MainWindow.outline.window.windowID)

                MainWindow.__Delete()
                MainWindow := ""
                PreviewsWindow := ""
            }
        }
    } catch Error as err {
        showErrorTooltip(err)
    }
}

altEscape() {
    global MainWindow
    global PreviewsWindow
    global isPreviewsWindowOpen

    try {
        If MainWindow AND !PreviewsWindow
        {
            tempTabCounter := MainWindow.outline.tabCounter

            for i in MainWindow.outline.window.windowSubWindows
            {
                try {
                    WinClose("ahk_id" i.windowID)
                }
            }

            MainWindow.__Delete()

            try {
                MainWindow := Main(tempTabCounter)
            } catch NoWindowsError {
                MainWindow := ""
            }
        }
        Else if MainWindow AND PreviewsWindow
        {
            isPreviewsWindowOpen := true
            tempTabCounter := MainWindow.outline.tabCounter
            tempPreviewCounter := PreviewsWindow.outline.previewCounter

            WinActivate("ahk_id" MainWindow.gui.hwnd)
            WinClose("ahk_id" PreviewsWindow.outline.getWindow().windowID)

            MainWindow.__Delete()

            try {
                MainWindow := Main(tempTabCounter)
            } catch NoWindowsError {
                MainWindow := ""
            }

            try {
                PreviewsWindow := PreviewsMain(MainWindow, MainWindow.outline.window, TaskbarLeft, TaskbarRight, tempPreviewCounter)
            } catch NoWindowsError {
                PreviewsWindow := ""
            }

            isPreviewsWindowOpen := false
        }

        if (ThemeValueVariables["Modifier"] = "alt" ? !GetKeyState("LAlt") : !GetKeyState("LControl")) {
            WinActivate("ahk_id" MainWindow.windowsArray[MainWindow.outline.tabCounter].windowID)
        }
    } catch Error as err {
        showErrorTooltip(err)
    }
}