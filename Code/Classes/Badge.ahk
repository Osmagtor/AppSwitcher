#Requires AutoHotkey v2.0
#SingleInstance Force

class Badge {
    count := ""
    onTop := ""
    wBadge := (ThemeValueVariables["IconSize"] * 18 / 48)
    wText := (ThemeValueVariables["IconSize"] * 10 / 48)

    ; The AHK control objects of the "Gui" class
    ctrlBadgeOnTop := ""
    ctrlBadgeNumber := ""
    ctrlTextOnTop := ""
    ctrlTextNumber := ""

    ; Text style parameters
    font := "Segoe UI"
    textParam := "s" . this.wText . " q5 w2000"
    textColor := "cffffff BackgroundTrans"

    ; Badge style parameters
    badgeParam := "s" . this.wBadge . " q5"
    badgeOnTopColor := "ca02f2f BackgroundTrans"
    badgeNumberColor := "c000000 BackgroundTrans"

    /**
     * Constructor
     * @param onTop A boolean value to specify whether the window this badge is for is on top of all other windows
     */
    __New(onTop) {
        this.onTop := onTop
    }

    /**
     * Method to draw badges over a window's icon
     * @param gui The object of the "gui" AHK class to draw the badges to
     * @param count The number to display on the badge
     * @param xPos The position on the x-axis of the icon over which the badge will be drawn
     * @param yPos The position on the y-axis of the icon over which the badge will be drawn
     * @param size The size of the icons
     * @param outline "True" if the badge is to be drawn for the "outline" window, otherwise "false"
     */
    draw(gui, count, xPos, yPos, size, outline) {
        this.count := count

        ;MsgBox("x: " . xPos . "`ny: " . yPos . "`nSize: " . size . "`nwBadge: " . this.wBadge . "`nwText: " . this.wText)

        try {
            if (this.onTop OR outline) {

                ; BADGE

                gui.SetFont(this.badgeParam, this.font)
                this.ctrlBadgeOnTop := gui.Add(
                    "Text",
                    "x" . (xPos + size - this.wBadge / 0.68) .
                    " y" . (yPos - this.wBadge / 2.60) . " " . this.badgeOnTopColor,
                    "⚫"
                )

                ; TEXT

                gui.SetFont(this.textParam, this.font)
                this.ctrlTextOnTop := gui.Add(
                    "Text",
                    "x" . (xPos + size - this.wText / 0.55) .
                    " y" . (yPos) . " " . this.textColor,
                    "📌"
                )
            }

            if (this.count > 1 OR outline) {

                ; BADGE

                gui.SetFont(this.badgeParam, this.font)
                this.ctrlBadgeNumber := gui.Add(
                    "Text",
                    "x" . (xPos + size - this.wBadge / 0.68) .
                    " y" . (yPos + size - this.wBadge / 0.67) . " " . this.badgeNumberColor,
                    "⚫"
                )

                ; TEXT

                gui.SetFont(this.textParam, this.font)
                this.ctrlTextNumber := gui.Add(
                    "Text",
                    "x" . (xPos + size - this.wText / (this.count > 9 ? 0.58 : 0.78)) .
                    " y" . (yPos + size - this.wText / 0.52) .
                    " w100" . " " . 
                    this.textColor,
                    this.count
                )
            }
        } catch Error as err {
            showErrorTooltip(err)
        }
    }

    /**
     * Method to update the visibility of the badges and the number count on the bottom badge
     * depending on the information of the object of the "Window" class passed as a parameter
     * @param window An object of the "Window" class passed as a parameter
     */
    update(window) {
        try {
            this.count := window.windowSubWindows.length

            this.ctrlBadgeOnTop.Visible := window.onTop
            this.ctrlTextOnTop.Visible := window.onTop

            this.ctrlBadgeNumber.Visible := window.windowSubWindows.length > 1
            this.ctrlTextNumber.Visible := window.windowSubWindows.length > 1

            this.ctrlTextNumber.Move(
                window.icon.x + window.icon.size - this.wText / (this.count > 9 ? 0.58 : 0.78)
            )

            this.ctrlTextNumber.Value := window.windowSubWindows.Length
        } catch Error as err {
            showErrorTooltip(err)
        }
    }
}