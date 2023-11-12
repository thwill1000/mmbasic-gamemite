' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

' Boot menu for the GameMite.

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

#Include "splib/ctrl.inc"
#Include "splib/sound.inc"
#Include "splib/string.inc"
#Include "splib/txtwm.inc"
#Include "splib/menu.inc"

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
  menu.load_data("main_menu_data")
  If sys.is_device%("gamemite") Then
    menu.items$(Bound(menu.items$(), 1)) = str.decode$("Use \x92 \x93 and SELECT|")
  EndIf
  menu.render(1)
  menu.main_loop()
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
End Sub

'!dynamic_call cmd_run
Sub cmd_run(key%)
  Select Case key%
    Case ctrl.A, ctrl.START, ctrl.SELECT
      menu.play_valid_fx(1)
      menu.term("Loading " + str.trim$(Field$(menu.items$(menu.selection%), 1, "|")) + " ...")
      Local f$ = Field$(menu.items$(menu.selection%), 3, "|"), orig$ = f$, x%
      If Not InStr("A:/B:/", UCase$(Left$(f$, 3))) Then
        f$ = "A:/GameMite/" + orig$
        x% = Mm.Info(Exists File f$)
        If Not x% Then
          f$ = "B:/GameMite/" + orig$
          On Error Skip
          x% = Mm.Info(Exist File f$)
          If Mm.ErrNo Then x% = 0
          If Not x% Then f$ = "A:/GameMite/" + orig$
        EndIf
      EndIf
      x% = Mm.Info(Exists File f$)
      If Not x% Then menu.term(f$ + " not found") : End
      Run f$
      Error "Invalid state"

    Case ctrl.B
      cmd_exit(ctrl.SELECT)

    Case Else
      menu.play_invalid_fx(1)

    End Select
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

    Case Else
      menu.play_invalid_fx(1)
  End Select
End Sub

main_menu_data:
Data "GameMite|"
Data "|"
Data "   Controller Test    |cmd_run|ctrl-demo-2.bas"
Data "      Sound Test      |cmd_run|sound-demo.bas"
Data "     Lazer Cycle      |cmd_run|lazer-cycle.bas"
Data "      PicoVaders      |cmd_run|pico-vaders.bas"
Data " Yellow River Kingdom |cmd_run|kingdom.bas"
Data "       3D Maze        |cmd_run|3d-maze.bas"
Data "     File Browser     |cmd_run|fm.bas"
Data "|"
Data " Exit to BASIC |cmd_exit"
Data "|"
Data "|"
Data "|"
Data "|"
Data "|"
Data "Use \x92 \x93 and SPACE to select|"
Data ""
