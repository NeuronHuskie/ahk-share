#Requires Autohotkey v2.0+
; -----------------------------------
; 	misc text/string functions
; -----------------------------------



quote(string, single_quote:=false) => ( single_quote ) ? Chr(39) . string . Chr(39) : Chr(34) . string . Chr(34)
; _________________________________________
strRepeat(str, count) => strReplace(format( "{:" count "}",  "" ), " ", str)
; _________________________________________
ThousandsSeparator(int) => RegExReplace(int, "(?(?<=\.)(*COMMIT)(*FAIL))\d(?=(\d{3})+(\D|$))", "$0,")
; _________________________________________
InStrList(str, list*) {
    for i, item in list 
        if InStr(str, item)
            return true
    return false
}
; _________________________________________
ClipSave() {
    bak         := ClipboardAll()
    A_Clipboard := ''
    Send('^c')
    ClipWait('.5')
    clipSave    := A_Clipboard
    A_Clipboard := bak
    bak         := ''
    return clipSave
}
; _________________________________________
SendClip(str) {
    bak := ClipboardAll()
    A_Clipboard := str
	BlockInput true
    Send('^v')
    Loop 20
        Sleep 50
    Until !DllCall('GetOpenClipboardWindow')
	BlockInput false
    A_Clipboard := bak
}
; _________________________________________
Letter2Number(input) {
    input   := StrLower(input) 
    len     := StrLen(input)
    num     := 0
    Loop Parse, input {
        thisNum := Ord(A_LoopField) - 96 
        num += thisNum * (26 ** (len - A_Index))
    }
    return num
}
; _________________________________________
Number2Letter(input, UPPER:=0) {   
    Loop ((input-1) // 26) + 1 	{
        letter := Chr(Mod(input-1, 26) + Ord('a'))
        if ( UPPER == 1 )
            letter := strUPPER(letter)
        out .= letter
    }
    return out
}
; _________________________________________
String2Number(string) {
    if ( string == "" )
        return ""
    else {
        num := StrReplace(string, ",")
        num := StrReplace(num, "$")
        num := num + 0.00                           
        num := Round(num, 2)
        return num
    }
}
