#Requires Autohotkey v2.0+
#SingleInstance Force 
#include <GUI\GetInput.v2>
#include <Tooltip\WiseGui\WiseGui> ; https://www.autohotkey.com/boards/viewtopic.php?f=83&t=94044
TraySetIcon(A_ScriptDir '\_icons\timer.png')
; _______________________________________________________________________________
timer_minutes               := InputBox('How many minutes should the timer be set for?', 'timerGUI').Value
; _______________________________________________________________________________
if ( timer_minutes != '' ) {
  timer_end                 := DateAdd(A_Now, timer_minutes, 'Minutes')
  timer_end_time_h_mm_ss_tt := FormatTime(timer_end, 'h:mm tt')
  ; _______________________________________________________________________________
  Loop {
    timer_left_seconds      := DateDiff(timer_end, A_Now, 'Seconds')
    ; __________________________________________
    hours         := Floor(timer_left_seconds / 3600)
    minutes       := Floor(Mod(timer_left_seconds, 3600) / 60)
    seconds       := Mod(timer_left_seconds, 60)
    timer_left    := ( hours > 0 ) ? Format('{:02d}:{:02d}:{:02d}', hours, minutes, seconds) : Format('{:02d}:{:02d}', minutes, seconds)
    ; __________________________________________
    theme_red     := '0xFFFFFF, 0x660000, 0xFFFFFF, 0'
    theme_default := '0x037682, 0x041B2D, 0x037682, 0'
    ; __________________________________________
    theme :=  (timer_minutes >= 60  && minutes < 15)                        ? theme_red
          :   (timer_minutes < 60   && timer_minutes > 30 && minutes < 10)  ? theme_red
          :   (timer_minutes <= 30  && timer_minutes > 10 && minutes < 5)   ? theme_red
          :   (timer_minutes <= 10  && minutes < 3)                         ? theme_red
          :   theme_default
    ; __________________________________________
    WiseGui(  
        'Timer'
      , 'FontMain:    s12 Norm, Source Sans Pro'
      , 'FontSub:     s24 Bold, Source Sans Pro Black'
      , 'MainText:    Your ' timer_minutes ' minute timer will be up at ' timer_end_time_h_mm_ss_tt
      , 'SubText:'    timer_left
      , 'TextWidth:   400'
      , 'MainAlign:   0'
      , 'SubAlign:    0'
      , 'Theme:'      theme
      , 'Trans:       220'
      , 'Show:        Fade@400ms'
      , 'Hide:        Fade@400ms'
      , 'Move:       , -1'
    )
    ; __________________________________________       
    Sleep(1000)
  } until ( timer_left_seconds <= 0 )
  MsgBox('Timer has finished!')
}
; _______________________________________________________________________________
WinExist('WiseGui\Timer ahk_class AutoHotkeyGUI') ? WinClose() : ''
ExitApp
^Esc::ExitApp
