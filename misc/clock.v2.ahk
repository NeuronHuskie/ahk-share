#Requires Autohotkey v2.0+
#SingleInstance Force 
#include <Tooltip\WiseGui\WiseGui> ; https://www.autohotkey.com/boards/viewtopic.php?f=83&t=94044
; _______________________________________________________________________________
Loop {
    current_time := FormatTime(A_Now, 'h:mm:ss tt')
    current_date := FormatTime(A_Now, 'LongDate')

    WiseGui(
          'Clock'
        , 'FontMain:    s28 Norm, Source Sans Pro Black'
        , 'FontSub:     s13 Norm, Source Sans Pro SemiBold'
        , 'MainText:    ' current_time
        , 'SubText:     ' current_date
        , 'TextWidth:   350'
        , 'MainAlign:   0'
        , 'SubAlign:    0'
        , 'Theme:       0x037682, 0x041B2D, 0x037682, 0'
        , 'Trans:       220'
        , 'Show:        Fade@400ms'
        , 'Hide:        Fade@400ms'
        , 'Move:       , -1'
    )

    Sleep(1000)
}
; _______________________________________________________________________________
^Esc::ExitApp()
