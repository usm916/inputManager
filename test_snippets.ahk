#SingleInstance Force
Process, Priority, , High

; ==== Config ====
REQUIRED_COUNT := 3      ; consecutive presses required
TIMEOUT_MS     := 500    ; max interval (ms) between presses
MIN_VALUE      := 0
MAX_VALUE      := 9
POPUP_MS       := 2000

; ==== State ====
global CurrentValue := 0
global LastPopupGuiName := ""
global ItemLabels := {}          ; index -> tray caption
global LastSeqKey := ""          ; last digit pressed
global PressCount := 0           ; consecutive count
global LastPressTick := 0        ; last press time (ms)

; ==== Tray ====
InitTray() {
    global MIN_VALUE, MAX_VALUE, ItemLabels
    Menu, Tray, NoStandard
    Menu, Tray, Add, Show current value, TrayShowValue
    Menu, Tray, Add
    Loop, % MAX_VALUE - MIN_VALUE + 1 {
        idx := MIN_VALUE + A_Index - 1
        lbl := "Set value to " idx
        ItemLabels[idx] := lbl
        Menu, Tray, Add, % lbl, TraySetValue
    }
    Menu, Tray, Add
    Menu, Tray, Add, Exit, TrayExit
    UpdateTray()
}
UpdateTray() {
    global CurrentValue, MIN_VALUE, MAX_VALUE, ItemLabels
    Menu, Tray, Tip, % "Current value: " CurrentValue
    Loop, % MAX_VALUE - MIN_VALUE + 1 {
        idx := MIN_VALUE + A_Index - 1
        if (ItemLabels.HasKey(idx))
            Menu, Tray, Uncheck, % ItemLabels[idx]
    }
    if (ItemLabels.HasKey(CurrentValue))
        Menu, Tray, Check, % ItemLabels[CurrentValue]
}
TrayShowValue:
    ShowPopup("Current value: " . CurrentValue, POPUP_MS)
return
TraySetValue:
    item := A_ThisMenuItem
    global ItemLabels
    for k, v in ItemLabels {
        if (v = item) {
            SetValue(k + 0)
            break
        }
    }
return
TrayExit:
    ExitApp

; ==== Core: 3x consecutive Shift+Alt+digit ====
HandleSeqDigit(digit) {
    global REQUIRED_COUNT, TIMEOUT_MS
    global LastSeqKey, PressCount, LastPressTick
    now := A_TickCount

    if (LastSeqKey != digit || (now - LastPressTick) > TIMEOUT_MS) {
        LastSeqKey := digit
        PressCount := 1
    } else {
        PressCount++
    }
    LastPressTick := now

    if (PressCount >= REQUIRED_COUNT) {
        PressCount := 0
        LastSeqKey := ""
        SetValue(digit + 0)
    }
}

; Hotkeys: Shift+Alt+0..9 (trigger sequence handler)
+!0::HandleSeqDigit("0")
+!1::HandleSeqDigit("1")
+!2::HandleSeqDigit("2")
+!3::HandleSeqDigit("3")
+!4::HandleSeqDigit("4")
+!5::HandleSeqDigit("5")
+!6::HandleSeqDigit("6")
+!7::HandleSeqDigit("7")
+!8::HandleSeqDigit("8")
+!9::HandleSeqDigit("9")

; ==== Value logic ====
SetValue(v) {
    global CurrentValue, POPUP_MS
    if (v < 0)
        return
    if (v = CurrentValue) {
        ShowPopup("Current value: " . CurrentValue, POPUP_MS)  ; optional feedback
        UpdateTray()
        return
    }
    CurrentValue := v
    ShowPopup("Switched to: " . CurrentValue, POPUP_MS)
    UpdateTray()
}

; ==== Popup (black bg, white text) ====
ShowPopup(msg, ms:=2000) {
    global LastPopupGuiName
    Gui, ModePopup: Destroy
    Gui, ModePopup: New, +AlwaysOnTop -Caption +ToolWindow
    Gui, ModePopup: Color, 000000
    Gui, ModePopup: Font, s16 Bold, Segoe UI cFFFFFF
    Gui, ModePopup: Add, Text, Center w360 h120 cFFFFFF BackgroundTrans, %msg%
    SysGet, sw, 0
    SysGet, sh, 1
    x := (sw - 360) / 2
    y := (sh - 120) / 2
    Gui, ModePopup: Show, x%x% y%y% w360 h120, ModePopup
    LastPopupGuiName := "ModePopup"
    SetTimer, ClosePopup, % -ms
}
ClosePopup:
    global LastPopupGuiName
    if (LastPopupGuiName != "") {
        Gui, %LastPopupGuiName%: Destroy
        LastPopupGuiName := ""
    }
return

; ==== Init / Cleanup ====
InitTray()
OnExit, __cleanup
return
__cleanup:
    Gui, ModePopup: Destroy
    ExitApp
