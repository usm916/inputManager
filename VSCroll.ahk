; Catch mapped input from scriptA (which uses SendLevel 1)
#InputLevel 1
#SingleInstance Force
#InstallMouseHook
#UseHook

; for connected displays
CoordMode Mouse, Screen
CoordMode ToolTip, Screen

; constants
SYMBOL := Chr(10021)
FAST_SCROLL_SPEED := 180
SLOW_SCROLL_DISTANCE := 70
SLOW_SCROLL_SLEEP := 60
SCROLL_AMOUNT := 1
END_SCROLL_RANGE := 450
INITIAL_POSITION := 10

global isScrolling := False
global hasScrollingStarted := False

*$MButton::       Gosub, __MB_X2_Down
*$XButton2::      Gosub, __MB_X2_Down
return

*$MButton up::    Gosub, __MB_X2_Up
*$XButton2 up::   Gosub, __MB_X2_Up
return

convertRange(value, min1, max1, min2, max2) {
    ; linear conversion of an input value
    Return ((value - min1) / (max1 - min1)) * (max2 - min2) + min2
}

cancelScroll(vscode:= True) {
    isScrolling := False
    hasScrollingStarted := False
    ToolTip
    if (vscode) {
        MouseGetPos x, y
        Loop 4 {
            Sleep 1
            PostMessage 0x20A, 1 << 16, y << 16 | x, , A
        }
    }
}

; target app detection
IsTargetApp() {
    WinGet, winExe, ProcessName, A
    return winExe ~= "^(Code\.exe|devenv\.exe|explorer\.exe|notepad\.exe)$"
}
IsVisualStudio() {
    WinGet, winExe, ProcessName, A
    return (winExe = "devenv.exe")
}
#IfWinActive ahk_exe blender.exe
*$MButton::             SendEvent {MButton down}
*$MButton up::          SendEvent {MButton up}
+*$MButton::            SendEvent +{MButton down}
+*$MButton up::         SendEvent +{MButton up}

*XButton2::             SendEvent {MButton down}
*XButton2 up::          SendEvent {MButton up}
+*XButton2::            SendEvent +{MButton down}
+*XButton2 up::         SendEvent +{MButton up}
#IfWinActive

#If IsTargetApp()
    ; use $* to avoid recursion and catch with modifiers
    __MB_X2_Down:
        hasScrollingStarted := False
        if (A_Cursor = "IBeam") {
            MouseGetPos x1, y1
            ToolTip %SYMBOL%, x1 - INITIAL_POSITION, y1 - INITIAL_POSITION
            sleepCount := 0
            isScrolling := True
            while (isScrolling) {
                if !IsTargetApp() {
                    cancelScroll(False)
                    break
                }
                MouseGetPos x2, y2
                direction := 0
                scrollDistance := 0
                if (GetKeyState("Shift")) {
                    direction := 0x20E  ; WM_MOUSEHWHEEL
                    scrollDistance := x2 - x1 + INITIAL_POSITION
                } else {
                    direction := 0x20A  ; WM_MOUSEWHEEL
                    scrollDistance := y2 - y1 + INITIAL_POSITION
                }
                delta := SCROLL_AMOUNT
                if (direction = 0x20A) {
                    if (scrollDistance > 0)
                        delta *= -1
                } else if (scrollDistance < 0) {
                    delta *= -1
                }

                scrollDistance := Abs(scrollDistance)
                if (scrollDistance > 12) {
                    if (IsVisualStudio()) {
                        absDelta := Abs(delta)
                        if (direction = 0x20A) {
                            if (delta > 0)
                                Loop, %absDelta% {
                                    SendInput {WheelUp}
                                    Sleep, 25
                                }
                            else
                                Loop, %absDelta% {
                                    SendInput {WheelDown}
                                    Sleep, 25
                                }
                        } else {
                            if (delta > 0)
                                Loop, %absDelta% {
                                    SendInput {WheelLeft}
                                    Sleep, 30
                                }
                            else
                                Loop, %absDelta% {
                                    SendInput {WheelRight}
                                    Sleep, 30
                                }
                        }
                    } else {
                        PostMessage direction, delta << 16, y2 << 16 | x2, , A
                    }
                    hasScrollingStarted := True

                    if (scrollDistance < SLOW_SCROLL_DISTANCE) {
                        sleepTime := convertRange(scrollDistance, 12, SLOW_SCROLL_DISTANCE, SLOW_SCROLL_SLEEP, 1)
                        Sleep sleepTime
                    } else {
                        sleepCycle := convertRange(scrollDistance, SLOW_SCROLL_DISTANCE, END_SCROLL_RANGE - SLOW_SCROLL_DISTANCE, 1, FAST_SCROLL_SPEED)
                        if (++sleepCount > sleepCycle) {
                            sleepCount := 0
                            Sleep 1
                        }
                    }
                }
            }
        } else {
            ; fall back to native middle click without re-triggering this hotkey
            SendInput {MButton down}
            Sleep, 10
            SendInput {MButton up}
        }
    return

    __MB_X2_Up:
        if (hasScrollingStarted) {
            cancelScroll()
        } else {
            hasScrollingStarted := True
        }
    return

    ~LButton::
    ~RButton::
    ~Alt::
        if (isScrolling) {
            cancelScroll()
        }
    return
#If
