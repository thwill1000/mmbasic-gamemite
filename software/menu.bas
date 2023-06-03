' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Base 0
Option Default None
Option Explicit On

'!define NO_INCLUDE_GUARDS

#Include "splib/system.inc"

'!if defined PICOMITEVGA
  '!replace { Page Copy 1 To 0 , B } { FrameBuffer Copy F , N , B }
  '!replace { Page Write 1 } { FrameBuffer Write F }
  '!replace { Page Write 0 } { FrameBuffer Write N }
  '!replace { Mode 7 } { Mode 2 : FrameBuffer Create }
'!elif defined PICOMITE
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

If sys.is_device%("mmb4w", "cmm2*") Then Option Console Serial
Mode 7
Page Write 1

main()
Error "Invalid state"

Sub main()
  Local ctrl$ = Choice(sys.is_device%("pglcd2"), "ctrl.pglcd2", "keys_cursor_ext")
  ctrl.init_keys()
  sys.override_break()
  Call ctrl$, ctrl.OPEN
  sound.init()
  menu.init(ctrl$, "menu_cb")
  menu.load_data("main_menu_data")
  menu.render()
  menu.main_loop()
End Sub

Sub keys_cursor_ext(x%)
  If x% < 0 Then Exit Sub
  x% =    ctrl.keydown%(32)  * ctrl.A ' Space
  Inc x%, ctrl.keydown%(98)  * ctrl.B ' B
  Inc x%, (ctrl.keydown%(101) Or ctrl.keydown%(113)) * ctrl.SELECT ' E or Q
  Inc x%, ctrl.keydown%(115) * ctrl.START ' S
  Inc x%, ctrl.keydown%(128) * ctrl.UP
  Inc x%, ctrl.keydown%(129) * ctrl.DOWN
  Inc x%, ctrl.keydown%(130) * ctrl.LEFT
  Inc x%, ctrl.keydown%(131) * ctrl.RIGHT
End Sub

Sub menu_cb(cb_data$)
  Select Case Field$(cb_data$, 1, "|")
    Case "ctrl"
      ctrl_cb(cb_data$)
    Case "open", "select"
      ' Do nothing.
    Case "render"
      render_cb(cb_data$)
    Case Else
      Error "Invalid state"
  End Select
End Sub

Sub ctrl_cb(cb_data$)
  Select Case Field$(cb_data$, 2, "|")
    Case "b", "start":
      menu.play_invalid_fx(1)
    Case "select"
      cmd_exit(ctrl.A)
    Case Else
      Error "Invalid state"
  End Select
End Sub

Sub render_cb(cb_data$)
  If sys.is_device%("pglcd") Then
    Const footer$ = str.decode$("Use \x92 \x93 and A to select ")
  Else
    Const footer$ = str.decode$("Use \x92 \x93 and SPACE to select")
  EndIf
  twm.print_at(1, menu.height% - 3, str.centre$(footer$, menu.width% - 2))
End Sub

Sub cmd_run(key%)
  If key% <> ctrl.A Then menu.play_invalid_fx(1) : Exit Sub
  menu.play_valid_fx(1)
  menu.term("Loading " + str.trim$(Field$(menu.items$(menu.selection%), 1, "|")) + " ...")
  Local f$ = Field$(menu.items$(menu.selection%), 3, "|"), orig$ = f$, x%
  If Not InStr("A:/B:/", UCase$(Left$(f$, 3))) Then
    f$ = "A:/pglcd/" + orig$
    x% = Mm.Info(Exists File f$)
    If Not x% Then
      f$ = "B:/pglcd/" + orig$
      On Error Skip
      x% = Mm.Info(Exist File f$)
      If Mm.ErrNo Then x% = 0
      If Not x% Then f$ = "A:/pglcd/" + orig$
    EndIf
  EndIf
  x% = Mm.Info(Exists File f$)
  If Not x% Then menu.term(f$ + " not found") : End
  Run f$
End Sub

Sub cmd_exit(key%)
  If key% <> ctrl.A Then menu.play_invalid_fx(1) : Exit Sub
  menu.play_valid_fx(1)
  Const msg$ = str.decode$("Are you sure you want to Exit to BASIC?\n\n(Serial connection reqd.)")
  Select Case YES_NO_BTNS$(menu.msgbox%(msg$, YES_NO_BTNS$(), 1))
    Case "Yes"
      menu.term("Exited to BASIC")
      End
    Case "No"
      twm.switch(menu.win1%)
      twm.redraw()
      Page Copy 1 To 0 , B
    Case Else
      Error "Invalid state"
  End Select
End Sub

main_menu_data:
Data "\x9F PicoGAME LCD \x9F"
Data "Controller Test|cmd_run|ctrl-demo-2.bas"
Data "  Sound Test   |cmd_run|sound-demo.bas"
Data "  Lazer Cycle  |cmd_run|lazer-cycle.bas"
Data "  PicoVaders   |cmd_run|pico-vaders.bas"
Data "    3D Maze    |cmd_run|3d-maze.bas"
Data "|"
Data "Exit to BASIC|cmd_exit"
Data ""
