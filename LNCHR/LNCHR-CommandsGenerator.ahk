#Requires Autohotkey v1.1.33+
#NoEnv
#SingleInstance Force 
SendMode Input  
SetWorkingDir %A_ScriptDir%
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#include <array\ObjCSV>     ; https://github.com/JnLlnd/ObjCSV
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
tempCSV     := A_Temp       . "\AutoHotkey\temp-lnchr_commands_generator.csv"
outputAHK   := A_ScriptDir  . "\LNCHR-COMMANDS.ahk"
gdocID      := "1tvzZvYvhTGVAc9CmY3aoX-xMju10yNn_au4ivuzhXR8"
gsheetID    := "14700514"
; ___________________________________________________
FileDelete, % tempCSV
FileDelete, % outputAHK
; ╔──────────────────────────────────────────────────╗
; ║          download google sheet to csv            ║
; ╚──────────────────────────────────────────────────╝
GSheet2CSV(gdocID, gsheetID, tempCSV)
while !FileExist(tempCSV)
	Sleep, 50
; ╔──────────────────────────────────────────────────╗
; ║             create csv object                    ║
; ╚──────────────────────────────────────────────────╝
LNCHR_COMMANDS                   := ObjCSV_CSV2Collection(tempCSV,strFileHeader,1,1,1)
; ╔──────────────────────────────────────────────────╗
; ║             create command arrays                ║
; ╚──────────────────────────────────────────────────╝
REPLACEME_QUERY                  := []
RUN_COMMAND                      := []
SEND_KEYS                        := []
RUN_COMMAND_WITHOUT_CLOSING_GUI  := []
CLOSE_GUI_THEN_RUN_COMMAND       := []
REGEX_CHECK                      := []
; ╔───────────────────────────────────────────────────────────╗
; ║ loop through csv object and assign commands to category   ║
; ╚───────────────────────────────────────────────────────────╝
loop, % LNCHR_COMMANDS.MaxIndex() {
    for k, v in LNCHR_COMMANDS[A_Index] {
        category            := ( k == "CATEGORY" )                  ? v                         : category
        command             := ( k == "COMMAND" )                   ? StrReplace(v, "_", " ")   : command
        description         := ( k == "DESCRIPTION" )               ? v                         : description
        command_type        := ( k == "COMMANDTYPE" )               ? v                         : command_type
        field1              := ( k == "FIELD1" )                    ? v                         : field1
        field2              := ( k == "FIELD2" )                    ? v                         : field2
        replaceme_baseurl   := ( k == "REPLACEMEBASEURL" )          ? v                         : replaceme_baseurl  
    }
    ; ╔──────────────────────────────────────────────────╗
    ; ║       map command type values to arrays          ║
    ; ╚──────────────────────────────────────────────────╝
	COMMAND_TYPE_ARRAYS     :={ "REPLACEME_QUERY"					: REPLACEME_QUERY
                            ,   "RUN_COMMAND"						: RUN_COMMAND
                            , 	"SEND_KEYS"						    : SEND_KEYS
                            , 	"RUN_COMMAND_WITHOUT_CLOSING_GUI"	: RUN_COMMAND_WITHOUT_CLOSING_GUI
                            , 	"CLOSE_GUI_THEN_RUN_COMMAND"		: CLOSE_GUI_THEN_RUN_COMMAND
                            ,   "REGEX_CHECK"                       : REGEX_CHECK }
    ; ╔──────────────────────────────────────────────────╗
    ; ║      assign array based on command types         ║
    ; ╚──────────────────────────────────────────────────╝
    TARGET_ARRAY            :=  COMMAND_TYPE_ARRAYS[command_type]
    ; ╔──────────────────────────────────────────────────╗
    ; ║       push data into the selected array          ║
    ; ╚──────────────────────────────────────────────────╝
    TARGET_ARRAY.Push({	        "Category"			                : category
                            ,   "Command"			                : command
                            , 	"Description"		                : description
                            ,	"CommandType"		                : command_type
                            , 	"Field1"			                : field1
                            , 	"Field2"			                : field2
                            , 	"ReplaceMeBaseURL"	                : replaceme_baseurl })	
}
; ╔──────────────────────────────────────────────────╗
; ║      START LNGUI_RUN_COMMANDS() FUNCTION         ║
; ╚──────────────────────────────────────────────────╝
output := new LNCHR_COMMANDS_GENERATOR()
output.commands_start()
; ╔──────────────────────────────────────────────────╗
; ║           COMMANDS - REPLACEME_QUERY             ║
; ╚──────────────────────────────────────────────────╝
output.replaceme_query_header()
; ___________________________________________________
for index, cmd in REPLACEME_QUERY
    output.replaceme_query(cmd["Command"], strUPPER(cmd["Command"]), cmd["Description"], cmd["ReplaceMeBaseURL"], cmd["Field1"], cmd["Field2"])
; ╔──────────────────────────────────────────────────╗
; ║             COMMANDS - RUN_COMMAND               ║
; ╚──────────────────────────────────────────────────╝
output.run_command_header()
; ___________________________________________________
for index, cmd in RUN_COMMAND 
    output.run_command(cmd["Command"], strUPPER(cmd["Command"]), cmd["Description"], cmd["Field1"]) 
; ╔──────────────────────────────────────────────────╗
; ║              COMMANDS - SEND_KEYS                ║
; ╚──────────────────────────────────────────────────╝
output.send_keys_header()
; ___________________________________________________
for index, cmd in SEND_KEYS 
    output.send_keys(cmd["Command"], strUPPER(cmd["Command"]), cmd["Description"], cmd["Field1"]) 
; ╔──────────────────────────────────────────────────╗
; ║   COMMANDS - RUN_COMMAND_WITHOUT_CLOSING_GUI     ║
; ╚──────────────────────────────────────────────────╝
output.run_command_without_closing_gui_header()
; ___________________________________________________
for index, cmd in RUN_COMMAND_WITHOUT_CLOSING_GUI 
    output.run_command_without_closing_gui(cmd["Command"], strUPPER(cmd["Command"]), cmd["Description"], cmd["Field1"])
; ╔──────────────────────────────────────────────────╗
; ║     COMMANDS - CLOSE_GUI_THEN_RUN_COMMAND        ║
; ╚──────────────────────────────────────────────────╝
output.close_gui_then_run_command_header()
; ___________________________________________________
for index, cmd in CLOSE_GUI_THEN_RUN_COMMAND 
    output.close_gui_then_run_command(cmd["Command"], strUPPER(cmd["Command"]), cmd["Description"], cmd["Field1"])
; ╔──────────────────────────────────────────────────╗
; ║             COMMANDS - REGEX_CHECK               ║
; ╚──────────────────────────────────────────────────╝
output.regex_check_header()
; ___________________________________________________
for index, cmd in REGEX_CHECK
    output.regex_check(cmd["Command"], cmd["Description"], cmd["Field1"])
; ╔──────────────────────────────────────────────────╗
; ║       END LNGUI_RUN_COMMANDS() FUNCTION          ║
; ╚──────────────────────────────────────────────────╝
output.commands_end()
output := output.GET_COMMANDS()
; ___________________________________________________
FileAppend, % output, % outputAHK
MsgBox      % "LNCHR-COMMANDS.ahk has been updated with " LNCHR_COMMANDS.MaxIndex() " commands!"
FileDelete, % tempCSV
ExitApp
; ___________________________________________________
Esc::
FileDelete, % tempCSV
ExitApp



; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
;;       functions
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
GSheet2CSV(gdocID, gsheetID, tempCSV:="temp.csv") {
    FileDelete,         % tempCSV
    URLDownloadToFile,  % "https://docs.google.com/spreadsheets/d/" gdocID "/export?format=csv&id=" gdocID "&gid=" gsheetID, % tempCSV
    while !FileExist(tempCSV)
        Sleep 50
    return
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
strRepeat(str, count) {
    return strReplace(format( "{:" count "}",  "" ), " ", str)
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
strUPPER(str) {
	stringUpper, strUPPER, str
	return strUPPER
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
quote(str) {
    return Chr(34) . str . Chr(34)
}



; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
;;       class
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
class LNCHR_COMMANDS_GENERATOR {
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    __New() {
        this.cmd := ""
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    commands_start() {
        this.cmd .= "lngui_run_commands(input) {" . "`n`n"
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    replaceme_query_header() {
        this.cmd .= Chr(59) . " " strRepeat("/", 100)       . "`n"
                .   Chr(59) . "   COMMANDS - RUN_COMMAND"   . "`n"
                .   Chr(59) . " " strRepeat("/", 100)       . "`n`n"
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    replaceme_query(command, COMMAND_UPPER, description, replaceme_baseurl, field1, field2) {
        if ( field2 == "" )
            this.cmd    .=  "if (input == " quote(command) " || input == " quote(COMMAND_UPPER) ") { " . Chr(59) . " " . description . "`n"
                        .   "lngui_enable_query(" quote(description) ", make_run_ReplaceTexts_func(" quote(command) ", " quote(replaceme_baseurl) ", " quote(field1) "))" . "`n"
                        .   "return"    . "`n"
                        .   "}"         . "`n`n"
                        .   Chr(59) . " _______________________________________________" . "`n`n"
        else
            this.cmd    .=  "if (input == " quote(command) " || input == " quote(COMMAND_UPPER) ") { " . Chr(59) . " " . description . "`n"
                        .   "lngui_enable_query(" quote(description) ", make_run_ReplaceTexts_func(" quote(command) ", " quote(replaceme_baseurl) . ", " quote(field1 "," field2) "))" . "`n"
                        .   "return"    . "`n"
                        .   "}"         . "`n`n"
                        .   Chr(59) . " _______________________________________________" . "`n`n"  
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    run_command_header() {
        this.cmd .= Chr(59) . " " strRepeat("/", 100)       . "`n"
                .   Chr(59) . "   COMMANDS - RUN_COMMAND"   . "`n"
                .   Chr(59) . " " strRepeat("/", 100)       . "`n`n"
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    run_command(command, COMMAND_UPPER, description, field1) {
        this.cmd .= "if (input == " quote(command) " || input == " quote(COMMAND_UPPER) ") { " . Chr(59) . " " . description . "`n"
                .   "close_lngui()"             . "`n"
                .   "TryRun('" . field1 . "')"  . "`n"
                .   "return"                    . "`n"
                .   "}"                         . "`n`n"
                .   Chr(59) . " _______________________________________________" . "`n`n"
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    send_keys_header() {
        this.cmd .= Chr(59) . " " strRepeat("/", 100)   . "`n"
                .   Chr(59) . "   COMMANDS - SEND_KEYS" . "`n"
                .   Chr(59) . " " strRepeat("/", 100)   . "`n`n"
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    send_keys(command, COMMAND_UPPER, description, field1) {
        this.cmd .= "if (input == " quote(command) " || input == " quote(COMMAND_UPPER) ") { " . Chr(59) . " " . description . "`n"
                .   "close_lngui()"         . "`n"
                .   "Send '" . field1 . "'" . "`n"
                .   "return"                . "`n"
                .   "}"                     . "`n`n"
                .   Chr(59) . " _______________________________________________" . "`n`n"
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    run_command_without_closing_gui_header() {
        this.cmd .= Chr(59) . " " strRepeat("/", 100)                           . "`n"
                .   Chr(59) . "   COMMANDS - RUN_COMMAND_WITHOUT_CLOSING_GUI"   . "`n"
                .   Chr(59) . " " strRepeat("/", 100)                           . "`n`n"
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    run_command_without_closing_gui(command, COMMAND_UPPER, description, field1) {
        this.cmd .= "if (input == " quote(command) " || input == " quote(COMMAND_UPPER) ") { " . Chr(59) . " " . description . "`n"
                .   field1      . "`n"
                .   "return"    . "`n"
                .   "}"         . "`n`n"
                .   Chr(59) . " _______________________________________________" . "`n`n"
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    close_gui_then_run_command_header() {
        this.cmd .= Chr(59) . " " strRepeat("/", 100)                       . "`n"
                .   Chr(59) . "   COMMANDS - CLOSE_GUI_THEN_RUN_COMMAND"    . "`n"
                .   Chr(59) . " " strRepeat("/", 100)                       . "`n`n"
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    close_gui_then_run_command(command, COMMAND_UPPER, description, field1) {
        this.cmd .= "if (input == " quote(command) " || input == " quote(COMMAND_UPPER) ") { " . Chr(59) . " " . description . "`n"
                .   "close_lngui()" . "`n"
                .   "WinActivate " quote("ahk_id ") " IniRead(A_Temp " quote("\AutoHotkey\lnchr_ini.ini") ", " quote("lnchr_info") ", " quote("active_id") ")" . "`n"
                .   field1          . "`n"
                .   "return"        . "`n"
                .   "}"             . "`n`n"
                .   Chr(59)     . " _______________________________________________" . "`n`n"
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    regex_check_header() {
        this.cmd .= Chr(59) . " " strRepeat("/", 100)       . "`n"
                .   Chr(59) . "   COMMANDS - REGEX_CHECK"   . "`n"
                .   Chr(59) . " " strRepeat("/", 100)       . "`n`n"
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    regex_check(command, description, field1) {
        this.cmd .= "if "   . command . "(input) { " . Chr(59) . " " . description  . "`n"
                .   "close_lngui()"   . "`n"
                .   field1            . "`n"
                .   "return"          . "`n"
                .   "}"               . "`n`n"
                .   Chr(59) . " _______________________________________________" . "`n`n"
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    commands_end() {
        this.cmd .= "}" 
    }
    ; ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
    GET_COMMANDS() {
        return this.cmd
    }
}