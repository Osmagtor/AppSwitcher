#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Libraries\simple-http.ahk
#Include Libraries\JSON.ahk

global MainWindow

/**
 * Method to render a fade-in animation for the window of a given handle
 * @param {number} hWnd 
 * @param {number} Duration 
 * @param {number} Flag 
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
    }
    Else ; Windows 11
    {
        WindowsVersionVariables["Gap"] := 15
    }
}

/**
 * Method to check for updates
 */
checkUpdates() {
    updateAvailable := false

    try {

        website := 'https://api.github.com/repos/Osmagtor/AppSwitcher/releases/latest'

        http := SimpleHTTP()
        content := http.get(website)
        parsed := JSON.parse(content)

        version := parsed["tag_name"]

        if (SubStr(version, 1, 1) = "v") {
            version := SubStr(version, 2)

            if (VerCompare(version, "7.1.5") > 0) {
                updateAvailable := true
            }
        }
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
            update.Destroy()
        }
    }
}

/**
 * Method to prepare the app's menus in the tray icon
 */
initializeMenus() {
    A_TrayMenu.Add("Reload", Restart)
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
    ModifierKeySubMenu := Menu()
    ModifierKeySubMenu.Add("Alt", Alt)
    ModifierKeySubMenu.Add("Control", Control)
    A_TrayMenu.Add("Set modifier key", ModifierKeySubMenu)
    A_TrayMenu.Add() ; separator
    CloseKeySubMenu := Menu()
    CloseKeySubMenu.Add("Esc", Esc)
    CloseKeySubMenu.Add("Q", Q)
    A_TrayMenu.Add("Set close key", CloseKeySubMenu)
    A_TrayMenu.Add() ; separator
    SameWindowKeySubMenu := Menu()
    SameWindowKeySubMenu.Add("Tilde", Tilde)
    SameWindowKeySubMenu.Add("Esc", Esc2)
    A_TrayMenu.Add("Set same window key", SameWindowKeySubMenu)
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

    try {
        ModifierValue := IniRead("settings.ini", "behaviour", "modifier")
        If (ModifierValue = "control")
        {
            ThemeValueVariables["Modifier"] := "control"
            ModifierKeySubMenu.Uncheck("Alt")
            ModifierKeySubMenu.Check("Control")
        }
        Else if (ModifierValue = "alt")
        {
            ThemeValueVariables["Modifier"] := "alt"
            ModifierKeySubMenu.Uncheck("Control")
            ModifierKeySubMenu.Check("Alt")
        }
    } catch {
        ThemeValueVariables["Modifier"] := "control"
        ModifierKeySubMenu.Uncheck("Control")
        ModifierKeySubMenu.Check("Alt")
        IniWrite("alt", "settings.ini", "behaviour", "modifier")
    }

    try {
        CloseKey := IniRead("settings.ini", "behaviour", "close")
        If (CloseKey = "esc")
        {
            ThemeValueVariables["Close"] := "esc"
            CloseKeySubMenu.Uncheck("Q")
            CloseKeySubMenu.Check("Esc")
        }
        Else if (CloseKey = "q")
        {
            ThemeValueVariables["Close"] := "q"
            CloseKeySubMenu.Uncheck("Esc")
            CloseKeySubMenu.Check("Q")
        }
    } catch {
        ThemeValueVariables["Close"] := "esc"
        CloseKeySubMenu.Uncheck("Q")
        CloseKeySubMenu.Check("Esc")
        IniWrite("esc", "settings.ini", "behaviour", "close")
    }

    try {
        SameWindowKey := IniRead("settings.ini", "behaviour", "same_window")
        If (SameWindowKey = "tilde")
        {
            ThemeValueVariables["SameWindow"] := "tilde"
            SameWindowKeySubMenu.Uncheck("Esc")
            SameWindowKeySubMenu.Check("Tilde")
        }
        Else if (SameWindowKey = "esc")
        {
            ThemeValueVariables["SameWindow"] := "esc"
            SameWindowKeySubMenu.Uncheck("Tilde")
            SameWindowKeySubMenu.Check("Esc")
        }
    } catch {
        ThemeValueVariables["SameWindow"] := "tilde"
        SameWindowKeySubMenu.Uncheck("Esc")
        SameWindowKeySubMenu.Check("Tilde")
        IniWrite("tilde", "settings.ini", "behaviour", "same_window")
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

    Control(*)
    {
        ModifierKeySubMenu.UnCheck("Alt")
        ModifierKeySubMenu.Check("Control")

        IniWrite("control", "settings.ini", "behaviour", "modifier")

        ThemeValueVariables["Modifier"] := "control"
        Return
    }

    Alt(*)
    {
        ModifierKeySubMenu.UnCheck("Control")
        ModifierKeySubMenu.Check("Alt")

        IniWrite("alt", "settings.ini", "behaviour", "modifier")

        ThemeValueVariables["Modifier"] := "alt"
        Return
    }

    Esc(*)
    {
        CloseKeySubMenu.UnCheck("Q")
        CloseKeySubMenu.Check("Esc")

        IniWrite("esc", "settings.ini", "behaviour", "close")

        ThemeValueVariables["Close"] := "esc"
        Return
    }

    Q(*)
    {
        CloseKeySubMenu.UnCheck("Esc")
        CloseKeySubMenu.Check("Q")

        IniWrite("q", "settings.ini", "behaviour", "close")

        ThemeValueVariables["Close"] := "q"
        Return
    }

    Tilde(*)
    {
        SameWindowKeySubMenu.UnCheck("Esc")
        SameWindowKeySubMenu.Check("Tilde")

        IniWrite("tilde", "settings.ini", "behaviour", "same_window")

        ThemeValueVariables["SameWindow"] := "tilde"
        Return
    }

    Esc2(*)
    {
        SameWindowKeySubMenu.UnCheck("Tilde")
        SameWindowKeySubMenu.Check("Esc")

        IniWrite("esc", "settings.ini", "behaviour", "same_window")

        ThemeValueVariables["SameWindow"] := "esc"
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
        AboutGui.Add("Text", "x30 y10", "Version 7.2.0")
        AboutGui.Add("Text", "x10 y+m", "Óscar Maganto Torres")
        AboutGui.Add("Button", "x36 y+m", "Github").OnEvent("Click", OpenGithub)
        AboutGui.Show()
        Return
    }

    Restart(*)
    {
        Reload()
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
 * @param {Error} error The message to display
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

        ; "16" corresponds to the "WM_CLOSE" message and "1" to the "WM_CREATE" message

        if (wParam = 16 OR wParam = 1)
        {
            if (WinGetProcessPath("ahk_id" lParam) != A_ScriptFullPath) {
                if (MainWindow) {
                    MainWindow.__Delete()
                    MainWindow := ""
                    PreviewsWindow := ""
                }
            }
        }
    }
}