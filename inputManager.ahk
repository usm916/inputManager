; ================================
; Minimal & robust remaps (AHK v1)
; - Swap Win <-> Ctrl (both sides)
; - IME toggle/convert/non-convert
; - Middle / Shift+Middle (split down/up)
; - Ctrl+0..9 -> Numpad0..9 (works with physical Win after swap)
; ================================
SendLevel 1   ; events from this script are at level 1
#SingleInstance Force
#InstallKeybdHook
#UseHook
SendMode, Event             ; stable for RDP/streaming
SetKeyDelay, 5, 5         ; tune 10–30ms if needed
#MenuMaskKey, vk07          ; mask Win single-tap side effects
; --- set process priority to High ---
Process, Priority, , High
;SetNumLockState, AlwaysOn
$*RAlt::       SendEvent {Blind}{Delete down}
$*RAlt up::    SendEvent {Blind}{Delete up}

; ---------- Swap Left Win <-> Left Ctrl ----------
$*LWin::        SendEvent {Blind}{LCtrl down}
$*LWin up::     SendEvent {Blind}{LCtrl up}
$*LCtrl::       SendEvent {Blind}{LWin down}
$*LCtrl up::    SendEvent {Blind}{LWin up}

; ---------- Swap Right Win <-> Right Ctrl ----------
$*RWin::        SendEvent {Blind}{RCtrl down}
$*RWin up::     SendEvent {Blind}{RCtrl up}
$*RCtrl::       SendEvent {Blind}{RWin down}
$*RCtrl up::    SendEvent {Blind}{RWin up}

; ================= IME mappings ===================
; VK_KANJI (0x19): IME toggle, VK_CONVERT (0x1C), VK_NONCONVERT (0x1D)
$`::            SendEvent {vk19}    ; ` -> IME toggle
$!`::           SendEvent {vk1C}    ; Alt+` -> Convert (Henkan)
$+`::           SendEvent {vk1D}    ; Shift+` -> NonConvert (Muhenkan)
; If your layout differs, try vkF3/vkF4 for toggle.

; ============ Middle / Shift+Middle ===============
; Physical MButton (split into down/up)
*$MButton::             SendEvent {MButton down}
*$MButton up::          SendEvent {MButton up}
+*$MButton::            SendEvent +{MButton down}   ; Shift + Middle
+*$MButton up::         SendEvent +{MButton up}

; Map side button to Middle (and Shift+Middle), also split down/up
*XButton2::             SendEvent {MButton down}
*XButton2 up::          SendEvent {MButton up}
+*XButton2::            SendEvent +{MButton down}
+*XButton2 up::         SendEvent +{MButton up}

; (Optional) side button as Left click, also stable split
; *XButton1::             SendEvent {LButton down}
; *XButton1 up::          SendEvent {LButton up}

; ===== Send Numpad keys via scancode (down -> delay -> up) =====
; Delay = 5 msec between down and up to improve reliability.

SendNumSC_Delay(key) {
    ; Save current NumLock toggle state (true=ON)
    state := GetKeyState("NumLock", "T")
    if (!state)
        SetNumLockState, On

    ; Map logical key -> scancode
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

    ; Send down, wait 5ms, then up
    SendInput {sc%sc% down}
    Sleep, 5
    SendInput {sc%sc% up}

    ; Restore NumLock state
    if (!state)
        SetNumLockState, Off
}

; ---- Remaps: Ctrl+digit -> Numpad (scancode, delay) ----
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

; ============== Cleanup on exit ===================
OnExit, _cleanup
return
_cleanup:
SendEvent {Shift up}{Ctrl up}{Alt up}{LWin up}{RWin up}
ExitApp
