' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

' Limited "File Manager" for the Game*Mite.

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
#Include "splib/file.inc"
#Include "splib/txtwm.inc"
#Include "splib/menu.inc"
#Include "splib/gamemite.inc"

If sys.is_device%("mmb4l") Then Option CodePage CMM2
If sys.is_device%("mmb4w", "cmm2*") Then Option Console Serial

Const MAX_FILES = 500
Const FILES_PER_PAGE = 12

If sys.is_device%("gamemite") Then
  Const num_drives% = 2
  Dim drives$(num_drives% - 1) = ("A:/", "B:/")
Else
  Const num_drives% = 1
  Dim drives$(1) = ("/", "/")
EndIf
Dim drive_idx% = 0
Dim file_list$(MAX_FILES + 1) Length 64 ' MAX_FILES + 2 elements
Dim menu.items$(15) Length 127
Dim num_files%
Dim cur_page%
Dim num_pages%

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
  update_files()
  update_menu_data()
  menu.render(1)
  menu.main_loop()
End Sub

Sub update_files()
  ' Check for existence of drive.
  On Error Skip
  Local s$ = Dir$(drives$(drive_idx%))
  If Mm.ErrNo Then num_files% = -1 : Exit Sub

  num_files% = file.get_files%(drives$(drive_idx%), "*", "all", file_list$())
  If (num_files% > MAX_FILES) Then
    file_list$(MAX_FILES) = "... and " + Str$(num_files% - MAX_FILES) + " more"
    num_files% = MAX_FILES + 1
  EndIf

  ' Shift all the enties in file_list$() one element to the right.
  If Len(file.get_parent$(drives$(drive_idx%))) Then
    Const p% = Peek(VarAddr file_list$())
    Memory Copy p%, p% + 65, 65 * (MAX_FILES + 1)
    file_list$(0) = ".."
    Inc num_files%
  EndIf

  num_pages% = num_files% \ FILES_PER_PAGE + ((num_files% Mod FILES_PER_PAGE) > 0)
  cur_page% = 1
End Sub

Sub update_menu_data()
  Local i%, j%, s$

  s$ = drives$(drive_idx%) + Choice(Right$(drives$(drive_idx%), 1) = "/", "", "/")
  If Len(s$) > menu.width% - 10 Then
    s$ = Left$(s$, 3) + "..." + Right$(s$, menu.width% - 16)
  EndIf
  If num_drives% > 1 Then
     menu.items$(i%) = str.decode$(" \x95 " + s$ + " \x94 ") + "|cmd_drive"
  Else
     menu.items$(i%) = " " + s$ + " |"
  EndIf
  Inc i%
  menu.items$(i%) = "|"
  Inc i%

  If num_files% = -1 Then
    menu.items$(i%) = "Drive not found|"
    Inc i%
  Else
    Const begin% = (cur_page% - 1) * FILES_PER_PAGE
    For j% = begin% To begin% + FILES_PER_PAGE - 1
      If j% >= num_files% Then Exit For
      s$ = file_list$(j%)
      If file.is_directory%(drives$(drive_idx%) + "/" + file_list$(j%)) Then Cat s$, "/"
      If Len(s$) > menu.width% - 10 Then
        s$ = Left$(s$, 3) + "..." + Right$(s$, menu.width% - 16)
      EndIf
      menu.items$(i%) = " " + str.rpad$(s$, 26) + " |cmd_open|" + Str$(j%)
      If i% = Bound(menu.items$(), 1) - 1 Then Exit For
      Inc i%
    Next
  EndIf

  ' Fill remaining entries with blanks.
  For i% = i% To Bound(menu.items$(), 1) - 1 : menu.items$(i%) = "|" : Next

  If sys.is_device%("gamemite") Then
    menu.items$(i%) = str.decode$("Use \x95 \x94 \x92 \x93 and SELECT|")
  Else
    menu.items$(i%) = str.decode$("Use \x95 \x94 \x92 \x93 and SPACE to select|")
  EndIf

  menu.item_count% = i% + 1
  If Not Len(Field$(menu.items$(menu.selection%), 2, "|")) Then
    For menu.selection% = 0 To menu.item_count% - 1
      If Len(Field$(menu.items$(menu.selection%), 2, "|")) Then Exit For
    Next
  EndIf
End Sub

'!dynamic_call menu_cb
Sub menu_cb(cb_data$)
  Select Case Field$(cb_data$, 1, "|")
    Case "selection_changed"
      ' Do nothing.
    Case "render"
      on_render(cb_data$)
    Case Else
      Error "Invalid state"
  End Select
End Sub

Sub on_render(cb_data$)
  Const s$ = "Page " + Str$(cur_page%) + "/" + Str$(num_pages%)
  twm.print_at(menu.width% - Len(s$) - 2, menu.height% - 2, s$)
End Sub

'!dynamic_call cmd_drive
Sub cmd_drive(key%)
  Local update% = 0

  Select Case key%
    Case ctrl.B
      If Len(file.get_parent$(drives$(drive_idx%))) Then
        update% = 1
        drives$(drive_idx%) = file.get_parent$(drives$(drive_idx%))
      EndIf

    Case ctrl.LEFT, ctrl.RIGHT
      update% = 1
      Inc drive_idx%, Choice(key% = ctrl.RIGHT, 1, -1)
      Select Case drive_idx%
        Case < 0 : drive_idx% = num_drives% - 1
        Case >= num_drives% : drive_idx% = 0
      End Select

    Case ctrl.START
      on_start()
      Exit Sub
  End Select

  If update% Then
    menu.play_valid_fx(1)
    update_files()
    update_menu_data()
    menu.render()
  Else
    menu.play_invalid_fx(1)
  EndIf
End Sub

'!dynamic_call cmd_open
Sub cmd_open(key%)
  Select Case key%
    Case ctrl.A, ctrl.SELECT
      Local f$ = Field$(menu.items$(menu.selection%), 1, "|")
      Local file_idx% = Val(Field$(menu.items$(menu.selection%), 3, "|"))
      If Right$(f$, 1) = "/" Then
        menu.play_valid_fx(1)
        If f$ = "../" Then
          drives$(drive_idx%) = file.get_parent$(drives$(drive_idx%))
        Else
          If Right$(drives$(drive_idx%), 1) <> "/" Then Cat drives$(drive_idx%), "/"
          Cat drives$(drive_idx%), file_list$(file_idx%)
        EndIf
        update_files()
        update_menu_data()
        menu.render()
      Else
        Select Case LCase$(file.get_extension$(file_list$(file_idx%)))
          Case ".bas"
            menu.play_valid_fx(1)
            open_bas(file_idx%)
          Case ".flac", ".mod", ".wav"
            menu.play_valid_fx(1)
            play_music(file_idx%)
          Case Else
            menu.play_invalid_fx(1)
        End Select
      EndIf

    Case ctrl.B
      If Len(file.get_parent$(drives$(drive_idx%))) Then
        menu.play_valid_fx(1)
        drives$(drive_idx%) = file.get_parent$(drives$(drive_idx%))
        update_files()
        update_menu_data()
        menu.render()
      Else
        menu.play_invalid_fx(1)
      EndIf

    Case ctrl.LEFT, ctrl.RIGHT
      If num_pages% = 1 Then
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

    Case ctrl.START
      on_start()

    Case Else
      menu.play_invalid_fx(1)
  End Select
End Sub

Sub open_bas(file_idx%)
  Local f$ = drives$(drive_idx%)
  If Right$(f$, 1) <> "/" Then Cat f$, "/"
  Cat f$, file_list$(file_idx%)
  menu.term("Loading " + file.get_name$(f$) + " ...")
  If Mm.Info(Exists File f$) Then
    Run f$
  Else
    menu.term(file.get_name$(f$) + " not found")
    End
  EndIf
  Error "Invalid state"
End Sub

Sub play_music(file_idx%)
  Local f$ = drives$(drive_idx%), key%
  If Right$(f$, 1) <> "/" Then Cat f$, "/"
  Cat f$, file_list$(file_idx%)
  Local ext$ = LCase$(file.get_extension$(f$))
  sound.term()

  If ext$ = ".flac" And sys.is_device%("pm*") Then
    ' Free enough memory to play .flac file.
    Local old_cur_page% = cur_page%
    Erase file_list$()
    Erase menu.items$()
    FrameBuffer Close F
  EndIf

  Select Case ext$
    Case ".flac"
      Play Flac f$, play_stop_cb
    Case ".mod"
      ' TODO: Currently no mechanism to determine end of .mod file.
      Play Modfile f$
    Case ".wav"
      Play Wav f$, play_stop_cb
    Case Else
      Error "Invalid state"
  End Select

  ctrl.wait_until_idle(menu.ctrl$)
  Do While key% = 0
    If sys.break_flag% Then menu.on_break()
    Call menu.ctrl$, key%
    If Not key% Then keys_cursor(key%)
  Loop

  play_stop_cb()

  If ext$ = ".flac" And sys.is_device%("pm*") Then
    ' Restore state after playing .flac file.
    FrameBuffer Create
    FrameBuffer Write F
    Dim file_list$(MAX_FILES + 1) Length 64
    Dim menu.items$(15) Length 127
    update_files()
    cur_page% = old_cur_page%
    update_menu_data()
    menu.render(1)
  EndIf

  ' TODO: This is a recursive call and may potentially blow up.
  menu.process_key(key%)
End Sub

'!dynamic_call play_stop_cb
Sub play_stop_cb()
  Play Stop
  sound.init()
End Sub

Sub on_start()
  menu.play_valid_fx(1)
  Const msg$ = str.decode$("\nAre you sure you want to quit this program?")
  Select Case YES_NO_BTNS$(menu.msgbox%(msg$, YES_NO_BTNS$(), 1))
    Case "Yes"
      gamemite.end()
    Case "No"
      twm.switch(menu.win1%)
      twm.redraw()
      Page Copy 1 To 0 , B
    Case Else
      Error "Invalid state"
  End Select
End Sub
