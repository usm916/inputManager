; ================================
; Minimal & robust remaps (AHK v1) + Mode system
; - Mode 0: swap Win <-> Ctrl (enabled)
; - Mode 1: swap disabled (pass-through)
; - Modes 2..5: same as Mode 0 for now (reserved)
; - Shift+Alt+digit (0..5): switch mode on 3 consecutive presses within 500ms
; - 2s popup on switch, tray shows current mode
; - IME mappings, Middle/Shift+Middle split, Ctrl+digits -> Numpad (scancode)
; ================================

SendLevel 1
#SingleInstance Force
#InstallKeybdHook
#UseHook
SendMode, Event
SetKeyDelay, 5, 5
#MenuMaskKey, vk07
Process, Priority, , High

; ================= Mode / Tray / Popup =================
; --- config ---
REQUIRED_COUNT := 3
TIMEOUT_MS     := 500
POPUP_MS       := 2000

; --- state ---
global CurrentMode := 0
global LastSeqKey := ""
global PressCount := 0
global LastPressTick := 0
global LastPopupGuiName := ""
global ModeLabels := {0:"::Apple mode"
                    , 1:"::Win mode"
                    , 2:"Mode 2"
                    , 3:"Mode 3"
                    , 4:"Mode 4"
                    , 5:"Mode 5"}
global TrayModeItems := {}  ; index -> caption string

; --- tray init ---
InitTray() {
    global ModeLabels, TrayModeItems, CurrentMode
    Menu, Tray, NoStandard
    Menu, Tray, Add, Show current mode, TrayShowMode
    Menu, Tray, Add
    ; build mode items 0..5
    Loop, 6 {
        idx := A_Index - 1
        cap := "Set " ModeLabels[idx]
        TrayModeItems[idx] := cap
        Menu, Tray, Add, % cap, TraySetMode
    }
    Menu, Tray, Add
    Menu, Tray, Add, Exit, TrayExit
    UpdateTray()
}
UpdateTray() {
    global ModeLabels, TrayModeItems, CurrentMode
    Menu, Tray, Tip, % "Cur " ModeLabels[CurrentMode]
    ; uncheck all then check current
    Loop, 6 {
        idx := A_Index - 1
        if (TrayModeItems.HasKey(idx))
            Menu, Tray, Uncheck, % TrayModeItems[idx]
    }
    if (TrayModeItems.HasKey(CurrentMode))
        Menu, Tray, Check, % TrayModeItems[CurrentMode]
}
TrayShowMode:
    ShowPopup(">> " . ModeLabels[CurrentMode], POPUP_MS)
return
TraySetMode:
    item := A_ThisMenuItem
    global TrayModeItems
    for k, v in TrayModeItems {
        if (v = item) {
            SetMode(k + 0)
            break
        }
    }
return
TrayExit:
    ExitApp

; --- mode switch core: Shift+Alt+digit pressed 3x within TIMEOUT_MS ---
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
        SetMode(digit + 0)
    }
}

; --- set mode ---
SetMode(m) {
    global CurrentMode, ModeLabels, POPUP_MS
    if (m < 0 || m > 5)
        return
    if (m = CurrentMode) {
        ShowPopup("Current: " . ModeLabels[CurrentMode], POPUP_MS)
        UpdateTray()
        return
    }
    CurrentMode := m
    ShowPopup("Switched to: " . ModeLabels[CurrentMode], POPUP_MS)
    UpdateTray()
}

; --- helper for #If expression: swap enabled? ---
ModeSwapEnabled() {
    global CurrentMode
    ; Mode 1 disables swap; others enable it
    return (CurrentMode != 1)
}

; --- popup (centered, dark) ---
ShowPopup(msg, ms:=2000) {
    global LastPopupGuiName
    Gui, ModePopup: Destroy
    Gui, ModePopup: New, +AlwaysOnTop -Caption +ToolWindow
    Gui, ModePopup: Color, 000000
    Gui, ModePopup: Font, s16 Bold, Segoe UI cFFFFFF
    Gui, ModePopup: Add, Text, Center w420 h130 cFFFFFF BackgroundTrans, %msg%
    SysGet, sw, 0
    SysGet, sh, 1
    x := (sw - 420) / 2
    y := (sh - 130) / 2
    Gui, ModePopup: Show, x%x% y%y% w420 h130, ModePopup
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

; --- hotkeys for sequence (Shift+Alt+0..5) ---
+!0::HandleSeqDigit("0")
+!1::HandleSeqDigit("1")
+!2::HandleSeqDigit("2")
+!3::HandleSeqDigit("3")
+!4::HandleSeqDigit("4")
+!5::HandleSeqDigit("5")

; ================= Other mappings =================

$*RAlt::       SendEvent {Blind}{Delete down}
$*RAlt up::    SendEvent {Blind}{Delete up}

; ---------- Swap Win <-> Ctrl (enabled only when ModeSwapEnabled()=true) ----------
#If ModeSwapEnabled()
$*LWin::        SendEvent {Blind}{LCtrl down}
$*LWin up::     SendEvent {Blind}{LCtrl up}
$*LCtrl::       SendEvent {Blind}{LWin down}
$*LCtrl up::    SendEvent {Blind}{LWin up}

$*RWin::        SendEvent {Blind}{RCtrl down}
$*RWin up::     SendEvent {Blind}{RCtrl up}
$*RCtrl::       SendEvent {Blind}{Delete down}
$*RCtrl up::    SendEvent {Blind}{Delete up}

+`::SendEvent, ~
#If  ; end conditional hotkeys

; ============ Middle / Shift+Middle ===============
*$MButton::             SendEvent {MButton down}
*$MButton up::          SendEvent {MButton up}
+*$MButton::            SendEvent +{MButton down}
+*$MButton up::         SendEvent +{MButton up}

*XButton2::             SendEvent {MButton down}
*XButton2 up::          SendEvent {MButton up}
+*XButton2::            SendEvent +{MButton down}
+*XButton2 up::         SendEvent +{MButton up}

; ================= IME mappings ===================
$`::            SendEvent {vk19}    ; IME toggle
$!`::           SendEvent {vk1C}    ; Convert
$+`::           SendEvent {vk1D}    ; NonConvert
; If needed, try vkF3/vkF4 depending on your IME.
F16::      SendEvent {vk19}
^F16::SendEvent, ~
+!'::SendEvent, ``

; ===== Numpad via scancode (down -> 5ms -> up) =====
SendNumSC_Delay(key) {
    state := GetKeyState("NumLock", "T")
    if (!state)
        SetNumLockState, On
    if (key = "0")
        sc := "052"
    else if (key = "1")
        sc := "04F"
    else if (key = "2")
        sc := "050"
    else if (key = "3")
        sc := "051"
    else if (key = "4")
        sc := "04B"
    else if (key = "5")
        sc := "04C"
    else if (key = "6")
        sc := "04D"
    else if (key = "7")
        sc := "047"
    else if (key = "8")
        sc := "048"
    else if (key = "9")
        sc := "049"
    else if (key = "Dot")
        sc := "053"
    SendInput {sc%sc% down}
    Sleep, 5
    SendInput {sc%sc% up}
    if (!state)
        SetNumLockState, Off
}

^0::SendNumSC_Delay("0")
^1::SendNumSC_Delay("1")
^2::SendNumSC_Delay("2")
^3::SendNumSC_Delay("3")
^4::SendNumSC_Delay("4")
^5::SendNumSC_Delay("5")
^6::SendNumSC_Delay("6")
^7::SendNumSC_Delay("7")
^8::SendNumSC_Delay("8")
^9::SendNumSC_Delay("9")
^.::SendNumSC_Delay("Dot")
return

; ============== Init / Cleanup ===================
InitTray()

OnExit, _cleanup
return
_cleanup:
SendEvent {Shift up}{Ctrl up}{Alt up}{LWin up}{RWin up}
ExitApp
