#Requires Autohotkey v2.0+
#SingleInstance Force

; █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
; █                               EXAMPLES                               █
; █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█
; use the CopyWinCoords() helper function to set up your zones
; F1:: CopyWinCoords()
; ╔──────────────────────────────────────────────────╗
; ║           move current window to zone            ║
; ╚──────────────────────────────────────────────────╝
; #1:: WinZones(1)
; #2:: WinZones(2)
; #3:: WinZones(3)
; #4:: WinZones(4)
; #5:: WinZones(5)
; ╔──────────────────────────────────────────────────╗
; ║           move specific window to zone           ║
; ╚──────────────────────────────────────────────────╝
; #6:: WinZones(1, 'Gmail - Google Chrome ahk_exe chrome.exe')
; ESC::ExitApp



; █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
; █                              FUNCTIONS                               █
; █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█
/**
* CopyWinCoords() - Helper function to set up MonitorZones()
                    Copies active window coordinates to clipboard in object format
*
* @returns {void} Sets clipboard to: {x:x, y:y, w:w, h:h}

* @example
    CopyWinCoords()         ; Click window then run to copy its position
    MsgBox(A_Clipboard)     ; Show copied coordinates
*/

CopyWinCoords() {
    WinGetPos(&x, &y, &w, &h, 'A')
    A_Clipboard := '{x:' x ', y:' y ', w:' w ', h:' h '}'
    MsgBox('The active window position coords have been copied to the clipboard.')
    return
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
/**
* WinZones() -  Moves and resizes a window to a predefined zone position
*               Zones for each monitor are defined in MonitorZones()
*               Zones 4-5 will maximize the window after moving
*
* @param {Integer} zone - Zone number to move window to (1-5)
* @param {String} win_title - Window title to move (defaults to active window)
* @throws {Error} If invalid monitor or zone specified

* @example
    WinZones(1)             ; Move active window to zone 1
    WinZones(3, 'Notepad')  ; Move Notepad to zone 3
*/

WinZones(zone, win_title:='A') {
    WinWait(win_title)
    id          := WinActive(win_title)
    positions   := MonitorZones()
    ; _______________________________________________________________
    try {
        wz      := positions[A_ComputerName][PrimaryMonitor()]
        pos     := wz[zone]
        WinMove(pos.x, pos.y, pos.w, pos.h, 'ahk_id ' id)
        ; ___________________________________________________________
        ;   uncomment below to maximize the window after moving
        ; ___________________________________________________________
        ; ((zone = 4 || zone = 5) && !WinGetMinMax('ahk_id ' id)) ? (
        ;         WinActivate('ahk_id ' id),
        ;         WinWaitActive('ahk_id ' id),
        ;         WinMaximize('ahk_id ' id)
        ;     ) : ''
    }
    ; _______________________________________________________________
    catch
        MsgBox('Invalid monitor or monitor specified.','WinZones', 48)
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
/**
* MonitorZones() -  Returns predefined monitor zone configurations for different setups
*                   Contains coordinate maps for window positions across multiple monitors
*                   Each zone defines x, y coordinates and width/height dimensions
*
* @returns {Map} Nested map structure:
*     Location (e.g. 'PCNAME-1')
*     Monitor Name (e.g. '43S431') 
*     Zone Number => {x, y, w, h}

* @example
    zones := MonitorZones()
    home_zones := zones['PCNAME-1']
    primary_monitor_zones := home_zones['43S431']
    zone1_coords := primary_monitor_zones[1]
    MsgBox(
        'Zone 1 position:`n'
        'x: ' zone1_coords.x '`n'
        'y: ' zone1_coords.y
)
*/

MonitorZones() {
    positions := Map(
        'PCNAME-1', Map(
            '43S431', Map(
                1, {x:13,    y:20,   w:1627, h:1286},
                2, {x:13,    y:1319, w:1627, h:798},
                3, {x:1646,  y:20,   w:2181, h:2097},
                4, {x:3832,  y:202,  w:2576, h:1426},
                5, {x:6392,  y:-3,   w:1096, h:1906}
            ),
            'Dell S2716DG', Map(
                1, {x:-3828, y:-190, w:1629, h:1287},
                2, {x:-3827, y:1109, w:1627, h:798},
                3, {x:-2194, y:-190, w:2181, h:2097},
                4, {x:360,   y:167,  w:1704, h:1144},
                5, {x:2552,  y:-213, w:1096, h:1906}
            )
        ),
        'PCNAME-2', Map(
            'TCL', Map(
                1, {x:13,    y:20,   w:1627, h:1287},
                2, {x:13,    y:1320, w:1627, h:797},
                3, {x:1646,  y:20,   w:2181, h:2097},
                4, {x:3130,  y:20,   w:697,  h:2097}
            )
        )
    )
    return positions
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
/**
* PrimaryMonitor() - Returns the primary monitor's friendly name or full monitor info
*
* @param {Boolean} return_friendly_name - If true returns monitor name, if false returns full monitor Map
* @returns {String|Map} Monitor friendly name or full monitor Map object
* @example
    primary_name := PrimaryMonitor()  ; Returns friendly name
    primary_info := PrimaryMonitor(false)  ; Returns full monitor Map
    MsgBox('Primary display: ' primary_info['description'])
*/

PrimaryMonitor(return_friendly_name:=true) {
    for monitor in MonitorInfo() 
        if monitor['isPrimary']
            return return_friendly_name ? monitor['userFriendlyName'] : monitor
    return
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
/**
* MonitorInfo() - Helper function to return an array with a map for each monitor - credit to SKAN's MonitorFind()
*
* @returns {Array} Array of Map objects containing monitor details:
*     userFriendlyName - Display name of the monitor
*     serialNumberID   - Unique serial number
*     description      - Monitor description/model
*     shortID         - Short identifier
*     monitorNumber   - System assigned number
*     displayDevice   - Display adapter info
*     portUID         - Port identifier
*     settingsNumber  - Settings reference number
*     isPrimary       - Whether this is primary display (1 or 0)

* @example
    for monitor in MonitorInfo() {
        is_primary := monitor['isPrimary'] ? 'Primary' : 'Secondary'
        MsgBox(
            'Monitor: ' monitor['userFriendlyName'] '`n' 
            'Type: ' is_primary
        )
    }
*/

MonitorInfo() {
    MONITORS := []
    ; __________________________________________________________________
    for block in StrSplit(MonitorFind(), '`n`n') {
        if block == ''
            continue
        ; _________________________________
        MONITOR := Map(
            'userFriendlyName', '',
            'serialNumberID',   '',
            'description',      '',
            'shortID',          '',
            'monitorNumber',    '',
            'displayDevice',    '',
            'portUID',          '',
            'settingsNumber',   '',
            'isPrimary',        ''
        )
        ; _________________________________
        for prop, line in StrSplit(block, '`n')
            if RegExMatch(line, '^\d+\) (.*)$', &match)
                MONITOR[ prop = 1 ? 'userFriendlyName' 
                    : prop = 2 ? 'serialNumberID'
                    : prop = 3 ? 'description'
                    : prop = 4 ? 'shortID'
                    : prop = 5 ? 'monitorNumber'
                    : prop = 6 ? 'displayDevice'
                    : prop = 7 ? 'portUID'
                    :            'settingsNumber'] := match[1]
        ; _________________________________
        MONITOR['isPrimary'] := MONITOR['monitorNumber'] = MonitorGetPrimary() ? 1 : 0
        MONITORS.Push(MONITOR)
    }
    ; __________________________________________________________________
    return MONITORS
}
; █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
; █                 MDMF - Multiple Display Monitors Functions - by justme @ https://autohotkey.com/r?t=4606                 █
; █                                                                                                                          █
; █              Multiple Display Monitors Functions -> msdn.microsoft.com/en-us/library/dd145072(v=vs.85).aspx              █
; █   Enumerates display monitors and returns an object containing the properties of all monitors or the specified monitor   █
; █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█
MDMF_Enum() {
    Monitors := Map(), Address := CallbackCreate(MDMF_EnumProc)
    Success := DllCall("User32.dll\EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", Address, "Ptr", ObjPtr(Monitors), "Int")
    return (CallbackFree(Address), Success ? Monitors : false)
}
; ======================================================================================================================
;  Callback function that is called by the MDMF_Enum function.
; ======================================================================================================================
MDMF_EnumProc(HMON, HDC, PRECT, ObjectAddr) {
    Monitors        := ObjFromPtrAddRef(ObjectAddr)
    Monitors[HMON]  := MDMF_GetInfo(HMON)
    if Monitors[HMON].Primary
    Monitors.Primary := HMON
    Monitors[HMON].UserFriendlyName := MonitorFind("5) " Monitors[HMON].Num, 1)
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
; █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
; █                        MonitorFind() v0.24                           █
; █                                                                      █
; █       by SKAN for ah2 on D78U/D79P @ autohotkey.com/r?t=133259       █
; █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█
MonitorFind(Query?, Field?)  {              ;   MonitorFind() v0.24  by SKAN for ah2 on D78U/D79P @ autohotkey.com/r?t=133259
    Local  QDC_ALL_PATHS           :=  0x00000001
        ,  QDC_DATABASE_CURRENT    :=  0x00000004
        ,  Topology                :=  { 1:"internal",  2:"clone",  4:"extend",  8:"external" }
        ,  nPath, nMode, nTopology :=  0
        ,  DISPLAYCONFIG_PATH_INFO_Array
        ,  DISPLAYCONFIG_MODE_INFO_Array

    DllCall("User32\GetDisplayConfigBufferSizes", "uint",QDC_DATABASE_CURRENT, "uintp",&nPath := 0, "uintp",&nMode := 0)

    DISPLAYCONFIG_PATH_INFO_Array  :=  Buffer(72 * nPath)   ; 72 = (20 + 48 + 4)
    DISPLAYCONFIG_MODE_INFO_Array  :=  Buffer(64 * nMode)

    DllCall( "User32\QueryDisplayConfig", "uint", QDC_DATABASE_CURRENT
                                        , "uintp",&nPath, "ptr",DISPLAYCONFIG_PATH_INFO_Array
                                        , "uintp",&nMode, "ptr",DISPLAYCONFIG_MODE_INFO_Array
                                        , "uintp",&nTopology )

    MonitorFind.Status :=  Topology.HasProp(nTopology) ? Topology.%nTopology% : "" ;  https://ss64.com/nt/displayswitch.html

    If ( IsSet(Query) and StrLen(Query) < 2 )
        Return (  MonitorFind.Count := 0,  StrLen(Query)=0 ? MonitorFind.Status : "" )

    DllCall("User32\GetDisplayConfigBufferSizes", "uint",QDC_ALL_PATHS, "uintp",&nPath := 0, "uintp",&nMode := 0)

    DISPLAYCONFIG_PATH_INFO_Array  :=  Buffer(72 * nPath)   ; 72 = (20 + 48 + 4)
    DISPLAYCONFIG_MODE_INFO_Array  :=  Buffer(64 * nMode)

    DllCall( "User32\QueryDisplayConfig", "uint", QDC_ALL_PATHS
                                        , "uintp",&nPath, "ptr",DISPLAYCONFIG_PATH_INFO_Array
                                        , "uintp",&nMode, "ptr",DISPLAYCONFIG_MODE_INFO_Array
                                        , "ptr",0 )

    Local  List :=  "`n`n"
        ,  DeviceName,   DevicePath,   AdpID,   TrgID,   SrcID,   DoneID :=  Map(),  Off  := -72
        ,  DISPLAYCONFIG_SOURCE_DEVICE_NAME  :=  Buffer( 84, 0)
        ,  DISPLAYCONFIG_TARGET_DEVICE_NAME  :=  Buffer(420, 0)

    DoneID.Default  :=  0

    Loop ( nPath )
    {
        If  ( NumGet(DISPLAYCONFIG_PATH_INFO_Array, (Off += 72) + 60, "uint") = 0 )   ;  Checking if targetAvailable = false
            Continue

        AdpID   :=   NumGet(DISPLAYCONFIG_PATH_INFO_Array, Off +  0, "int64")
        SrcID   :=   NumGet(DISPLAYCONFIG_PATH_INFO_Array, Off +  8,  "uint")
        TrgID   :=   NumGet(DISPLAYCONFIG_PATH_INFO_Array, Off + 28,  "uint")

        If  ( DoneID[TrgID & 0xFFFF] )
            Continue
        Else  DoneID[TrgID & 0xFFFF] := 1

        NumPut("int",       1,  DISPLAYCONFIG_SOURCE_DEVICE_NAME,  0)     ;  DISPLAYCONFIG_DEVICE_INFO_GET_SOURCE_NAME =   1
        NumPut("int",      84,  DISPLAYCONFIG_SOURCE_DEVICE_NAME,  4)     ;  DISPLAYCONFIG_SOURCE_DEVICE_NAME.Size     =  84
        NumPut("int64", AdpID,  DISPLAYCONFIG_SOURCE_DEVICE_NAME,  8)
        NumPut("uint",  SrcID,  DISPLAYCONFIG_SOURCE_DEVICE_NAME, 16)

        DllCall("User32\DisplayConfigGetDeviceInfo", "ptr",DISPLAYCONFIG_SOURCE_DEVICE_NAME)
        DeviceName  :=  StrGet(DISPLAYCONFIG_SOURCE_DEVICE_NAME.Ptr + 20)

        NumPut("int",       2,  DISPLAYCONFIG_TARGET_DEVICE_NAME,  0)     ;  DISPLAYCONFIG_DEVICE_INFO_GET_TARGET_NAME =   2
        NumPut("int",     420,  DISPLAYCONFIG_TARGET_DEVICE_NAME,  4)     ;  DISPLAYCONFIG_TARGET_DEVICE_NAME.Size     = 420
        NumPut("int64", AdpID,  DISPLAYCONFIG_TARGET_DEVICE_NAME,  8)
        NumPut("uint",  TrgID,  DISPLAYCONFIG_TARGET_DEVICE_NAME, 16)

        DllCall("User32\DisplayConfigGetDeviceInfo", "ptr",DISPLAYCONFIG_TARGET_DEVICE_NAME)
        DevicePath  :=  StrGet(DISPLAYCONFIG_TARGET_DEVICE_NAME.Ptr + 164)

        If ( TrgID > 0xFFFF )
            List := StrReplace(List, DeviceName)

        If ( InStr(List, DeviceName) )
            DeviceName  :=  ""

        List  .=  ParseEDID(DevicePath, TrgID & 0xFFFF, DeviceName) "`n`n"
    }

    MonitorFind.Count := DoneID.Count

    For TrgID in DoneID
        List := StrReplace(List, "8) " TrgID "`n", "8) " A_Index "`n")

    Loop ( MonitorGetCount() )
        DeviceName  :=  MonitorGetName(A_Index)
        , List  :=  StrReplace(List, "5) `n6) " DeviceName, "5) " A_Index "`n6) " DeviceName)

    If ( IsSet(Query) = 0 )
        Return Trim(List, "`n")

    Local  sPos, ePos, Str

    If (  sPos  :=  InStr(List, StrReplace(Query, "`n"), True)  )
        sPos  :=  InStr(List, "`n`n",, sPos, -1) + 2
    ,   ePos  :=  InStr(List, "`n`n",, sPos)
    ,   Str   :=  SubStr(List, sPos, ePos-sPos)
    Else  Return

    Return (  IsSet(Field) = 0  or IsInteger(Field) = 0 or Field > 8 or Field < 1
            ?    Str
            :  ( Str := StrSplit(Str, "`n")[Field]
                , SubStr(Str, 4) )  )

                    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                    ParseEDID(Hex, UniqID := 0, DeviceName := "")
                    {
                        If ( StrLen(Hex) < 256 )
                            Hex  :=  StrSplit(Hex, "#")
                        , Hex  :=  RegRead( "HKLM\SYSTEM\CurrentControlSet\Enum\DISPLAY\"
                                            .  Hex[2] "\" Hex[3] "\Device Parameters", "EDID", "" )

                                        HexToBuf_128(&Hex)
                                        {
                                            Local Buf := Buffer(128, 0)

                                            Loop (  Min(128, StrLen(Hex)//2)  )
                                                    NumPut("char", "0x" . SubStr(Hex, 2*A_Index-1, 2), Buf, A_Index-1)

                                            Return Buf
                                        }

                        EDID :=  HexToBuf_128(&Hex)
                        Manf :=  NumGet(EDID, 8, "ushort")
                        Manf :=  (Manf >> 8) | ((Manf & 0xFF) << 8) ;  convert Manf to BigEndian word

                                        UEFI_PNPID(BigE_word)       ;  https://uefi.org/PNP_ID_List
                                        {
                                            Local  Chars := "0ABCDEFGHIJKLMNOPQRSTUVWXYZ?????"

                                            Return (  SubStr(Chars, (BigE_word >> 10 & 31) + 1, 1)
                                                .  SubStr(Chars, (BigE_word >> 5  & 31) + 1, 1)
                                                .  SubStr(Chars, (BigE_word       & 31) + 1, 1)  )
                                        }

                        Local  Manf    :=  UEFI_PNPID(Manf)
                            ,  Prod    :=  NumGet(EDID, 10, "ushort")
                            ,  Serial  :=  NumGet(EDID, 12, "uint")

                        Local  EDID,  Make := "",  Desc := "",  Snid := ""
                        EDID.Ptr2  :=  EDID.Ptr + 54                ;    54 is starting offset of detailed timing descriptor
                                                                    ;  and 72, 90 and 108 are offsets to display descriptors
                        Loop ( 3 )
                            Switch ( NumGet(EDID.Ptr2 += 18, "int64") & 0xFFFFFFFFFF )  ; Read int64 and convert to int40
                            {
                                        Case 0x00FC000000:  Make :=  StrGet(EDID.Ptr2 + 5, 13, "cp437")
                                                        ,  Make :=  RTrim(Make, "`n`s")

                                        Case 0x00FE000000:  Desc :=  StrGet(EDID.Ptr2 + 5, 13, "cp437")
                                                        ,  Desc :=  RTrim(Desc, "`n`s")

                                        Case 0x00FF000000:  Snid :=  StrGet(EDID.Ptr2 + 5, 13, "cp437")
                                                        ,  Snid :=  RTrim(Snid, "`n`s")
                            }

                        Return Format( "1) {1:}`n2) {2:}`n3) {3:}`n"
                                    . "4) {4:}{5:04X}_{6:08X}`n"
                                    . "5) `n6) {7:}`n7) UID{8:}`n8) {8:}"
                                    , Make, Snid, Desc, Manf, Prod, Serial, DeviceName, UniqID )
                    }
} ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

/*

DISPLAYCONFIG_PATH_INFO                                                                  ;  http://tiny.cc/displayconfig_1
=======================
0   20  DISPLAYCONFIG_PATH_SOURCE_INFO *                                                ;  http://tiny.cc/displayconfig_2
20   48  DISPLAYCONFIG_PATH_TARGET_INFO **                                               ;  http://tiny.cc/displayconfig_3
68    4  UINT32                                  flags;

DISPLAYCONFIG_PATH_SOURCE_INFO *                                                         ;  http://tiny.cc/displayconfig_2
--------------------------------
0    8  LUID                                    adapterId;
8    4  UINT32                                  id;
12    4  UINT32                                  modeInfoIdx
16    4  UINT32                                  statusFlags;

DISPLAYCONFIG_PATH_TARGET_INFO **                                                        ;  http://tiny.cc/displayconfig_3
---------------------------------
28    4? LUID                                    adapterId;
32?   4  UINT32                                  id;
36    4  DISPLAYCONFIG_VIDEO_OUTPUT_TECHNOLOGY   outputTechnology;
40    4  DISPLAYCONFIG_ROTATION                  rotation;
44    4  DISPLAYCONFIG_SCALING                   scaling;
48    8  DISPLAYCONFIG_RATIONAL                  refreshRate;
56    4  DISPLAYCONFIG_SCANLINE_ORDERING         scanLineOrdering;
60    4  BOOL                                    targetAvailable;
64    4  UINT32                                  statusFlags;

____________________________________________________________________________________________________________________________

DISPLAYCONFIG_TARGET_DEVICE_NAME                                                         ;  http://tiny.cc/displayconfig_4
================================
0   20  DISPLAYCONFIG_DEVICE_INFO_HEADER *      header;                                 ;  http://tiny.cc/displayconfig_5
20    4  DISPLAYCONFIG_TARGET_DEVICE_NAME_FLAGS  flags;
24    4  DISPLAYCONFIG_VIDEO_OUTPUT_TECHNOLOGY   outputTechnology;
28    2  UINT16                                  edidManufactureId;
30    3  UINT16                                  edidProductCodeId;
32    4  UINT32                                  connectorInstance;
36  128  WCHAR                                   monitorFriendlyDeviceName[64];
164  256  WCHAR                                   monitorDevicePath[128];

DISPLAYCONFIG_SOURCE_DEVICE_NAME                                                         ;  http://tiny.cc/displayconfig_6
================================
0   20  DISPLAYCONFIG_DEVICE_INFO_HEADER *      header;                                 ;  http://tiny.cc/displayconfig_5
20   64  WCHAR                                   viewGdiDeviceName[CCHDEVICENAME];

DISPLAYCONFIG_DEVICE_INFO_HEADER *                                                       ;  http://tiny.cc/displayconfig_5
----------------------------------
0    4  DISPLAYCONFIG_DEVICE_INFO_TYPE          type;
4    4  UINT32                                  size;
8    8  LUID                                    adapterId;
16    4  UINT32                                  id;

*/
