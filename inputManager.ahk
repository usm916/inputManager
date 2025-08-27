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
SetKeyDelay, 0, 0
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
                    , 1:"::Windows mode"
                    , 2:"::Mode 2"
                    , 3:"::Mode 3"
                    , 4:"::Mode 4"
                    , 5:"::Mode 5"}
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
    ShowPopup("Profile: " . ModeLabels[CurrentMode], POPUP_MS)
    UpdateTray()
}

; --- helper for #If expression: swap enabled? ---
ModeSwapEnabled() {
    global CurrentMode
    ; Mode 1 disables swap; others enable it
    return (CurrentMode != 1)
}

ShowPopup(msg, ms:=2000) {
    global LastPopupGuiName
    w   := 320          ; window width
    h   := 90          ; window height
    pad := 16           ; inner padding
    innerW := w - 2*pad
    innerH := h - 2*pad

    Gui, ModePopup: Destroy
    Gui, ModePopup: New, +AlwaysOnTop -Caption +ToolWindow
    Gui, ModePopup: Color, 0F0F0F
    ; set font face/size/color before adding controls
    Gui, ModePopup: Font, s16 Bold c0xDDDDDD, Segoe UI

    ; create text and measure height
    Gui, ModePopup: Add, Text, HwndhText Center BackgroundTrans, %msg%
    GuiControlGet, pos, ModePopup: Pos, %hText%
    textH := posH

    ; vertical centering inside padded area
    yText := pad + (innerH - textH) / 2
    if (yText < pad)
        yText := pad

    ; move text to centered position with fixed width
    GuiControl, ModePopup: Move, %hText%, % "x" pad " y" yText " w" innerW " h" textH

    ; center window on screen
    SysGet, sw, 0
    SysGet, sh, 1
    x := (sw - w) / 2
    y := (sh - h) / 2
    Gui, ModePopup: Show, % "x" x " y" y " w" w " h" h, ModePopup

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

$*RAlt::       SendInput {Blind}{Delete down}
$*RAlt up::    SendInput {Blind}{Delete up}

; ---------- Swap Win <-> Ctrl (enabled only when ModeSwapEnabled()=true) ----------
#If ModeSwapEnabled()
$*LWin::        SendInput {Blind}{LCtrl down}
$*LWin up::     SendInput {Blind}{LCtrl up}
$*LCtrl::       SendInput {Blind}{LWin down}
$*LCtrl up::    SendInput {Blind}{LWin up}

$*RWin::        SendInput {Blind}{RCtrl down}
$*RWin up::     SendInput {Blind}{RCtrl up}
$*RCtrl::       SendInput {Blind}{Delete down}
$*RCtrl up::    SendInput {Blind}{Delete up}

+`::SendInput, ~
#If  ; end conditional hotkeys

; ============ Middle / Shift+Middle ===============
*$MButton::             SendInput {MButton down}
*$MButton up::          SendInput {MButton up}
+*$MButton::            SendInput +{MButton down}
+*$MButton up::         SendInput +{MButton up}

*XButton2::             SendInput {MButton down}
*XButton2 up::          SendInput {MButton up}
+*XButton2::            SendInput +{MButton down}
+*XButton2 up::         SendInput +{MButton up}

; ================= IME mappings ===================
$`::            SendInput {vk19}    ; IME toggle
$!`::           SendInput {vk1C}    ; Convert
$+`::           SendInput {vk1D}    ; NonConvert
; If needed, try vkF3/vkF4 depending on your IME.
F16::   SendInput {vk19}
^F16::  SendInput {Shift down}{sc029}{Shift up}
+!'::   SendInput {sc029}

; ===== =======================================================
; ===== Only active when Blender is the foreground window ====
#IfWinActive ahk_exe blender.exe
; ; --- Hotkeys: Ctrl + [0-9 / .] produce pure Numpad digits via scancode (no modifiers) ---
^0::SendInput {Numpad0}
^1::SendInput {Numpad1}
^2::SendInput {Numpad2}
^3::SendInput {Numpad3}
^4::SendInput {Numpad4}
^5::SendInput {Numpad5}
^6::SendInput {Numpad6}
^.::SendInput {NumpadDot}
#IfWinActive
; ===== =======================================================
; ===== =======================================================

; ============== Init / Cleanup ===================
InitTray()

OnExit, _cleanup
return
_cleanup:
SendInput {Shift up}{Ctrl up}{Alt up}{LWin up}{RWin up}
ExitApp
