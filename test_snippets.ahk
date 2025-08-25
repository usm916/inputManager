MsgBox "Running on AHK v" A_AhkVersion

#HotIf WinActive("ahk_exe blender.exe")

SendNumSC_NoMods(sc) {
    ; Save current physical modifier states
    lc := GetKeyState("LControl","P"), rc := GetKeyState("RControl","P")
    ls := GetKeyState("LShift","P"),   rs := GetKeyState("RShift","P")
    la := GetKeyState("LAlt","P"),     ra := GetKeyState("RAlt","P")

    ; Release pressed modifiers to avoid Ctrl/Shift/Alt sticking to the output
    if lc
        SendInput "{LControl up}"
    if rc
        SendInput "{RControl up}"
    if ls
        SendInput "{LShift up}"
    if rs
        SendInput "{RShift up}"
    if la
        SendInput "{LAlt up}"
    if ra
        SendInput "{RAlt up}"

    ; Send the target scancode (down -> short delay -> up)
    SendInput "{sc" sc " down}"
    Sleep 5
    SendInput "{sc" sc " up}"

    ; Restore modifiers that were down before
    if lc
        SendInput "{LControl down}"
    if rc
        SendInput "{RControl down}"
    if ls
        SendInput "{LShift down}"
    if rs
        SendInput "{RShift down}"
    if la
        SendInput "{LAlt down}"
    if ra
        SendInput "{RAlt down}"
}

; --- Helper: Map "0-9/Dot" to Numpad scancodes and call the sender ---
SendNumSC(key) {
    sc := (key = "0") ? "052"
        : (key = "1") ? "04F"
        : (key = "2") ? "050"
        : (key = "3") ? "051"
        : (key = "4") ? "04B"
        : (key = "5") ? "04C"
        : (key = "6") ? "04D"
        : (key = "7") ? "047"
        : (key = "8") ? "048"
        : (key = "9") ? "049"
        : (key = "Dot") ? "053" : ""
    if sc != ""
        SendNumSC_NoMods(sc)
}

; --- Hotkeys: Ctrl + [0-9 / .] produce pure Numpad digits via scancode (no modifiers) ---
^0::SendNumSC("0")
^1::SendNumSC("1")
^2::SendNumSC("2")
^3::SendNumSC("3")
^4::SendNumSC("4")
^5::SendNumSC("5")
^6::SendNumSC("6")
^7::SendNumSC("7")
^8::SendNumSC("8")
^9::SendNumSC("9")
^.::SendNumSC("Dot")

#HotIf