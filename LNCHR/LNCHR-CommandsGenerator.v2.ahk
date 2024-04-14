#Requires AutoHotkey 2.0.12+
#SingleInstance Force
SetWorkingDir(A_ScriptDir)
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
output_ahk      := A_ScriptDir '\LNCHR-COMMANDS.v2.ahk'
gdoc_id         := "1tvzZvYvhTGVAc9CmY3aoX-xMju10yNn_au4ivuzhXR8"
gsheet_id       := '14700514'
lnchr_csv       := GSheet2Var(gdoc_id, gsheet_id)
Sleep(1000)
HDRS            := GetHeaders(lnchr_csv)
LNCHR_ARR       := CSV2ARRAY(lnchr_csv)
LNCHR_MAP       := Map()
; _______________________________
for row_index, row in LNCHR_ARR {
    if (row_index > 1) {
        ; __________________________________________________________________
        ;   create array for each command type
        ; __________________________________________________________________
        try if !LNCHR_MAP.Has(row[4])
            LNCHR_MAP[row[4]] := []
        ; __________________________________________________________________
        ;   create a map for each row
        ;       with the row values paired with the col names keys
        ; __________________________________________________________________
        row_map := Map()
        for i, hdr in HDRS
            try row_map[hdr] := row[i]
        ; __________________________________________________________________
        ;   add the row map to the corresponding command type array
        ; __________________________________________________________________
        try row_command_type := row[4]
        try LNCHR_MAP[row_command_type].Push(row_map)
    }
}
; __________________________________________________________________
;   prepare lnchr commands output ahk file
; __________________________________________________________________
LNCHR_COMMANDS := LNCHR_COMMANDS_GENERATOR()
LNCHR_COMMANDS.commands_start()
; _______________________________
for command_group in LNCHR_MAP 
    for cmd in LNCHR_MAP[command_group]
        LNCHR_COMMANDS.handle_command(cmd)
; _______________________________
LNCHR_COMMANDS.commands_end()
LNCHR_COMMANDS := LNCHR_COMMANDS.GET_COMMANDS()
; __________________________________________________________________
;   delete lnchr_commands ahk file
;       + append new file with updated commands
; __________________________________________________________________
try FileDelete(output_ahk)
FileAppend(LNCHR_COMMANDS, output_ahk)
MsgBox('Done!')
; _______________________________
ExitApp
ESC::ExitApp

; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
class LNCHR_COMMANDS_GENERATOR {
    current_commands_group := ""

    __New() {
        this.commands := []
    }

    append(cmd) {
        this.commands.push(cmd)
    }

    set_header(commands_group) {
        if (this.current_commands_group != commands_group) {
            this.current_commands_group := commands_group
            this.header(commands_group)
        }
    }

    header(name) {
        separator := strRepeat('/', 100)
        this.append('; ' separator)
        this.append(';`t COMMANDS - ' name)
        this.append('; ' separator '`n')
    }

    command_handler(commands_group, command, COMMAND_UPPER, description, action) {
        this.set_header(commands_group)
        this.append('if (input == "' . StrReplace(command, '_', ' ') . '" || input == "' . StrReplace(COMMAND_UPPER, '_', ' ') . '") { `t; ' description)
        this.append(action)
        this.append('return')
        this.append('}`n')
        this.append('; `t __________________________________________________________________ `n')
    }

    commands_start() {
        this.append('lngui_run_commands(input) {`n`n')
    }

    handle_command(cmd) {
        params := cmd['FIELD2'] ? cmd['FIELD1'] . ',' . cmd['FIELD2'] : cmd['FIELD1']
        ; ___________________________________________________
        action := (cmd['COMMANDTYPE'] == 'REPLACEME_QUERY')
                ? 'lngui_enable_query("' . cmd['DESCRIPTION'] . '", make_run_ReplaceTexts_func("' . cmd['COMMAND'] . '", "' . cmd['REPLACEMEBASEURL'] . '", "' . params . '"))'
                ; _______________________________
                : (cmd['COMMANDTYPE'] == 'RUN_COMMAND')
                ? 'close_lngui()`nTryRun("' . cmd['FIELD1'] . '")'
                ; _______________________________
                : (cmd['COMMANDTYPE'] == 'SEND_KEYS')
                ? 'close_lngui()`nSend "' . cmd['FIELD1'] . '"'
                ; _______________________________
                : (cmd['COMMANDTYPE'] == 'RUN_COMMAND_WITHOUT_CLOSING_GUI')
                ? cmd['FIELD1']
                ; _______________________________
                : (cmd['COMMANDTYPE'] == 'CLOSE_GUI_THEN_RUN_COMMAND')
                ? 'close_lngui()`nWinActivate "ahk_id " IniRead(A_Temp "\AutoHotkey\lnchr_ini.ini", "lnchr_info", "active_id")`n' . cmd['FIELD1']
                ; _______________________________
                : '' 
        ; ___________________________________________________
        this.command_handler(cmd['COMMANDTYPE'], cmd['COMMAND'], strUPPER(cmd['COMMAND']), cmd['DESCRIPTION'], action)
    }

    commands_end() {
        this.append('}')
    }

    GET_COMMANDS() {
        commands := ''
        for line in this.commands
            commands .= line . '`n'
        return commands
    }

}

; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
GSheet2Var(gdoc_id, gsheet_id) {
    whr := ComObject('WinHttp.WinHttpRequest.5.1')
    ; whr.Open('GET', 'https://docs.google.com/spreadsheets/d/' gdoc_id '/export?format=csv&id' gdoc_id '&gid=' gsheet_id, true)
    whr.Open('GET', 'https://docs.google.com/spreadsheets/d/' gdoc_id '/export?format=csv&id' gdoc_id, true)
    whr.Send()
    whr.WaitForResponse()
    csvDATA := whr.ResponseText
    return csvDATA
}

; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
GetHeaders(csv, delimiter:=",") {
    csv := ( FileExist(csv) ) ? FileRead(csv) : csv
    arr := []
    ; _______________________________
    Loop Parse csv, '`n'
        headers := ( A_Index == 1 ) ? StrSplit(A_LoopField, delimiter) : headers
    until ( headers )
    ; _______________________________
    for each, header in headers {
        cleanedHeader := RegExReplace(Trim(header), "[^\w-]", "")
        arr.Push(cleanedHeader)
    }
    ; _______________________________
    return arr
}

; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
CSV2ARRAY(csv) {
    csv         := ( FileExist(csv) ) ? FileRead(csv) : csv
    CSV_OBJECT  := []
    ; _______________________________
    for x, y in StrSplit(csv, '`r`n') {
        RW := []	
        Loop Parse, y, 'CSV'
            RW.Push(A_LoopField)
        (y) && CSV_OBJECT.Push(RW)
    }
    ; _______________________________
    return CSV_OBJECT
}

; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
strRepeat(str, count) {
    return strReplace(format( "{:" count "}",  "" ), " ", str)
}