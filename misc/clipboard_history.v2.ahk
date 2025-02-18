#Requires AutoHotkey v2.0
#SingleInstance Force
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
;   required libraries
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#include <JSON\cJSON.v2>    ; https://github.com/G33kDude/cJson.ahk
#include <Array\Array.v2>   ; https://github.com/Descolada/AHK-v2-libraries/blob/main/Lib/Array.ahk
; ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


clipboard_history()


class clipboard_history {   ;   inspired by CL3 ahkv1   - https://github.com/hi5/CL3 

    static menu_width       := 60
    static history_json     := A_ScriptDir '\clip_history.json'

    ; ═══════════════════════════════════════════════════════════════════

    __New() {
        this.clip_history   := []
        this.max_history    := 52 
        this.app_icons      := Map()
        this.TRAY_MENU      := A_TrayMenu
        FileExist(clipboard_history.history_json)  ? '' : FileAppend('', clipboard_history.history_json)
        this.init_tray_menu()
        this.load_saved_history()
        OnClipboardChange(this.handle_clipboard_change.Bind(this))
        HotKey('^!v', this.show_history_menu.Bind(this))                ; currently CTRL + ALT + V triggers the menu but you can this to whatever you want
        OnExit(this.save_history.Bind(this))
    }

    ; ═══════════════════════════════════════════════════════════════════

    init_tray_menu() {
        this.TRAY_MENU.Delete()
        this.TRAY_MENU.Add('Show History',  this.show_history_menu.Bind(this))
        this.TRAY_MENU.Add('Clear History', this.clear_history.Bind(this))
        this.TRAY_MENU.Add()
        this.TRAY_MENU.Add('Edit Script',   (*) => Edit())
        this.TRAY_MENU.Add('Open Folder',   (*) => (SplitPath(A_ScriptFullPath,,&dir), Run(dir)))
        this.TRAY_MENU.Add('Reload Script', (*) => Reload())
        this.TRAY_MENU.Add('Exit Script',   (*) => ExitApp())
    }

    ; ═══════════════════════════════════════════════════════════════════

    handle_clipboard_change(data_type) {
        if (data_type != 1)
            return
        
        clip_text       := A_Clipboard
        active_win      := ''
        try active_win  := WinGetProcessPath('A')
        try crc         := this.crc32(clip_text)
        
        if (clip_text = '' || this.crc_exists_in_clip_history(crc))
            return
            
        this.clip_history.InsertAt(1, Map(
            'text', clip_text,
            'app',  active_win,
            'crc',  crc,
            'time', A_Now
        ))
        
        while (this.clip_history.Length > this.max_history)
            this.clip_history.Pop()
            
        this.save_history()
    }

    ; ═══════════════════════════════════════════════════════════════════
    
    show_history_menu(*) {
        if (this.clip_history.Length = 0) {
            MsgBox('No clipboard history available.')
            return
        }
        
        HISTORY_MENU := Menu()
        MORE_MENU    := Menu()
        
        for index, item in this.clip_history {
            if (index <= 25) {
                menu_text   := Chr(96 + index) '. ' this.format_menu_text(item['text'])
                target_menu := HISTORY_MENU
                bind_index  := index
            } else if (index == 26) {
                HISTORY_MENU.Add()
                HISTORY_MENU.Add('z.            ━━━━━━━━━━━━━━━━    MORE HISTORY    ━━━━━━━━━━━━━━━━   ', MORE_MENU)
                menu_text   := 'a. ' this.format_menu_text(item['text'])  
                target_menu := MORE_MENU
                bind_index  := index
            } else if (index <= 51) { 
                menu_text   := Chr(96 + (index - 25)) '. ' this.format_menu_text(item['text'])  
                target_menu := MORE_MENU
                bind_index  := index
            }
            
            target_menu.Add(menu_text, this.paste_clip.Bind(this, bind_index))
            
            try {
                if !this.app_icons.Has(item['app'])
                    this.app_icons[item['app']] := LoadPicture(item['app'])
                target_menu.SetIcon(menu_text, item['app'])
            }
        }
        
        try HISTORY_MENU.Show()
    }
    
    ; ═══════════════════════════════════════════════════════════════════
    
    paste_clip(clip_index, *) {
        if (clip_index > this.clip_history.Length)
            return
        OnClipboardChange(this.handle_clipboard_change.Bind(this), 0)
        selected_item := this.clip_history[clip_index]
        this.clip_history.RemoveAt(clip_index)
        this.clip_history.InsertAt(1, selected_item)
        A_Clipboard := selected_item['text']
        this.save_history()
        Send('^v')
        OnClipboardChange(this.handle_clipboard_change.Bind(this), 1)
    }

    ; ═══════════════════════════════════════════════════════════════════
    
    format_menu_text(text) {
        text := RegExReplace(text, '\s+', ' ')
        return StrLen(text) > clipboard_history.menu_width 
            ? SubStr(text, 1, clipboard_history.menu_width) ' ➞'
            : text
    }
    
    ; ═══════════════════════════════════════════════════════════════════
    
    clear_history(*) {
        this.clip_history := []
        this.save_history()
        MsgBox('Clipboard history cleared.')
    }
    
    ; ═══════════════════════════════════════════════════════════════════
    
    save_history(*) {
        try {
            if (this.clip_history.Length > 0) {
                history_json := JSON.DUMP(this.clip_history)
                FileDelete(clipboard_history.history_json)
                FileAppend(history_json, clipboard_history.history_json)
            }
        } catch Error as e {
            MsgBox('Error saving history: ' e.Message)
        }
    }
    
    ; ═══════════════════════════════════════════════════════════════════
    
    load_saved_history() {
        try {
            if FileExist(clipboard_history.history_json) {
                saved_content := FileRead(clipboard_history.history_json)
                if (saved_content != '') {
                    this.clip_history := JSON.LOAD(saved_content)
                }
            }
        } catch Error as e {
            MsgBox('Error loading history: ' e.Message)
        }
    }
    
    ; ═══════════════════════════════════════════════════════════════════
    
    crc32(input_str, encoding:='UTF-8') {
        bytes_per_char  := (encoding = 'CP1200' || encoding = 'UTF-16') ? 2 : 1
        str_size        := (StrPut(input_str, encoding) - 1) * bytes_per_char
        memory_buffer   := Buffer(str_size, 0)
        StrPut(input_str, memory_buffer, str_size / bytes_per_char, encoding)
        checksum        := DllCall('ntdll.dll\RtlComputeCrc32', 'UInt', 0, 'Ptr', memory_buffer, 'UInt', str_size)
        return Format('{:#x}', checksum)
    }
    
    ; ═══════════════════════════════════════════════════════════════════
    
    crc_exists_in_clip_history(crc) => 
        this.clip_history.Find((c)  => c['crc'] == crc) ? true : false

}
