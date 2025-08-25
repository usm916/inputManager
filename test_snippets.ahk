#InputLevel 1              ; catch events from SendLevel 0..1
#SingleInstance Force

SendMode, Event
CoordMode, Mouse, Screen

; ===== Config =====
LogFile := A_ScriptDir . "\keylog.txt"
ShowTooltipMs := 800

; ===== Logger =====
LogEvent(event) {
    global LogFile, ShowTooltipMs
    FormatTime, ts,, yyyy-MM-dd HH:mm:ss
    MouseGetPos, mx, my, hwnd, ctrl
    WinGetTitle, title, A
    WinGet, exe, ProcessName, A
    ; compose one line
    line := ts . " [" . A_TickCount . "]  " . event
          . "  exe=" . exe . "  win=" . title
          . "  ctrl=" . ctrl . "  x=" . mx . " y=" . my . "`n"
    FileAppend, %line%, %LogFile%

    ; optional on-screen hint
    ToolTip, % event
    SetTimer, __ClearTip, -%ShowTooltipMs%
}

__ClearTip:
    ToolTip
return

; ===== Hotkeys to log MButton and XButton2 (down/up) =====
$*MButton::
    LogEvent("MButton down")
return

$*MButton up::
    LogEvent("MButton up")
return

$*XButton2::
    LogEvent("XButton2 down")
return

$*XButton2 up::
    LogEvent("XButton2 up")
return

; ===== Utilities =====
; F12 -> open Key History (quick live debug)
F12::
    KeyHistory
return

; Ctrl+Alt+L -> clear log file
^!l::
    FileDelete, %LogFile%
    FileAppend, , %LogFile%
    ToolTip, Log cleared
    SetTimer, __ClearTip, -600
return
