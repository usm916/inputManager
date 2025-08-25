; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
; General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program. If not, see <https://www.gnu.org/licenses/>.

#InputLevel 1  ; catch input from SendLevel 1
#SingleInstance Force
; for connected displays
CoordMode Mouse, Screen
CoordMode ToolTip, Screen

; modify these constants to change behaviour of script
; slow scroll: sleep > 1 ms, from start position to SLOW_SCROLL_DISTANCE
; fast scroll: sleep < 1 ms, SLOW_SCROLL_DISTANCE and above
SYMBOL := Chr(10021) ; html code for four direction arrow symbol
FAST_SCROLL_SPEED := 180 ; higher values will increase fast scroll speed
SLOW_SCROLL_DISTANCE := 70 ; distance until fast scroll starts
SLOW_SCROLL_SLEEP := 60 ; higher values will decrease slow scroll speed
SCROLL_AMOUNT := 1 ; slow and fast scroll delta (int, > 0)
END_SCROLL_RANGE := 450 ; end of scroll range, affects fast scroll
INITIAL_POSITION := 10 ; initial scroll and tooltip position

global isScrolling := False
global hasScrollingStarted := False

convertRange(value, min1, max1, min2, max2) {
    ; linear conversion of an input value
    Return ((value - min1) / (max1 - min1)) * (max2 - min2) + min2
}

cancelScroll(vscode:= True) {
    isScrolling := False
    hasScrollingStarted := False
    ToolTip
    ; the code below is to fix a bug with vscode smooth scrolling
    ; without it, when you stop scrolling, the next 4 mouse wheel
    ; scrolls won't use smooth scroll
    ; this code simulates 4 small scrolls quickly so it's not noticable
    ; there also needs to be a sleep between scrolls or it won't work
    ; if you don't use vscode smooth scroll, remove the next 7 lines
    If (vscode) {
        MouseGetPos x, y
        Loop 4 {
            Sleep 1
            PostMessage 0x20A, 1 << 16, y << 16 | x, , A
        }
    }
}

; 対象アプリ判定用関数
IsTargetApp() {
    WinGet, winExe, ProcessName, A
    return winExe ~= "^(Code\.exe|devenv\.exe|explorer\.exe|notepad\.exe)$"
}

IsVisualStudio() {
    WinGet, winExe, ProcessName, A
    return (winExe = "devenv.exe")
}

#If IsTargetApp()
    MButton::
        hasScrollingStarted := False
        If (A_Cursor = "IBeam") {
            MouseGetPos x1, y1
            ToolTip %SYMBOL%, x1 - INITIAL_POSITION, y1 - INITIAL_POSITION
            sleepCount := 0
            isScrolling := True
            While (isScrolling) {
                If !IsTargetApp() {
                    cancelScroll(False)
                    Break
                }
                MouseGetPos x2, y2
                direction := 0
                scrollDistance := 0
                If (GetKeyState("Shift")) {
                    direction := 0x20E
                    scrollDistance := x2 - x1 + INITIAL_POSITION
                } Else {
                    direction := 0x20A
                    scrollDistance := y2 - y1 + INITIAL_POSITION
                }
                delta := SCROLL_AMOUNT
                If (direction = 0x20A) {
                    If (scrollDistance > 0)
                        delta := delta * -1
                } Else If (scrollDistance < 0) {
                    delta := delta * -1
                }

                scrollDistance := Abs(scrollDistance)
                If (scrollDistance > 12) {
                    ; Visual Studioの場合はSendInputで物理ホイールイベント送信
                    if (IsVisualStudio()) {
                        absDelta := Abs(delta)
                        if (direction = 0x20A) {
                            if (delta > 0)
                                Loop, %absDelta%
                                {
                                    SendInput {WheelUp}
                                    Sleep, 25 ; ← Visual Studioだけ遅くする（値はお好みで調整）
                                }
                            else
                                Loop, %absDelta%
                                {
                                    SendInput {WheelDown}
                                    Sleep, 25
                                }
                        } else {
                            if (delta > 0)
                                Loop, %absDelta%
                                {
                                    SendInput {WheelLeft}
                                    Sleep, 30
                                }
                            else
                                Loop, %absDelta%
                                {
                                    SendInput {WheelRight}
                                    Sleep, 30
                                }
                        }
                    } else {
                        PostMessage direction, delta << 16, y2 << 16 | x2, , A
                    }
                    hasScrollingStarted := True

                    If (scrollDistance < SLOW_SCROLL_DISTANCE) {
                        sleepTime := convertRange(scrollDistance, 12, SLOW_SCROLL_DISTANCE, SLOW_SCROLL_SLEEP, 1)
                        Sleep sleepTime
                    } Else {
                        sleepCycle := convertRange(scrollDistance, SLOW_SCROLL_DISTANCE, END_SCROLL_RANGE - SLOW_SCROLL_DISTANCE, 1, FAST_SCROLL_SPEED)
                        If (++sleepCount > sleepCycle) {
                            sleepCount := 0
                            Sleep 1
                        }
                    }
                }
            }
        } Else {
            SendInput {MButton}
        }
    Return

    MButton Up::
        If (hasScrollingStarted) {
            cancelScroll()
        } Else {
            hasScrollingStarted := True
        }
    Return

    ~Lbutton::
    ~Rbutton::
    ~Alt::
        If (isScrolling) {
            cancelScroll()
        }
    Return
#If