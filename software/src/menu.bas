' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

' Boot menu for the Game*Mite.

Option Base 0
Option Default None
Option Explicit On

'!define NO_INCLUDE_GUARDS

#Include "splib/system.inc"

'!if defined(PICOMITEVGA)
  '!replace { Page Copy 1 To 0 , B } { FrameBuffer Copy F , N , B }
  '!replace { Page Write 1 } { FrameBuffer Write F }
  '!replace { Page Write 0 } { FrameBuffer Write N }
  '!replace { Mode 7 } { Mode 2 : FrameBuffer Create }
'!elif defined(PICOMITE) || defined(GAMEMITE)
  '!replace { Page Copy 1 To 0 , B } { FrameBuffer Copy F , N }
  '!replace { Page Write 1 } { FrameBuffer Write F }
  '!replace { Page Write 0 } { FrameBuffer Write N }
  '!replace { Mode 7 } { FrameBuffer Create }
'!endif

#Include "splib/array.inc"
#Include "splib/ctrl.inc"
#Include "splib/sound.inc"
#Include "splib/string.inc"
#Include "splib/txtwm.inc"
#Include "splib/menu.inc"
#Include "splib/gamemite.inc"

Const MAX_NUM_PROGS = 100
Const PROGS_PER_PAGE = 10

Dim prog_list$(MAX_NUM_PROGS - 1) Length 127
Dim menu.items$(15) Length 127
Dim num_progs%
Dim cur_page%
Dim num_pages%

If sys.is_device%("mmb4l") Then Option CodePage MMB4L
If sys.is_device%("mmb4w", "cmm2*") Then Option Console Serial
Mode 7
Page Write 1

main()
Error "Invalid state"

Sub main()
  '!dynamic_call ctrl.gamemite
  '!dynamic_call keys_cursor_ext
  Const ctrl$ = Choice(sys.is_device%("gamemite"), "ctrl.gamemite", "keys_cursor_ext")
  ctrl.init_keys()
  sys.override_break()
  Call ctrl$, ctrl.OPEN
  sound.init()
  menu.init(ctrl$, "menu_cb")
  read_programs()
  update_menu_data()
  menu.render(1)
  menu.main_loop()
End Sub

Sub read_programs()
  Const f$ = sys.HOME$() + "/.gm-menu"
  If Not Mm.Info(Exists File f$) Then
    Open f$ For Output As #1
    Print #1, "Controller Test,ctrl-demo-2.bas"
    Print #1, "Sound Test,sound-demo.bas"
    Print #1, "Lazer Cycle,lazer-cycle.bas"
    Print #1, "PicoVaders,pico-vaders.bas"
    Print #1, "The Circle Game,circle.bas"
    Print #1, "Yellow River Kingdom,kingdom.bas"
    Print #1, "3D Maze,3d-maze.bas"
    Print #1, "File Browser,fm.bas"
    Close #1
  EndIf

  array.fill(prog_list$(), "")
  Local i%, s$
  Open f$ For Input As #1
  num_progs% = 0
  Do
    If Eof(#1) Then Exit Do
    Line Input #1, s$
    s$ = str.trim$(s$)
    If s$ = "" Then Continue Do
    prog_list$(num_progs%) = s$
    Inc num_progs%
  Loop Until num_progs% = MAX_NUM_PROGS
  Close #1

  num_pages% = num_progs% \ PROGS_PER_PAGE + ((num_progs% Mod PROGS_PER_PAGE) > 0)
  If num_pages% = 0 Then num_pages% = 1
  cur_page% = 1
End Sub

Sub update_menu_data()
  Local i%, j%, s$, width% = 15
  menu.items$(i%) = "GameMite|" : Inc i%
  menu.items$(i%) = "|" : Inc i%

  ' Determine maximum menu-item width (+2)
  Const begin% = (cur_page% - 1) * PROGS_PER_PAGE
  For j% = begin% To begin% + PROGS_PER_PAGE - 1
    If j% >= num_progs% Then Exit For
    width% = Max(width%, 2 + Len(Field$(prog_list$(j%), 1, ",")))
  Next
  width% = Min(width%, menu.width% - 10)

  ' Add programs to menu.
  For j% = begin% To begin% + PROGS_PER_PAGE - 1
    If j% >= num_progs% Then Exit For
    s$ = str.centre$(Field$(prog_list$(j%), 1, ","), width%)
    If Len(s$) > menu.width% - 10 Then
      s$ = Left$(s$, 3) + "..." + Right$(s$, menu.width% - 16)
    EndIf
    menu.items$(i%) = s$ + "|cmd_run|" + Field$(prog_list$(j%), 2, ",")
    Inc i%
  Next

  If i% = 2 Then menu.items$(i%) = "No programs found!|" : Inc i%

  ' Fill remaining entries with blanks.
  For i% = i% To Bound(menu.items$(), 1) - 4 : menu.items$(i%) = "|" : Next

  menu.items$(i%) = "|" : Inc i%
  menu.items$(i%) = " Exit to BASIC |cmd_exit" : Inc i%
  menu.items$(i%) = "|" : Inc i%
  menu.items$(i%) = "Use "
  If num_pages% > 1 Then Cat menu.items$(i%), "\x95 \x94 "
  Cat menu.items$(i%), "\x92 \x93 and "
  Cat menu.items$(i%), Choice(sys.is_device%("gamemite"), "SELECT", "and SPACE to select")
  Cat menu.items$(i%), "|"
  menu.items$(i%) = str.decode$(menu.items$(i%))
  Inc i%

  menu.item_count% = i%

  ' Select the first selectable item.
  If Field$(menu.items$(menu.selection%), 2, "|") = "" Then
    For menu.selection% = 0 To menu.item_count% - 1
      If Field$(menu.items$(menu.selection%), 2, "|") <> "" Then Exit For
    Next
  EndIf
End Sub

'!dynamic_call menu_cb
Sub menu_cb(cb_data$)
  Select Case Field$(cb_data$, 1, "|")
    Case "render"
      on_render()
    Case "selection_changed"
      ' Do nothing.
    Case Else
      Error "Invalid state"
  End Select
End Sub

Sub on_render()
  ' Fiddle with the title so that the spacing around the star looks good.
  Const y% = 2 * Mm.Info(FontHeight)
  Text 163 - 5 * Mm.Info(FontWidth), y%, "Game   ", , 1, 1, Rgb(Yellow)
  Text 158, y%, " Mite", , 1, 1, Rgb(Yellow)
  Text 160, y%, Chr$(&h9F), CT, 1, 1, Rgb(Yellow)

  ' Show page indicator.
  If num_pages% > 1 Then
    Const s$ = "Page " + Str$(cur_page%) + "/" + Str$(num_pages%)
    twm.print_at(menu.width% - Len(s$) - 2, menu.height% - 2, s$)
  EndIf
End Sub

'!dynamic_call cmd_run
Sub cmd_run(key%)
  Select Case key%
    Case ctrl.A, ctrl.START, ctrl.SELECT
      menu.play_valid_fx(1)
      run_program(Field$(menu.items$(menu.selection%), 3, "|"))

    Case ctrl.B
      cmd_exit(ctrl.SELECT)

    Case ctrl.LEFT, ctrl.RIGHT
      change_page(key%)

    Case Else
      menu.play_invalid_fx(1)

    End Select
End Sub

Sub run_program(orig$)
  Const f$ = gamemite.file$(orig$)

  If Not Mm.Info(Exists File f$) Then
    Const msg$ = str.decode$("Program not found:\n\n" + f$)
    Local tmp% = menu.msgbox%(msg$, menu.OK_BTN$(), 0)
    twm.switch(menu.win1%)
    twm.redraw()
    on_render()
    Page Copy 1 To 0 , B
    Exit Sub
  EndIf

  menu.term("Loading " + str.trim$(Field$(menu.items$(menu.selection%), 1, "|")) + " ...")
  Run f$
  Error "Invalid state"
End Sub

Sub change_page(key%)
  If (num_pages% = 1) Or (key% <> ctrl.RIGHT And key% <> ctrl.LEFT) Then
    menu.play_invalid_fx(1)
  Else
    menu.play_valid_fx(1)
    Inc cur_page%, Choice(key% = ctrl.RIGHT, 1, -1)
    Select Case cur_page%
      Case < 1 : cur_page% = num_pages%
      Case > num_pages% : cur_page% = 1
    End Select
    update_menu_data()
    menu.render()
  EndIf
End Sub

'!dynamic_call cmd_exit
Sub cmd_exit(key%)
  Select Case key%
    Case ctrl.A, ctrl.START, ctrl.SELECT
      menu.play_valid_fx(1)
      Const msg$ = str.decode$("Are you sure you want to Exit to BASIC?\n\n(Serial connection reqd.)")
      Select Case YES_NO_BTNS$(menu.msgbox%(msg$, YES_NO_BTNS$(), 1))
        Case "Yes"
          menu.term("Exited to BASIC")
          End
        Case "No"
          twm.switch(menu.win1%)
          twm.redraw()
          on_render()
          Page Copy 1 To 0 , B
        Case Else
          Error "Invalid state"
      End Select

    Case ctrl.LEFT, ctrl.RIGHT
      change_page(key%)

    Case Else
      menu.play_invalid_fx(1)
  End Select
End Sub
