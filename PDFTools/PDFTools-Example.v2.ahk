#Requires Autohotkey v2.0+
#WinActivateForce
#SingleInstance Force
; ▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪
; #include <array\Peep.v2>
; ▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪▪
ESC:: OnExit()
; ╔──────────────────────────────────────────────────╗
; ║             data for fillable pdf                ║
; ╚──────────────────────────────────────────────────╝
EXAMPLE_DATA := {       first_name: 'Jane',
                        last_name:  'Doe',
                        company:    'Company XYZ',
                        tax_class:  'S-Corporation',
                        street:     '123 Main St',
                        city:       'Anytown',
                        state:      'NY',
                        zip:        '99999',
                        ein:        '12-3456789'    }
; ╔───────────────────────────────────────────────────────────────────────────╗
; ║ prepare data for PDF form                                                 ║
; ║                                                                           ║
; ║ the var names must match the XFDF field temp values (without the %)       ║
; ║                                                                           ║
; ║ eg. <field name="fullname_entityname"><value>%fullname%</value></field>   ║
; ║                                                                           ║
; ║ name your var 'fullname' so it will replace the temp value of %fullname%  ║
; ╚───────────────────────────────────────────────────────────────────────────╝
OUTPUT_FORM_DATA := {   fullname                    : EXAMPLE_DATA.first_name ' ' EXAMPLE_DATA.last_name,
                        businessname                : EXAMPLE_DATA.company,
                        street_address              : EXAMPLE_DATA.street,
                        city_state_zip              : EXAMPLE_DATA.city ', ' EXAMPLE_DATA.state ' ' EXAMPLE_DATA.zip,
                        ssn_1                       : ( EXAMPLE_DATA.HasOwnProp("ssn") )                                                            ? SubStr(EXAMPLE_DATA.ssn, 1, 3)    : "",
                        ssn_2                       : ( EXAMPLE_DATA.HasOwnProp("ssn") )                                                            ? SubStr(EXAMPLE_DATA.ssn, 5, 2)    : "",
                        ssn_3                       : ( EXAMPLE_DATA.HasOwnProp("ssn") )                                                            ? SubStr(EXAMPLE_DATA.ssn, 9, 4)    : "",
                        ein_1                       : ( EXAMPLE_DATA.HasOwnProp("ein") )                                                            ? SubStr(EXAMPLE_DATA.ein, 1, 2)    : "",
                        ein_2                       : ( EXAMPLE_DATA.HasOwnProp("ein") )                                                            ? SubStr(EXAMPLE_DATA.ein, 4)       : "",
                        taxclass_ind_soleprop       : ( InStr(EXAMPLE_DATA.tax_class, 'Individual') || InStr(EXAMPLE_DATA.tax_class, 'Sole Prop') ) ? 1                                 : "",
                        taxclass_ccorp              : ( InStr(EXAMPLE_DATA.tax_class, 'C-Corp') )                                                   ? 1                                 : "",
                        taxclass_scorp              : ( InStr(EXAMPLE_DATA.tax_class, 'S-Corp') )                                                   ? 1                                 : "",
                        taxclass_partnership        : ( InStr(EXAMPLE_DATA.tax_class, 'Partnership') )                                              ? 1                                 : "",
                        taxclass_trust_estate       : ( InStr(EXAMPLE_DATA.tax_class, 'Trust') || InStr(EXAMPLE_DATA.tax_class, 'Estate') )         ? 1                                 : "",
                        taxclass_llc                : ( InStr(EXAMPLE_DATA.tax_class, 'LLC') )                                                      ? 1                                 : "",
                        taxclass_other              : ( InStr(EXAMPLE_DATA.tax_class, 'Other') )                                                    ? 1                                 : "",
                        exempt_payee_code           : ( EXAMPLE_DATA.HasOwnProp("exempt_payee_code") )                                              ? EXAMPLE_DATA.exempt_payee_code    : "",
                        fatca_code                  : ( EXAMPLE_DATA.HasOwnProp("fatca_code") )                                                     ? EXAMPLE_DATA.facta_code           : "",
                        foreign_partners            : ( EXAMPLE_DATA.HasOwnProp("foreign_partners") )                                               ? 1                                 : "",
                        account_numbers             : ( EXAMPLE_DATA.HasOwnProp("account_numbers") )                                                ? EXAMPLE_DATA.account_numbers      : "" }
; ╔──────────────────────────────────────────────────╗
; ║               set file/path vars                 ║
; ╚──────────────────────────────────────────────────╝
master_pdf_path     := A_ScriptDir  '\templates\W9-MASTER.pdf'
master_xfdf_path    := A_ScriptDir  '\templates\W9-MASTER.xfdf'
pdf_form_name       := 'W9'
output_dir          := A_Desktop    '\' EXAMPLE_DATA.first_name ' ' EXAMPLE_DATA.last_name
temp_dir            := output_dir   '\temp'
fn                  := EXAMPLE_DATA.first_name ' ' EXAMPLE_DATA.last_name ' - W9 ' A_YYYY '-' A_MM '-' A_DD
output_pdf_path     := output_dir   '\' fn '.pdf' 
temp_pdf_path       := temp_dir     '\' fn '.pdf'
temp_xfdf_path      := temp_dir     '\' fn '.xfdf'
; ╔──────────────────────────────────────────────────╗
; ║     copy master/template files to temp dir       ║
; ╚──────────────────────────────────────────────────╝
while !DirExist(temp_dir)
    DirCreate(temp_dir)
while !FileExist(temp_pdf_path)
    FileCopy(master_pdf_path, temp_pdf_path)
; ╔────────────────────────────────────────────────────────────────────────────────────────╗
; ║ read master xfdf + replace with data from output data object + create temp xfdf file   ║
; ╚────────────────────────────────────────────────────────────────────────────────────────╝
xfdf := FileRead(master_xfdf_path, 'UTF-8')
; _________________________________________
for key, value in OUTPUT_FORM_DATA.OwnProps() {
    if InStr(xfdf, "%" key "%")
        xfdf := StrReplace(xfdf, "%" key "%", value)
    if InStr(xfdf, "%" key "%")
        xfdf := StrReplace(xfdf, "%" key "%", "")
}
; _________________________________________
FileAppend(xfdf, temp_xfdf_path, 'UTF-8')
; ╔──────────────────────────────────────────────────╗
; ║      get pdftools 'toolid' + run pdftools        ║
; ╚──────────────────────────────────────────────────╝
pdftools_id := GetPDFToolsID(pdf_form_name)
; _________________________________________
RunPDFTools(pdftools_id, temp_pdf_path, output_pdf_path) 
; ╔──────────────────────────────────────────────────╗
; ║        delete temp files + exit script           ║
; ╚──────────────────────────────────────────────────╝
DirDelete(temp_dir,1)
MsgBox('Done!')
ExitApp
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
;   get pdftools toolid
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
GetPDFToolsID(form_name) {
    TOOL_IDS := Map(
        'W2'    , '{1111111111111111111111111}' ,
        'W4'    , '{9999999999999999999999999}' ,
        'W9'    , '{5A281CDC-2394-4EBF-885075D937A7317F}'
    )
    ; _________________________________________
    return TOOL_IDS[form_name]
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
;   run pdf tools
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
RunPDFTools(tool_id, input_pdf_path, output_pdf_path) {
    SplitPath(output_pdf_path, &output_pdf_fn, &output_pdf_dir)
    ; _________________________________________
    pdftools_path   := '"C:\Program Files\Tracker Software\PDF Tools\PDFXTools.exe"'
    input_params    := '/RunTool:showui=no;showprog=no;showrep=no ' '"' tool_id '" "' input_pdf_path '"' 
    output_params   := '/Output:folder="' output_pdf_dir '";filename="' output_pdf_fn '";overwrite=yes'
    ; _________________________________________
    RunWait(A_ComSpec ' /c "' pdftools_path ' ' input_params ' ' output_params '"')
    return
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
;   delete temp files + exit script
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
OnExit() {
    try DirDelete(temp_dir,1)
    ExitApp
}
