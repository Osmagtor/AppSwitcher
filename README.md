# App Switcher
An alternative to Window's built-in Task Switcher made entirely with AutoHotkey.

## Shortcuts

| Shortcut                                                                           | Description                                                                                                                                                                                            |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Alt + Tab**                                                                      | Switch between open apps from left to right                                                                                                                                                                               |
| **Alt + Tilde** (or whatever the key above the tab key is in your keyboard layout) | (1) If the main window is not open, switch between windows of the same app; (2) If the main window is open, open the window containing the previews of all the open windows of the same app    |
| **Alt + Esc**                                                                      | (1) If the window with all the previews is not open, close all the windows of the selected app; (2) If the window with all the previews is open, close the selected window of the selected app |
| **Alt + Shift + Tab**                                                              | Switch between open apps from right to left                                                                                                                                                                                                       |

## Themes
App Switcher has three built-in GUI themes: Light mode, Dark mode, and System Default. System Default changes between the Light and Dark modes based on Windows' theme. The selection outlines that surround the icons and the preview windows are coloured based on Windows' palette of theme colours. A lighter colour is selected for dark mode and a darker one for light mode.

![App Switcher in Dark Mode](https://github.com/Osmagtor/AppSwitcher/blob/main/Pasted%20image%2020230822165949.png)

![App Switcher in Light Mode](https://github.com/Osmagtor/AppSwitcher/blob/main/Pasted%20image%2020230822170042.png)

## Known limitations
- In its current form, App Switcher can only load the icons of UWP apps when at least one window of an UWP app is not minimized. Otherwise, the UI defaults to a generic Windows icon. All icons are retrieved directly from the ".exe" file of each program. However, all UWP apps are displayed through the same icon-less "ApplicationFrameHost" file. The only workaround I have successfully been able to implement involves retrieving the true process path of a UWP app from the "Windows.UI.Core.CoreWindow1" control that makes up the title bar of any UWP app. From there, the string containing the process path is parsed to find the app's manifest, which is loop read to find the path to the app's icon. Unfortunately, the "Windows.UI.Core.CoreWindow1" controls in UWP apps that allow for this are completely inaccessible when the window is minimized.
- Some programs that open their own windows explorer windows (i.e., [Flow Launcher](https://www.flowlauncher.com/)), do so under a different process ID than that of windows explorer. As a result, App Switcher considers those windows to belong to a different program.
- Some programs encompass multiple .exe files with the same icon. The main window in [VirtualBox](https://www.virtualbox.org/), for instance, runs off one ".exe" file while the virtual boxes themselves run off a separate ".exe" file with a separate corresponding process ID. As a result, App Switcher considers each window to belong to a different program.
