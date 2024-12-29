#Requires Autohotkey v2.0+


modify_delimiter_gui() {
    active_win  := WinActive('A')
    tmp         := A_Clipboard
    ; ╔──────────────────────────────────────────────────╗
    ; ║                define delimiters                 ║
    ; ╚──────────────────────────────────────────────────╝
    DELIMITERS := Map(
        'comma',        ',',
        'newline',      '`n',
        'pipe',         '|',
        'semi-colon',   ';',
        'space',        ' ',
        'tab',          '`t',
        'custom',       '' 
    )
    ; ╔──────────────────────────────────────────────────╗
    ; ║                     make gui                     ║
    ; ╚──────────────────────────────────────────────────╝
    MonitorGetWorkArea(, &monitor_left, &monitor_top, &monitor_right, &monitor_bottom)
    monitor_width := (monitor_right - monitor_left)
    monitor_height := (monitor_bottom - monitor_top)
    gui_width := Min(monitor_width * 0.6, 1600)
    gui_height := Min(monitor_height * 0.6, 900)
    control_width := ((gui_width - 60) / 2)
    ; ___________________________________________________________
    main_gui := Gui('+LastFound +ToolWindow -Caption +Border', 'Modify Clip Delimiter')
    main_gui.Opt('+DPIScale')
    main_gui.BackColor := '041B2D'
    main_gui.MarginX := 20
    main_gui.MarginY := 20
    ; ╔──────────────────────────────────────────────────╗
    ; ║                current delimiter                 ║
    ; ╚──────────────────────────────────────────────────╝
    main_gui.SetFont('cFFFFFF s11', 'Source Sans Pro')
    main_gui.Add('Text', 'x10 y10', 'Current delimiter:')
    current_delimiter := main_gui.Add('DropDownList', 'xp+200 yp w200 Choose1 vCurrentDelimiter', DELIMITERS.Keys)
    current_custom_delimiter := main_gui.Add('Edit', 'x+10 yp w100 vCurrentCustomDelimiter Hidden')
    ; ╔──────────────────────────────────────────────────╗
    ; ║                  new delimiter                   ║
    ; ╚──────────────────────────────────────────────────╝
    main_gui.Add('Text', 'x10 y+10', 'New delimiter:')
    new_delimiter := main_gui.Add('DropDownList', 'xp+200 yp w200 Choose1 vNewDelimiter', DELIMITERS.Keys)
    main_gui.SetFont('c000000 s11', 'Source Sans Pro')
    new_custom_delimiter := main_gui.Add('Edit', 'x+10 yp w100 vNewCustomDelimiter Hidden')
    ; ╔──────────────────────────────────────────────────╗
    ; ║             keep existing delimiter?             ║
    ; ╚──────────────────────────────────────────────────╝
    main_gui.SetFont('cFFFFFF s11', 'Source Sans Pro')
    main_gui.Add('Text', 'x10 y+10', 'Keep existing delimiter?')
    keep_existing_delimiter := main_gui.Add('Checkbox', 'xp+200 yp Choose0 vKeepExistingDelimiter')
    ; ╔──────────────────────────────────────────────────╗
    ; ║                 wrap in quotes?                  ║
    ; ╚──────────────────────────────────────────────────╝
    main_gui.Add('Text', 'x10 y+10', 'Wrap in quotes?')
    wrap_quotes := main_gui.Add('Checkbox', 'xp+200 yp Choose1 vWrapQuotes')
    ; ╔──────────────────────────────────────────────────╗
    ; ║             single or double quotes?             ║
    ; ╚──────────────────────────────────────────────────╝
    main_gui.Add('Text', 'x10 y+10 vQuotesTypeLabel', 'Single or double quotes?')
    quotes_type := main_gui.Add('DropDownList', 'xp+200 yp w200 Choose1 vQuotesType', [quote('Single',1), quote('Double')])
    ; ╔──────────────────────────────────────────────────╗
    ; ║                clipboard preview                 ║
    ; ╚──────────────────────────────────────────────────╝
    main_gui.Add('Text', 'x10 y+20 w' . control_width, 'Clipboard preview:')
    main_gui.SetFont('c14E0E8 s11', 'Source Sans Pro')
    current_content := main_gui.Add('Edit', 'x10 y+5 w' control_width ' h' (gui_height - 275) ' +Background041B2D ReadOnly vCurrentContent', tmp)
    ; ╔──────────────────────────────────────────────────╗
    ; ║                  output preview                  ║
    ; ╚──────────────────────────────────────────────────╝
    main_gui.SetFont('cFFFFFF s11', 'Source Sans Pro')
    main_gui.Add('Text', 'x' (control_width + 40) ' yp-25 w' control_width, 'Output preview:')
    main_gui.SetFont('c14E0E8 s11', 'Source Sans Pro')
    preview_edit := main_gui.Add('Edit', 'x' (control_width + 40) ' yp+25 w' control_width ' h' (gui_height - 275) ' +Background041B2D ReadOnly vPreview')
    ; ___________________________________________________________
    main_gui.Add('Button', 'x' (gui_width / 2 - 200) ' y' (gui_height - 40) ' w400 Default', 'Apply changes to clipboard').OnEvent('Click', (*) => replace_delimiters(tmp, main_gui))
    ; ___________________________________________________________
    current_delimiter.OnEvent('Change', (*) => toggle_custom_delimiter(main_gui, 'Current'))
    new_delimiter.OnEvent('Change', (*) => toggle_custom_delimiter(main_gui, 'New'))
    current_custom_delimiter.OnEvent('Change', (*) => update_preview(main_gui))
    new_custom_delimiter.OnEvent('Change', (*) => update_preview(main_gui))
    keep_existing_delimiter.OnEvent('Click', (*) => update_preview(main_gui))
    wrap_quotes.OnEvent('Click', (*) => update_preview(main_gui))
    quotes_type.OnEvent('Change', (*) => update_preview(main_gui))    
    main_gui.OnEvent('Close', (*) => main_gui.Destroy())
    ; ___________________________________________________________
    current_delimiter.Text := (detect_delimiter(tmp) != '') ? detect_delimiter(tmp) : 'comma'
    ; ___________________________________________________________
    main_gui.Show('w' gui_width ' h' gui_height)
    ; ___________________________________________________________
    update_preview(main_gui)
    ; ╔──────────────────────────────────────────────────╗
    ; ║                 detect_delimiter                 ║
    ; ╚──────────────────────────────────────────────────╝
    detect_delimiter(content) {
        max_count := 0
        detected_delimiter := ''
        ; ___________________________________________________________
        for delimiter_name, delimiter in DELIMITERS {
            if (delimiter_name == 'custom')
                continue
            count := (delimiter = '`n') 
                  ? StrSplit(content, '`n', '`r').Length - 1 
                  : StrSplit(content, delimiter).Length - 1  
            if (count > max_count) {
                max_count := count
                detected_delimiter := delimiter_name
            }
        }
        ; ___________________________________________________________
        return detected_delimiter
    }
    ; ╔──────────────────────────────────────────────────╗
    ; ║             toggle_custom_delimiter              ║
    ; ╚──────────────────────────────────────────────────╝
    toggle_custom_delimiter(gui, prefix) {
        if (gui[prefix 'Delimiter'].Text == 'custom') {
            gui[prefix 'CustomDelimiter'].Visible := true
        } else {
            gui[prefix 'CustomDelimiter'].Visible := false
        }
        update_preview(gui)
    }
    ; ╔──────────────────────────────────────────────────╗
    ; ║                  update preview                  ║
    ; ╚──────────────────────────────────────────────────╝
    update_preview(gui) {
        gui['QuotesTypeLabel'].Visible  := gui['WrapQuotes'].Value == 1 ? true : false
        gui['QuotesType'].Visible       := gui['WrapQuotes'].Value == 1 ? true : false
        ; ___________________________________________________________
        current_content := gui['CurrentContent'].Value
        current_delimiter_name := gui['CurrentDelimiter'].Text
        new_delimiter_name := gui['NewDelimiter'].Text
        current_delimiter := (current_delimiter_name == 'custom') ? gui['CurrentCustomDelimiter'].Text : DELIMITERS[current_delimiter_name]
        new_delimiter := (new_delimiter_name == 'custom') ? gui['NewCustomDelimiter'].Text : DELIMITERS[new_delimiter_name]
        ; ___________________________________________________________
        split_array := (current_delimiter = '`n') 
                    ? StrSplit(current_content, '`n', '`r') 
                    : (current_delimiter = '`t') 
                        ? StrSplit(current_content, '`t') 
                        : StrSplit(current_content, current_delimiter)
        ; ___________________________________________________________
        preview := ''
        ; ___________________________________________________________
        for i, item in split_array {
            trimmed_item := Trim(item)

            quoted_item := (gui['WrapQuotes'].Value == 1) 
                        ? (gui['QuotesType'].Text == quote('Single', 1))
                            ? quote(trimmed_item, 1) 
                            : quote(trimmed_item)
                        : trimmed_item
            
            preview .= quoted_item
            
            preview .= (gui['KeepExistingDelimiter'].Value == 1) 
                    ? new_delimiter . ((i < split_array.Length) 
                        ? current_delimiter 
                        : '')
                    : ((i < split_array.Length) 
                        ? new_delimiter 
                        : '')
        }
        ; ___________________________________________________________
        gui['Preview'].Value := preview
    }
    ; ╔──────────────────────────────────────────────────╗
    ; ║                replace delimiters                ║
    ; ╚──────────────────────────────────────────────────╝
    replace_delimiters(tmp, gui) {
        current_delimiter_name := gui['CurrentDelimiter'].Text
        new_delimiter_name := gui['NewDelimiter'].Text
        current_delimiter := (current_delimiter_name == 'custom') ? gui['CurrentCustomDelimiter'].Text : DELIMITERS[current_delimiter_name]
        new_delimiter := (new_delimiter_name == 'custom') ? gui['NewCustomDelimiter'].Text : DELIMITERS[new_delimiter_name]
        ; ___________________________________________________________
        split_array := (current_delimiter = '`n') 
                    ? StrSplit(tmp, '`n', '`r') 
                    : (current_delimiter = '`t') 
                        ? StrSplit(tmp, '`t') 
                        : StrSplit(tmp, current_delimiter)
        ; ___________________________________________________________
        output := ''
        ; ___________________________________________________________
        for i, item in split_array {
            trimmed_item := Trim(item)

            quoted_item := (gui['WrapQuotes'].Value == 1)
                        ? (gui['QuotesType'].Text == quote('Single', 1))
                            ? quote(trimmed_item, 1)
                            : quote(trimmed_item)
                        : trimmed_item

            output .= quoted_item

            output .= (gui['KeepExistingDelimiter'].Value == 1)
                   ? new_delimiter . ((i < split_array.Length) 
                        ? current_delimiter 
                        : '')
                    : ((i < split_array.Length) 
                        ? new_delimiter 
                        : '')
        }
        ; ___________________________________________________________
        gui.Destroy()
        ; ___________________________________________________________
        CustomMsgBox('Copy or send formatted clip?', 'Copy', 'Send') == 'Copy' 
            ? A_Clipboard := output 
            : (WinActivate('ahk_id ' active_win), WinWaitActive('ahk_id ' active_win), SendClip(output))
        ; ___________________________________________________________
        ExitApp
    }
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
  CustomMsgBox(prompt, btn1_name, btn2_name, title:='Custom MsgBox') {
    change_button_names(*) {
        if !WinExist(title)
            return
        SetTimer(change_button_names, 0)
        WinActivate()
        ControlSetText('&' btn1_name, 'Button1')
        ControlSetText('&' btn2_name, 'Button2')
    }
    ; ___________________________________________________________
    SetTimer(change_button_names, 50)
    ; ___________________________________________________________
    return ( MsgBox(prompt, title, 4) = 'Yes' ) 
        ? btn1_name 
        : btn2_name
}
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
SendClip(str) {
    bak := ClipboardAll()
    A_Clipboard := str
	BlockInput('On')
    Send('^v')
    Loop 20
        Sleep 50
    Until !DllCall('GetOpenClipboardWindow')
	BlockInput('Off')
    A_Clipboard := bak
}
