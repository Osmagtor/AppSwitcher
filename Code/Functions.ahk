#Requires AutoHotkey v2.0
#SingleInstance Force

global MainWindow

/**
 * Method to render a drop shadow in the window of a given handle
 * @param gHwnd 
 */
EnableShadow(gHwnd) {
    _MARGINS := Buffer(16)
    NumPut("UInt", 1, _MARGINS, 0)
    NumPut("UInt", 1, _MARGINS, 4)
    NumPut("UInt", 1, _MARGINS, 8)
    NumPut("UInt", 1, _MARGINS, 12)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", gHwnd, "UInt", 2, "Int*", 2, "UInt", 4)
    DllCall("dwmapi\DwmExtendFrameIntoClientArea", "Ptr", gHwnd, "Ptr", _MARGINS)
}

/**
 * Method to render a fade-in animation for the window of a given handle
 * @param hWnd 
 * @param Duration 
 * @param Flag 
 * @returns {Float | Integer | String} 
 */
AnimateWindow(hWnd, Duration, Flag) {
    Return DllCall("AnimateWindow", "UInt", hWnd, "Int", Duration, "UInt", Flag)
}

/**
 * Method to conduct some needed checks on start-up
 */
startupChecks() {
    ;=================================================================================================================
    ; STARTUP CHECKS


    ; This checks on startup that all the files needed are where they are supposed to be

    If !FileExist(A_MyDocuments "\App Switcher\")
    {
        DirCreate A_MyDocuments "\App Switcher\"
    }

    SetWorkingDir A_MyDocuments "\App Switcher\"

    If !FileExist(A_StartMenu "\Programs\Startup\App Switcher.lnk")
        FileCreateShortcut A_WorkingDir "\App Switcher.exe", A_StartMenu "\Programs\Startup\App Switcher.lnk", A_StartMenu "\Programs\Startup\"

    If !FileExist(A_WorkingDir "\App Switcher.exe")
        FileMove A_InitialWorkingDir "\App.Switcher.exe", A_WorkingDir "\App Switcher.exe", 1

    If !FileExist(A_WorkingDir "\Uninstall.exe")
        FileInstall "uninstall.exe", A_WorkingDir "\uninstall.exe", 1

    If !FileExist(A_WorkingDir "\settings.ini")
    {
        FileInstall "settings.ini", A_WorkingDir "\settings.ini", 1
    }


    ; GETTING OS-DEPENDENT VARIABLES READY
    ; These are various variables that control different aspects of the appearance of the application depending on the version of Windows. I used a "map" to bind them all together

    global WindowsVersionVariables := Map()
    If (SubStr(A_OSVersion, 6) < 20000) ; Windows 10
    {
        WindowsVersionVariables["Gap"] := 0
        WindowsVersionVariables["MainOffset"] := 10
    }
    Else ; Windows 11
    {
        WindowsVersionVariables["Gap"] := 15
        WindowsVersionVariables["MainOffset"] := 8
    }
}

/**
 * Method to check for updates
 */
checkUpdates() {
    updateAvailable := false

    ; The links in the array below are changed whenever a new version is released. They contain different version numbers based on the next possible version numbers

    websites := ['https://github.com/Osmagtor/AppSwitcher/releases/tag/v7.1.1', 'https://github.com/Osmagtor/AppSwitcher/releases/tag/v7.2', 'https://github.com/Osmagtor/AppSwitcher/releases/tag/v8']

    ; Then we download each of the websites from the links in the "websites" array above and "loop read" through them to find out if they really exist. If the text "404 "This is not the web page you are looking for"" is found, then there is no update yet on that website. So, we break out of both loops using a simple "goto" and delete all .html files. If it the text is not found, the innermost loop will end normally and "updateAvailable" will change to true, triggering the conditional structure further below

    Loop websites.Length
    {
        Download(websites[A_Index], "test" A_Index ".html")
        loop read "test" A_Index ".html"
        {
            If InStr(A_LoopReadLine, "404 &ldquo;This is not the web page you are looking for&rdquo;")
            {
                ;FileDelete("test.html")
                goto out
            }
        }
        updateAvailable := true
out:
        FileDelete("test" A_Index ".html")
    }


    if (updateAvailable = true)
    {
        update := Gui(, "App Switcher Updater")
        update.Add("Text", , "An update is available for App Switcher. Would you like to install it?")
        update.Add("Button", "x130", "No").OnEvent("Click", close)
        update.Add("Button", "x+m", "Yes").OnEvent("Click", downloadGithub)
        update.Show()
        return

        downloadGithub(*)
        {
            MsgBox "Please make sure that App Switcher is closed before installing a new version"
            Run("https://github.com/Osmagtor/AppSwitcher/releases")
            ProcessClose("App Switcher.exe")
        }

        close(*)
        {
            ExitApp
        }
    }
}

/**
 * Method to prepare the app's menus in the tray icon
 */
initializeMenus() {
    A_TrayMenu.Add() ; separator
    A_TrayMenu.Add("Uninstall", Uninstall)
    A_TrayMenu.Add() ; separator
    AppearanceSubMenu := Menu()
    AppearanceSubMenu.Add("Light", Light)
    AppearanceSubMenu.Add("Dark", Dark)
    AppearanceSubMenu.Add("System Default", SystemDefault)
    A_TrayMenu.Add("Appearance", AppearanceSubMenu)
    A_TrayMenu.Add() ; separator
    AltEscSubMenu := Menu()
    AltEscSubMenu.Add("Close selected window", CloseSelectedWindow)
    AltEscSubMenu.Add("Hide App Switcher", HideAppSwitcher)
    A_TrayMenu.Add("Alt + Escape Behaviour", AltEscSubMenu)
    A_TrayMenu.Add() ; separator
    A_TrayMenu.Add("Set icon size", SetIconSize)
    A_TrayMenu.Add() ; separator
    A_TrayMenu.Add("About", About)

    global ThemeValueVariables := Map()
    global altEsc := ""

    try {
        ThemeValueVariables["IconSize"] := IniRead("settings.ini", "theme", "icon_size")
    } catch {
        ThemeValueVariables["IconSize"] := 48
    }

    try {
        altEsc := IniRead("settings.ini", "behaviour", "alt_esc") = 1 ? true : false

        if (altEsc) {
            AltEscSubMenu.Check("Close selected window")
            AltEscSubMenu.Uncheck("Hide App Switcher")
        } else {
            AltEscSubMenu.Check("Hide App Switcher")
            AltEscSubMenu.Uncheck("Close selected window")
        }
    } catch {
        altEsc := true
        AltEscSubMenu.Check("Hide App Switcher")
        AltEscSubMenu.Uncheck("Close selected window")
    }

    ; The code below checks for any pre-existing theme settings from the user by checking inside the "settings.ini" file that is created when App Switcher is first run
    ; The accent colors are extracted from Windows resgistry files. Fret not, they are only read, not tampered with
    ; And again, all the variables are bound together by means of a "map"

    try {
        ThemeValue := IniRead("settings.ini", "theme", "theme")
        If (ThemeValue = "dark")
        {
            ThemeValueVariables["BackgroundColor"] := "242424"
            ThemeValueVariables["TextColor"] := "ffffff"
            ThemeValueVariables["AccentColor"] := SubStr(RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent", "AccentPalette"), 1, 6)

            AppearanceSubMenu.Check("Dark")
            AppearanceSubMenu.Uncheck("Light")
            AppearanceSubMenu.Uncheck("System Default")
        }
        Else if (ThemeValue = "light")
        {
            ThemeValueVariables["BackgroundColor"] := "ffffff"
            ThemeValueVariables["TextColor"] := "000000"
            ThemeValueVariables["AccentColor"] := SubStr(RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent", "AccentPalette"), 33, 6)

            AppearanceSubMenu.Check("Light")
            AppearanceSubMenu.Uncheck("Dark")
            AppearanceSubMenu.Uncheck("System Default")
        }
        Else if (ThemeValue = "system_default")
        {
            If (RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "SystemUsesLightTheme") = 0)
            {
                ThemeValueVariables["AccentColor"] := SubStr(RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent", "AccentPalette"), 1, 6)
                ThemeValueVariables["BackgroundColor"] := "242424"
                ThemeValueVariables["TextColor"] := "ffffff"
            }
            Else
            {
                ThemeValueVariables["AccentColor"] := SubStr(RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent", "AccentPalette"), 33, 6)
                ThemeValueVariables["BackgroundColor"] := "ffffff"
                ThemeValueVariables["TextColor"] := "000000"
            }
            AppearanceSubMenu.Uncheck("Light")
            AppearanceSubMenu.Uncheck("Dark")
            AppearanceSubMenu.Check("System Default")
        }
    }
    Return

    ; These are the functions that are triggered when clicking on the different options of the tray icon menu

    Light(*) ; Functions must now always have one parameter at the very least. The use of an asterisk is encouraged as a null placeholder
    {
        AppearanceSubMenu.Check("Light")
        AppearanceSubMenu.Uncheck("Dark")
        AppearanceSubMenu.Uncheck("System Default")
        IniWrite("light", "settings.ini", "theme", "theme")

        ThemeValueVariables["AccentColor"] := SubStr(RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent", "AccentPalette"), 33, 6)
        ThemeValueVariables["BackgroundColor"] := "ffffff"
        ThemeValueVariables["TextColor"] := "000000"
        Return
    }

    Dark(*)
    {
        AppearanceSubMenu.UnCheck("Light")
        AppearanceSubMenu.Check("Dark")
        AppearanceSubMenu.Uncheck("System Default")
        IniWrite("dark", "settings.ini", "theme", "theme")

        ThemeValueVariables["AccentColor"] := SubStr(RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent", "AccentPalette"), 1, 6)
        ThemeValueVariables["BackgroundColor"] := "242424"
        ThemeValueVariables["TextColor"] := "ffffff"
        Return
    }

    SystemDefault(*)
    {
        AppearanceSubMenu.Uncheck("Light")
        AppearanceSubMenu.Uncheck("Dark")
        AppearanceSubMenu.Check("System Default")
        IniWrite("system_default", "settings.ini", "theme", "theme")
        If (RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "SystemUsesLightTheme") = 0)
        {
            ThemeValueVariables["AccentColor"] := SubStr(RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent", "AccentPalette"), 1, 6)
            ThemeValueVariables["BackgroundColor"] := "242424"
            ThemeValueVariables["TextColor"] := "ffffff"
        }
        Else
        {
            ThemeValueVariables["AccentColor"] := SubStr(RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent", "AccentPalette"), 33, 6)
            ThemeValueVariables["BackgroundColor"] := "ffffff"
            ThemeValueVariables["TextColor"] := "000000"
        }
        Return
    }

    Uninstall(*)
    {
        Run A_WorkingDir "\uninstall.exe"
        Return
    }

    About(*)
    {
        AboutGui := Gui("+ToolWindow", "About",)
        AboutGui.Add("Text", "x30 y10", "Version 7.1")
        AboutGui.Add("Text", "x10 y+m", "Óscar Maganto Torres")
        AboutGui.Add("Button", "x36 y+m", "Github").OnEvent("Click", OpenGithub)
        AboutGui.Show()
        Return
    }

    OpenGithub(*)
    {
        Run "https://github.com/Osmagtor/AppSwitcher"
    }

    SetIconSize(*)
    {
        IconGui := Gui("+ToolWindow", "Set icon size",)
        IconGui.Add("Text", "y10", "Introduce the size you would like the icons to have (between 48px and 120px)")
        IconGui.Add("Text", "y+m", "Recommended sizes: 96, 80, 72, 64, 60, 48")
        IconGui.Add("Edit", "x130 y+m w120 vEdit", "48")
        IconGui.Add("Button", "x165 y+m", "Confirm").OnEvent("Click", ChangeIconSize)
        IconGui.Show()
        Return
    }

    ChangeIconSize(*)
    {
        if (ControlGetText("Edit1", "Set icon size") >= 48 && ControlGetText("Edit1", "Set icon size") <= 120) {
            try {
                IniWrite(ControlGetText("Edit1", "Set icon size"), "settings.ini", "theme", "icon_size")
                ThemeValueVariables["IconSize"] := ControlGetText("Edit1", "Set icon size")
                WinClose("Set icon size")
            } catch {
                MsgBox("There was an error saving these settings", "Error", 16)
            }
        }
    }

    CloseSelectedWindow(*) {
        try {
            IniWrite(1, "settings.ini", "behaviour", "alt_esc")
        } catch {
            MsgBox("There was an error saving these settings", "Error", 16)
        }

        AltEscSubMenu.Check("Close selected window")
        AltEscSubMenu.Uncheck("Hide App Switcher")
        altEsc := true
    }

    HideAppSwitcher(*) {
        try {
            IniWrite(0, "settings.ini", "behaviour", "alt_esc")
        } catch {
            MsgBox("There was an error saving these settings", "Error", 16)
        }

        AltEscSubMenu.Check("Hide App Switcher")
        AltEscSubMenu.Uncheck("Close selected window")
        altEsc := false
    }
}

/**
 * Method to display a tooltip when a critical error occurs and save it to "errorlog.ini"
 * @param error The message to display
 */
showErrorTooltip(error) {
    ToolTip "Error on line " error.Line " in script `"" error.File "`" by `"" error.What ": " error.Message "`""
    SetTimer () => ToolTip(), -5000

    If !FileExist(A_WorkingDir "\errorlog.ini") {
        FileAppend "", A_WorkingDir "\errorlog.ini"
    }

    IniWrite("Error on line " error.Line " in script `"" error.File "`" by `"" error.What ": " error.Message "`"", "errorlog.ini", A_YYYY "-" A_MM "-" A_DD, A_Hour ":" A_Min ":" A_Sec "." A_MSec)
}

/**
 * Internal method to close the app when another window gains focus
 * @param wParam
 * @param lParam 
 * @param msg 
 * @param hwnd 
 */
FocusLost(wParam, lParam, msg, hwnd) {
    global MainWindow
    global PreviewsWindow

    try {
        if ((WinExist("Super AltTab.ahk") AND (WinGetClass("A") != "AutoHotkeyGUI") AND (isPreviewsWindowOpen = false)))
        {
            if ((wParam = 6) OR (wParam = 32772))
            {
                if (WinExist("Super AltTab.ahk")) {
                    MainWindow.__Delete()
                    MainWindow := ""

                    if (WinExist("Super Previews.ahk")) {
                        PreviewsWindow.__Delete()
                        PreviewsWindow := ""
                    }
                }
            }
        }
    } catch Error as err {
        showErrorTooltip(err)
    }
}