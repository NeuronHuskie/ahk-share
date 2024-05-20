#Requires AutoHotkey 2.0.12+
#SingleInstance Force

; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
;       EXAMPLES
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

; move current window to zone
#1:: WinZones(,1)
#2:: WinZones(,2)
#3:: WinZones(,3)
#4:: WinZones(,4)
#5:: WinZones(,5)

; move specific window to zone
; #1:: WinZones('Gmail - Google Chrome ahk_exe chrome.exe',1)



; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
;       FUNCTIONS
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
WinZones(win_title:='A', zone:=1) {
   WinWait(win_title)
   id          := WinActive(win_title)
   positions   := GetMonitorPositions()
   ; _______________________________________________________________
   try {
      wz       := positions[A_ComputerName][PrimaryMonitor()]
      pos      := wz[zone]
      WinMove(pos.x, pos.y, pos.w, pos.h, 'ahk_id ' id)
   }
   catch 
      MsgBox("Invalid monitor or monitor specified.",'WinZones',48)
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
PrimaryMonitor() {
   for HMON, M in MDMF_Enum() {
       w       := Abs(M.Right - M.Left)
       h       := (M.Bottom - M.Top)
       pixels  := (w * h)
       if (M.Primary)
           return (pixels = 8294400) ? "Monitor1"
                : (pixels = 3686400) ? "Monitor2"
                : (pixels = 2073600) ? "Monitor3"
                : ""
   }
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
MonitorZones() {
    positions                       := Map()
    positions['PC1']                := Map()
    positions['PC1']['Monitor1']    := Map()
    positions['PC1']['Monitor2']    := Map()
    positions['PC2']                := Map()
    positions['PC2']['Monitor1']    := Map()
    ; _______________________________________
    positions['PC1']['Monitor1'][1] := {x:13,    y:20,   w:1627, h:1286}
    positions['PC1']['Monitor1'][2] := {x:13,    y:1319, w:1627, h:798}
    positions['PC1']['Monitor1'][3] := {x:1646,  y:20,   w:2181, h:2097}
    positions['PC1']['Monitor1'][4] := {x:3832,  y:202,  w:2576, h:1426}
    positions['PC1']['Monitor1'][5] := {x:6392,  y:-3,   w:1096, h:1906}
    ; _______________________________________
    positions['PC1']['Monitor2'][1] := {x:-3828, y:-190, w:1629, h:1287}
    positions['PC1']['Monitor2'][2] := {x:-3827, y:1109, w:1627, h:798}
    positions['PC1']['Monitor2'][3] := {x:-2194, y:-190, w:2181, h:2097}
    positions['PC1']['Monitor2'][4] := {x:360,   y:167,  w:1704, h:1144}
    positions['PC1']['Monitor2'][5] := {x:2552,  y:-213, w:1096, h:1906}
    ; _______________________________________
    positions['PC2']['Monitor1'][1] := {x:13,    y:20,   w:1627, h:1287}
    positions['PC2']['Monitor1'][2] := {x:13,    y:1320, w:1627, h:797}
    positions['PC2']['Monitor1'][3] := {x:1646,  y:20,   w:2181, h:2097}
    positions['PC2']['Monitor1'][4] := {x:3130,  y:20,   w:697,  h:2097}
   ; _______________________________________
   return positions
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
CopyWinCoords() {
    WinGetPos(&x, &y, &w, &h, 'A')
    A_Clipboard := '{x:' x ', y:' y ', w:' w ', h:' h '}'
    MsgBox('The active window position coords have been copied to the clipboard.')
    return
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
; https://www.autohotkey.com/boards/viewtopic.php?p=567016#p567016
; ======================================================================================================================
; Multiple Display Monitors Functions -> msdn.microsoft.com/en-us/library/dd145072(v=vs.85).aspx =======================
; ======================================================================================================================
; Enumerates display monitors and returns an object containing the properties of all monitors or the specified monitor.
; ======================================================================================================================
MDMF_Enum() {
   Monitors := Map(), Address := CallbackCreate(MDMF_EnumProc)
   Success := DllCall("User32.dll\EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", Address, "Ptr", ObjPtr(Monitors), "Int")
   return (CallbackFree(Address), Success ? Monitors : false)
}
; ======================================================================================================================
;  Callback function that is called by the MDMF_Enum function.
; ======================================================================================================================
MDMF_EnumProc(HMON, HDC, PRECT, ObjectAddr) {
   Monitors := ObjFromPtrAddRef(ObjectAddr)
   Monitors[HMON] := MDMF_GetInfo(HMON)
   if Monitors[HMON].Primary
      Monitors.Primary := HMON
   return true
}
; ======================================================================================================================
; Retrieves the display monitor that has the largest area of intersection with a specified window.
; The following flag values determine the function's return value if the window does not intersect any display monitor:
;    MONITOR_DEFAULTTONULL    = 0 - Returns NULL.
;    MONITOR_DEFAULTTOPRIMARY = 1 - Returns a handle to the primary display monitor. 
;    MONITOR_DEFAULTTONEAREST = 2 - Returns a handle to the display monitor that is nearest to the window.
; ======================================================================================================================
MDMF_FromHWND(HWND, Flag?) {
   return DllCall("User32.dll\MonitorFromWindow", "Ptr", HWND, "UInt", Flag ?? 0, "Ptr")
}
; ======================================================================================================================
; Retrieves the display monitor that contains a specified point.
; If either X or Y is empty, the function will use the current cursor position for this value and return it ByRef.
; The following flag values determine the function's return value if the point is not contained within any
; display monitor:
;    MONITOR_DEFAULTTONULL    = 0 - Returns NULL.
;    MONITOR_DEFAULTTOPRIMARY = 1 - Returns a handle to the primary display monitor. 
;    MONITOR_DEFAULTTONEAREST = 2 - Returns a handle to the display monitor that is nearest to the point.
; ======================================================================================================================
MDMF_FromPoint(X?, Y?, Flag?) {
   if !IsSet(X) || !IsSet(Y) {
      PT := Buffer(8)
      DllCall("User32.dll\GetCursorPos", "Ptr", PT, "Int")
      if !IsSet(X)
         X := NumGet(PT, 0, "Int")
      if !IsSet(Y)
         Y := NumGet(PT, 4, "Int")
   }
   return DllCall("User32.dll\MonitorFromPoint", "Int64", (X & 0xFFFFFFFF) | (Y << 32), "UInt", Flag ?? 0, "Ptr")
}
; ======================================================================================================================
; Retrieves the display monitor that has the largest area of intersection with a specified rectangle.
; Parameters are consistent with the common AHK definition of a rectangle, which is X, Y, W, H instead of
; Left, Top, Right, Bottom.
; The following flag values determine the function's return value if the rectangle does not intersect any
; display monitor:
;    MONITOR_DEFAULTTONULL    = 0 - Returns NULL.
;    MONITOR_DEFAULTTOPRIMARY = 1 - Returns a handle to the primary display monitor. 
;    MONITOR_DEFAULTTONEAREST = 2 - Returns a handle to the display monitor that is nearest to the rectangle.
; ======================================================================================================================
MDMF_FromRect(X, Y, W, H, Flag?) {
   RC := Buffer(16)
   DllCall("SetRect", "Ptr", RC, "Int", X, "Int", Y, "Int", X + W, "Int", Y + H, "Int")
   return DllCall("User32.dll\MonitorFromRect", "Ptr", RC, "UInt", Flag ?? 0, "Ptr")
}
; ======================================================================================================================
; Retrieves information about a display monitor.
; ======================================================================================================================
MDMF_GetInfo(HMON) {
   MIEX := Buffer(104)
   NumPut "UInt", 104, MIEX, 0
   if DllCall("User32.dll\GetMonitorInfo", "Ptr", HMON, "Ptr", MIEX, "Int")
      return {Name:       (Name := StrGet(MIEX.Ptr + 40, 32))  ; CCHDEVICENAME = 32
            , Num:        RegExReplace(Name, ".*(\d+)$", "$1")
            , Left:       NumGet(MIEX,  4, "Int")    ; display rectangle
            , Top:        NumGet(MIEX,  8, "Int")    ; "
            , Right:      NumGet(MIEX, 12, "Int")    ; "
            , Bottom:     NumGet(MIEX, 16, "Int")    ; "
            , WALeft:     NumGet(MIEX, 20, "Int")    ; work area
            , WATop:      NumGet(MIEX, 24, "Int")    ; "
            , WARight:    NumGet(MIEX, 28, "Int")    ; "
            , WABottom:   NumGet(MIEX, 32, "Int")    ; "
            , Primary:    NumGet(MIEX, 36, "UInt")}  ; contains a non-zero value for the primary monitor.
   return false
}
