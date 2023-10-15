# App Switcher
A macOS-like alternative to Windows' built-in task switcher made entirely with AutoHotkey. 

It shows icons rather than window previews and it only shows one icon per app irrespective of the number of open windows of each app. Nevertheless, when more than one window of the same app is open, a badge indicating the number of open windows of said app is displayed. If an app has a badge next to it, then you can also get a list of previews like the ones displayed by Windows' default task switcher to hand-pick which window to open. Productivity galore!

![App Switcher Icon](https://github.com/Osmagtor/AppSwitcher/blob/main/Icon.ico)

## How to Install
Download the "App.Switcher.exe" executable from the latest release, double-click it and that's it! Next time you boot up into Windows you should be able to delete the "App.Switcher.exe" file that you downloaded. App Switcher automatically creates a folder called "App Switcher" in "C:\Users\Your Username\Documents\" where the main executable is stored along with some other necessary files. A shortcut to the main executable file is also automatically created in the Startup folder so App Switcher is ready every time you start your computer.

Note that some antivirus programmes may incorrectly detect App Switcher as a virus. The original .ahk scripts that make up App Switcher were compiled using AHK's compiler, which can't doesn't prevent antivirus software from labelling it as malicious software.

## How to Uninstall
To uninstall App Switcher, go to the system tray and right click on App Switcher's icon. Then click on "Uninstall". A pop-up window will appear to ask for confirmation. Once App Switcher is uninstalled, please check "C:\Users\Your Username\Documents\" for residual files.

## Shortcuts

| Shortcut                                                                           | Description                                                                                                                                                                                            |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Alt + Tab**                                                                      | Switches between open apps from left to right                                                                                                                                                                               |
| **Alt + Tilde** (the key above the tab key) | (1) If the main window is not open, switches between windows of the same app; (2) If the main window is open, opens the window containing the previews of all the open windows of the same app; (3) If the window containing the previews of all the open windows of the same app is open, switches between open windows from left to right |
| **Alt + Esc**                                                                      | (1) If the window with all the previews is not open, closes all the windows of the selected app; (2) If the window with all the previews is open, closes the selected window of the selected app |
| **Alt + Shift + Tab**                                                              | Switches between open apps from right to left |
| **Alt + Shift + Tilde** (the key above the tab key)                                | Switches between window previews from right to left |

## Themes
App Switcher has three built-in GUI themes: Light mode, Dark mode, and System Default. System Default changes between the Light and Dark modes based on Windows' theme. The selection outlines that surround the icons and the preview windows are coloured based on Windows' palette of theme colours. A lighter colour is selected for dark mode and a darker one for light mode.

To change themes, go to the system tray and right click on App Switcher's icon. From there, you can click on the "Appearance" submenu and select your theme of choice.

Note that App Switcher only displays rounded corners in Windows 11.

![App Switcher in Dark Mode](https://github.com/Osmagtor/AppSwitcher/blob/main/Pasted%20image%2020230822165949%20-%20Dark.png)

![App Switcher in Light Mode](https://github.com/Osmagtor/AppSwitcher/blob/main/Pasted%20image%2020230822165949%20-%20Light.png)

## Known limitations
- In its current form, App Switcher can only load the icons of UWP apps when at least one window of a UWP app is not minimized. Otherwise, the UI defaults to a generic Windows icon. All icons are retrieved directly from the ".exe" file of each program. However, all UWP apps are displayed through the same icon-less "ApplicationFrameHost" file. The only workaround I have successfully been able to implement involves retrieving the true process path of a UWP app from the "Windows.UI.Core.CoreWindow1" control that makes up the title bar of any UWP app. From there, the string containing the process path is parsed to find the app's manifest, which is loop read to find the path to the app's icon. Unfortunately, the "Windows.UI.Core.CoreWindow1" controls in UWP apps that allow for this are completely inaccessible when the window is minimized. A band-aid solution was implemented in version [7.0.3](https://github.com/Osmagtor/AppSwitcher/releases/tag/v7.0.3). The icon path of UWP apps is stored in App Switcher's "settings.ini" file after a UWP is open for the first time. Thus, App Switcher can always retrieve it whenever that UWP app is open thereafter.
- Some programs that open their own file explorer windows (i.e., [Flow Launcher](https://www.flowlauncher.com/)), do so under a different process ID than that of normally launched file explorer windows. As a result, App Switcher considers those windows to belong to a different program.
- Some programs encompass multiple .exe files with the same icon. The main window in [VirtualBox](https://www.virtualbox.org/), for instance, runs off one ".exe" file while the virtual boxes themselves run off a separate ".exe" file with a separate corresponding process ID. As a result, App Switcher considers each window to belong to a different program.
