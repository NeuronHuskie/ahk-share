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
WinZones(win_title:="A", zone:="1") {
   WinWait(win_title)
   id          := WinActive(win_title)
   positions   := MonitorZones()
   ; _______________________________________
   try {
      pos := positions[zone]
      WinMove(pos.x, pos.y, pos.w, pos.h, 'ahk_id ' id)
   }
   catch 
      MsgBox("Invalid zone specified.",'WinZones',48)
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
MonitorZones() {
   return Map( 1, {x:13,    y:20,   w:1627, h:1286},
               2, {x:13,    y:1319, w:1627, h:798},
               3, {x:1646,  y:20,   w:2181, h:2097},
               4, {x:3832,  y:202,  w:2576, h:1426},
               5, {x:6392,  y:-3,   w:1096, h:1906}
           )
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
CopyWinCoords() {
    WinGetPos(&x, &y, &w, &h, 'A')
    A_Clipboard := '{x:' x ', y:' y ', w:' w ', h:' h '}'
    MsgBox('The active window position coords have been copied to the clipboard.')
    return
}
