' Transpiled on 06-03-2023 14:09:17

' Copyright (c) 2022-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.06

Option Base 0
Option Default None
Option Explicit On
' Option LcdPanel NoConsole

' Preprocessor flag PICOGAME_LCD defined

' BEGIN:     #Include "ctrl.inc" -----------------------------------------------
' Copyright (c) 2022-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
'
' MMBasic Controller Library

' Preprocessor flag PICOMITE defined
' Preprocessor flag CTRL_ONE_PLAYER defined
' Preprocessor flag CTRL_NO_SNES defined
' Preprocessor flag CTRL_USE_INKEY defined

Const ctrl.VERSION = 907  ' 0.9.7

' Button values as returned by controller driver subroutines.
Const ctrl.R      = &h01
Const ctrl.START  = &h02
Const ctrl.HOME   = &h04
Const ctrl.SELECT = &h08
Const ctrl.L      = &h10
Const ctrl.DOWN   = &h20
Const ctrl.RIGHT  = &h40
Const ctrl.UP     = &h80
Const ctrl.LEFT   = &h100
Const ctrl.ZR     = &h200
Const ctrl.X      = &h400
Const ctrl.A      = &h800
Const ctrl.Y      = &h1000
Const ctrl.B      = &h2000
Const ctrl.ZL     = &h4000

Const ctrl.OPEN  = -1
Const ctrl.CLOSE = -2
Const ctrl.SOFT_CLOSE = -3

' The NES standard specifies a 12 micro-second pulse, but all the controllers
' I've tested work with 1 micro-second, and possibly less.
Const ctrl.PULSE = 0.001 ' 1 micro-second

' When a key is down the corresponding byte of this 256-byte map is set,
' when the key is up then it is unset.
'
' Note that when using INKEY$ (as opposed to the CMM2 'KEYDOWN' function or
' the PicoMiteVGA 'ON PS2' command) to read the keyboard we cannot detect
' keyup events and instead automatically clear a byte after it is read.
Dim ctrl.key_map%(31 + Mm.Info(Option Base))

' Initialises keyboard reading.
'
' @param  period%  CMM2 only - interval to read KEYDOWN state, default 40 ms.
' @param  nbr%     CMM2 only - timer nbr to read KEYDOWN state, default 4.
Sub ctrl.init_keys(period%, nbr%)
  ctrl.term_keys()
  On Key ctrl.on_key()
  ' Read Save
  ' Restore ctrl.scan_map_data
  ' Local i%
  ' For i% = Bound(ctrl.scan_map%(), 0) To Bound(ctrl.scan_map%(), 1)
  '   Read ctrl.scan_map%(i%)
  ' Next
  ' Read Restore
  ' On Ps2 ctrl.on_ps2()
End Sub

' TODO: use the 'lower-case' character for all keys, not just letters.
Sub ctrl.on_key()
  Poke Var ctrl.key_map%(), Asc(LCase$(Inkey$)), 1
End Sub

' Terminates keyboard reading.
Sub ctrl.term_keys()
   On Key 0
  ' On Ps2 0
  Memory Set Peek(VarAddr ctrl.key_map%()), 0, 256
  Do While Inkey$ <> "" : Loop
End Sub

Function ctrl.keydown%(i%)
  ctrl.keydown% = Peek(Var ctrl.key_map%(), i%)
   Poke Var ctrl.key_map%(), i%, 0
End Function

Function ctrl.poll_multiple$(drivers$(), mask%, duration%)
  Local expires% = Choice(duration%, Timer + duration%, &h7FFFFFFFFFFFFFFF), i%
  Do
    For i% = Bound(drivers$(), 0) To Bound(drivers$(), 1)
      If ctrl.poll_single%(drivers$(i%), mask%) Then
        ctrl.poll_multiple$ = drivers$(i%)
        Exit Do
      EndIf
    Next
  Loop While Timer < expires%
End Function

' Opens, polls (for a maximum of 5ms) and closes a controller.
'
' @param  driver$  controller driver function.
' @param  mask%    bit mask to match against.
' @return          1 if any of the bits in the mask match what is read from the
'                  controller, otherwise 0.
Function ctrl.poll_single%(driver$, mask%)
  On Error Ignore
  Call driver$, ctrl.OPEN
  If Mm.ErrNo = 0 Then
    Local key%, t% = Timer + 5
    Do
      Call driver$, key%
      If key% And mask% Then
        ctrl.poll_single% = 1
        ' Wait for user to release key.
        Do While key% : Pause 5 : Call driver$, key% : Loop
        Exit Do
      EndIf
    Loop While Timer < t%
    Call driver$, ctrl.SOFT_CLOSE
  EndIf
  On Error Abort
End Function

' Gets a string representation of bits read from a controller driver.
'
' @param  x%  bits returned by driver.
' @return     string representation.
Function ctrl.bits_to_string$(x%)
  Static BUTTONS$(14) = ("R","Start","Home","Select","L","Down","Right","Up","Left","ZR","X","A","Y","B","ZL")

  If x% = 0 Then
    ctrl.bits_to_string$ = "No buttons down"
    Exit Function
  EndIf

  ctrl.bits_to_string$ = Str$(x%) + " = "
  Local count%, i%, s$
  For i% = 0 To Bound(BUTTONS$(), 1)
    If x% And 2^i% Then
      s$ = BUTTONS$(i%)
      If count% > 0 Then Cat ctrl.bits_to_string$, ", "
      Cat ctrl.bits_to_string$, s$
      Inc count%
    EndIf
  Next
End Function

' Reads the keyboard as if it were a controller.
'
' Note that the PicoMite has no KEYDOWN function so we are limited to
' reading a single keypress from the input buffer and cannot handle multiple
' simultaneous keys or properly handle a key being pressed and not released.
Sub keys_cursor(x%)
  If x% < 0 Then Exit Sub
  x% =    ctrl.keydown%(32)  * ctrl.A
  Inc x%, ctrl.keydown%(128) * ctrl.UP
  Inc x%, ctrl.keydown%(129) * ctrl.DOWN
  Inc x%, ctrl.keydown%(130) * ctrl.LEFT
  Inc x%, ctrl.keydown%(131) * ctrl.RIGHT
End Sub

' Atari joystick on PicoGAME Port A.
Sub atari_a(x%)
  Select Case x%
    Case >= 0
      x% =    Not Pin(GP14) * ctrl.A
      Inc x%, Not Pin(GP0)  * ctrl.UP
      Inc x%, Not Pin(GP1)  * ctrl.DOWN
      Inc x%, Not Pin(GP2)  * ctrl.LEFT
      Inc x%, Not Pin(GP3)  * ctrl.RIGHT
      Exit Sub
    Case ctrl.OPEN
      SetPin GP0, DIn : SetPin GP1, DIn : SetPin GP2, DIn : SetPin GP3, DIn : SetPin GP14, DIn
    Case ctrl.CLOSE, ctrl.SOFT_CLOSE
      SetPin GP0, Off : SetPin GP1, Off : SetPin GP2, Off : SetPin GP3, Off : SetPin GP14, Off
  End Select
End Sub

' Reads port A connected to a NES gamepad.
'
' Note that the extra pulse after reading bit 7 (Right) should not be necessary,
' but in practice some NES clone controllers require it to behave correctly.
'
'   GP2: Latch, GP3: Clock, GP1: Data
Sub nes_a(x%)
  Select Case x%
    Case >= 0
      Pulse GP2, ctrl.PULSE
      x% =    Not Pin(GP1) * ctrl.A      : Pulse GP3, ctrl.PULSE
      Inc x%, Not Pin(GP1) * ctrl.B      : Pulse GP3, ctrl.PULSE
      Inc x%, Not Pin(GP1) * ctrl.SELECT : Pulse GP3, ctrl.PULSE
      Inc x%, Not Pin(GP1) * ctrl.START  : Pulse GP3, ctrl.PULSE
      Inc x%, Not Pin(GP1) * ctrl.UP     : Pulse GP3, ctrl.PULSE
      Inc x%, Not Pin(GP1) * ctrl.DOWN   : Pulse GP3, ctrl.PULSE
      Inc x%, Not Pin(GP1) * ctrl.LEFT   : Pulse GP3, ctrl.PULSE
      Inc x%, Not Pin(GP1) * ctrl.RIGHT  : Pulse GP3, ctrl.PULSE
      Exit Sub
    Case ctrl.OPEN
      SetPin GP1, Din : SetPin GP2, Dout : SetPin GP3, Dout
      Pin(GP2) = 0 : Pin(GP3) = 0
      nes_a(0) ' Discard the first reading.
    Case ctrl.CLOSE, ctrl.SOFT_CLOSE
      SetPin GP1, Off : SetPin GP2, Off : SetPin GP3, Off
  End Select
End Sub

' END:       #Include "src/ctrl.inc" -------------------------------------------
' BEGIN:     #Include "utility.inc" --------------------------------------------
' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.06

' Utility code lifted from 'splib'.

' Pads a string with spaces to the left and right so that it will be centred
' within a fixed length field. If the string is longer than the field then
' this function just returns the string. If an odd number of spaces are
' required then the extra space is added to the left hand side of the string.
'
' @param  s$  the string to centre.
' @param  x   the field length.
Function str.centre$(s$, x%)
  If Len(s$) < x% Then
    str.centre$ = s$ + Space$((x% - Len(s$)) \ 2)
    str.centre$ = Space$(x% - Len(str.centre$)) + str.centre$
  Else
    str.centre$ = s$
  EndIf
End Function

' Gets bit i% of x%.
Function bits.get%(x%, i%)
  If i% < 0 Or i% > 63 Then Error "i% out of 0 .. 63 range"
  bits.get% = (x% And 1 << i%) <> 0
End Function

Function str.lpad$(s$, x%)
  str.lpad$ = s$
  If Len(s$) < x% Then str.lpad$ = Space$(x% - Len(s$)) + s$
End Function

' Gets a string "quoted" with given characters.
'
' @param  s$      the string.
' @param  begin$  the character to put at the start, defaults to double-quote.
' @param  end$    the character to put at the end, defaults to double-quote.
' @return         the "quoted" string.
Function str.quote$(s$, begin$, end$)
  Local begin_$ = Choice(begin$ = "", Chr$(34), Left$(begin$, 1))
  Local end_$ = Choice(end$ = "", begin_$, Left$(end$, 1))
  str.quote$ = begin_$ + s$ + end_$
End Function

' Gets a string padded to a given width with spaces to the right.
'
' @param  s$  the string.
' @param  w%  the width.
' @return     the padded string.
'             If Len(s$) > w% then returns the unpadded string.
Function str.rpad$(s$, x%)
  str.rpad$ = s$
  If Len(s$) < x% Then str.rpad$ = s$ + Space$(x% - Len(s$))
End Function

' Returns a copy of s$ with leading and trailing spaces removed.
Function str.trim$(s$)
  Local st%, en%
  For st% = 1 To Len(s$)
    If Peek(Var s$, st%) <> 32 Then Exit For
  Next
  For en% = Len(s$) To 1 Step -1
    If Peek(Var s$, en%) <> 32 Then Exit For
  Next
  If en% >= st% Then str.trim$ = Mid$(s$, st%, en% - st% + 1)
End Function

Function format_version$(version%)
  Local major% = version% \ 10000
  Local minor% = (version% - major% * 10000) \ 100
  Local micro% = version% - major% * 10000 - minor% * 100
  format_version$ = Str$(major%) + "." + Str$(minor%) + "." + Str$(micro%)
End Function
' END:       #Include "src/utility.inc" ----------------------------------------
' BEGIN:     #Include "sound.inc" ----------------------------------------------
' Copyright (c) 2022-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.06

' Preprocessor flag SOUND_USE_PWM defined

SetPin GP4,PWM2A
SetPin GP6,PWM3A

Const sound.MAX_TRACK_LEN% = 1024
Const sound.NUM_MUSIC_CHANNELS% = 3

' These would be constants but MMBasic does not support constant arrays
Dim sound.F!(127)
Dim sound.NO_MUSIC%(1)  = (&h0000000000000000, &hFFFFFFFF00000000)
Dim sound.FX_NONE%(1)   = (&hFFFFFFFFFFFFFFFF, &hFFFFFFFFFFFFFFFF)
Dim sound.FX_BLART%(1)  = (&hFFFFFF0036373C3D, &hFFFFFFFFFFFFFFFF)
Dim sound.FX_SELECT%(1) = (&hFFFFFFFF0048443C, &hFFFFFFFFFFFFFFFF)
Dim sound.FX_DIE%(3)    = (&h4748494A4B4C4D4E, &h3F40414243444546, &h0038393A3B3C3D3E, &hFFFFFFFFFFFFFFFF)
Dim sound.FX_WIPE%(3)   = (&h3F3E3D3C3B3A3938, &h4746454443424140, &h004E4D4C4B4A4948, &hFFFFFFFFFFFFFFFF)
Dim sound.FX_READY_STEADY_GO%(12)

Dim sound.music_start_ptr%
Dim sound.music_ptr%
Dim sound.current_track%
Dim sound.num_tracks%
Dim sound.fx_enabled% = 1
Dim sound.fx_ptr% = Peek(VarAddr sound.FX_NONE%())

' Initialises sound engine.
Sub sound.init(track1$, track2$)
  Local i%

  ' sound.F!(0) - rest
  ' sound.F!(1) - C0   - 16.35 Hz
  For i% = 0 To 127
    sound.F!(i%) = 440 * 2^((i% - 58) / 12.0)
  Next

  Read Save
  Restore sound.ready_steady_go_data:
  For i% = 0 To 12
    Read sound.FX_READY_STEADY_GO%(i%)
  Next
  Read Restore

  If track1$ = "" Then
    sound.play_music(sound.NO_MUSIC%())
  Else
    sound.num_tracks% = 2
    Local tracks$(sound.num_tracks%) Length 32
    tracks$(1) = track1$
    tracks$(2) = Choice(track2$ = "", track1$, track2$)

    ' 2D array indexed (notes, tracks) because that is the way
    ' incrementing a pointer through the data naturally works.
    Dim sound.MUSIC%((sound.MAX_TRACK_LEN% \ 8) - 1, sound.num_tracks% - 1)

    Local count%, j%, num_channels%, track$
    For i% = 1 to sound.num_tracks%
      track$ = tracks$(i%)
      Restore track$
      Read count%, num_channels%
      If count% > sound.MAX_TRACK_LEN% Then
        Local err$ = "Track '" + track$ + "' is too long; "
        Error err$ + "expected " + Str$(sound.MAX_TRACK_LEN%) + " bytes but found " + Str$(count%)
      EndIf
      If num_channels% <> sound.NUM_MUSIC_CHANNELS% Then
        Local err$ = "Track '" + track$ + "' has wrong number of channels; "
        Error err$ + "expected " + Str$(sound.NUM_CHANNELS%) + ", but found " + Str$(num_channels%)
      EndIf
      For j% = 1 To count% \ 8
        Read sound.MUSIC%(j% - 1, i% - 1)
      Next j%
    Next

    sound.play_music(sound.MUSIC%())
  EndIf

  ' Music and sound effects are played on SetTick interrupts.
  sound.start_music()
  SetTick 40, sound.fx_int, 2
End Sub

' Terminates sound engine.
Sub sound.term()
   Pwm 2, Off
   Pwm 3, Off
End Sub

' Enables/disables sound fx.
Sub sound.enable_fx(z%)
  sound.fx_enabled% = z%
End Sub

' Gets the current music and sound fx enabled state.
'
' @return  if bit 0 is set then sound fx are enabled,
'          if bit 1 is set then music is enabled.
Function sound.get_state%()
  sound.get_state% = sound.fx_enabled%
  Inc sound.get_state%, (sound.music_start_ptr% = Peek(VarAddr sound.MUSIC%())) * 2
End Function

' Plays a music score.
Sub sound.play_music(music%())
  sound.music_start_ptr% = Peek(VarAddr music%())
  sound.music_ptr% = sound.music_start_ptr%
  sound.current_track% = 1
End Sub

' Starts music playing interrupt.
Sub sound.start_music()
  SetTick 200, sound.music_int, 1
End Sub

' Stops music playing interrupt.
Sub sound.stop_music()
  SetTick 0, 0, 1
   Pwm 2, sound.F!(0), 0
End Sub

' Called from interrupt to play next note of music.
Sub sound.music_int()
  Local n% = Peek(Byte sound.music_ptr%)
  If n% < 255 Then
   If n% = 0 Then n% = Peek(Byte sound.music_ptr% + 1)
   If n% = 0 Then n% = Peek(Byte sound.music_ptr% + 2)
   Pwm 2, sound.F!(n%), (n% > 0) * 2
    Inc sound.music_ptr%, 3
    Exit Sub
  EndIf

  If sound.music_start_ptr% = Peek(VarAddr sound.NO_MUSIC%()) Then
    sound.music_ptr% = sound.music_start_ptr%
  Else
    Inc sound.current_track%
    If sound.current_track% > sound.num_tracks% Then sound.current_track% = 1
    sound.music_ptr% = sound.music_start_ptr% + (sound.current_track% - 1) * sound.MAX_TRACK_LEN%
  EndIf
End Sub

' Plays a new sound effect.
Sub sound.play_fx(fx%(), wait_%)
  If Not sound.fx_enabled% Then Exit Sub
  If wait_% Then sound.wait_for_fx()
  sound.fx_ptr% = Peek(VarAddr fx%())

  ' Wait for first note of new sound effect to play.
  Do While sound.fx_ptr% = Peek(VarAddr fx%()) : Loop
End Sub

' Waits for current sound effect to end.
Sub sound.wait_for_fx()
  If Not sound.fx_enabled% Then Exit Sub
  Do While Peek(Byte sound.fx_ptr%) <> &hFF : Loop
End Sub

' Called from interrupt to play next note of current sound effect.
Sub sound.fx_int()
  Local n% = Peek(Byte sound.fx_ptr%)
  If n% = 255 Then Exit Sub
   Pwm 3, sound.F!(n%), (n% > 0) * 5
  Inc sound.fx_ptr%
End Sub

sound.ready_steady_go_data:
Data &h3C3C3C3C3C3C3C3C, &h3C3C3C3C3C3C3C3C, &h0000000000000000, &h0000000000000000
Data &h3C3C3C3C3C3C3C3C, &h3C3C3C3C3C3C3C3C, &h0000000000000000, &h0000000000000000
Data &h4848484848484848, &h4848484848484848, &h4848484848484848, &h0000000048484848
Data &hFFFFFFFFFFFFFFFF
' END:       #Include "src/sound.inc" ------------------------------------------
' BEGIN:     #Include "highscr.inc" --------------------------------------------
' Copyright (c) 2022-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.06

Const highscr.MAX_NAME_LEN% = 8

Dim highscr.values$(9) Length highscr.MAX_NAME_LEN% + 7

' 256-bit map of characters that can be entered into the high-score table
' via gamepad or joystick. For each character 0-255 the character is allowed
' if the corresponding bit is set.
'  Dim highscr.ALLOWED_CHARS%(3) = (&h03FF440100000000, &h000000007FFFFFF, &h0000020080001E00, &h8000000000000000)
Dim highscr.ALLOWED_CHARS%(3) = (&h03FF440100000000, &h000000007FFFFFF, &h0000020080001E00, &h0)

' Initialises high-score library.
'
' @param  filename$    file to read/write high-scores to.
' @param  data_label$  label for DATA to read default high-scores from.
Sub highscr.init(filename$, data_label$)
  Local i%

  ' It is convenient to always fill with the defaults
  ' even if we end up overwriting them immediately.
  Read Save
  Restore data_label$
  For i% = 0 To Bound(highscr.values$(), 1)
    Read highscr.values$(i%)
  Next
  Read Restore

  ' If there is no file-system then do not load high-scores.
  If Not highscr.has_fs%() Then Exit Sub

  ' Check filename$ is absolute.
  Local ok% = 0
  Select Case UCase$(Left$(filename$, 1))
    Case "/", "\" : ok% = 1
    Case "A" To "Z" : If Mid$(filename$, 2, 1) = ":" Then ok% = 1
  End Select
  If Not ok% Then Error "Expected absolute file path '" + filename$ + "'"

  ' Create any parent directories for filename$ if they do not exist.
  Local ch$, parent$
  For i% = 1 To Len(filename$)
    ch$ = Mid$(filename$, i%, 1)
    If InStr("/\", ch$) And parent$ <> "" And UCase$(parent$) <> "A:" Then
      Select Case Mm.Info(FileSize parent$)
        Case -2   : ' Is a directory, do nothing.
        Case -1   : MkDir parent$
        Case Else : Error "Expected directory but found file '" + parent$ + "'"
      End Select
    EndIf
    Cat parent$, ch$
  Next

  ' Check file exists and is not a directory.
  Select Case Mm.Info(FileSize filename$)
    Case -2: Error "Expected file but found directory '" + parent$ + "'"
    Case -1: Exit Sub ' File does not exist.
  End Select

  ' Read the file.
  Open filename$ For Input As #1
  For i% = 0 To Bound(highscr.values$())
    Line Input #1, highscr.values$(i%)
    ok% = ok% And Field$(highscr.values$(i%), 1) <> ""
    ok% = ok% And Field$(highscr.values$(i%), 2) <> ""
    ok% = ok% And Val(Field$(highscr.values$(i%), 2)) > 0
    If Not ok% Then Error "Invalid high-score file '" + filename$ + "'"
  Next
  Close #1
End Sub

' Does the device have a file-system ?
Function highscr.has_fs%()
  If Mm.Device$ = "MMBasic for Windows" Or InStr(Mm.Device$, "PicoMite") Then
    highscr.has_fs% = 1
  Else
    highscr.has_fs% = (UCase$(Mm.Info$(SdCard)) = "READY")
  EndIf
End Function

' Assumes parent directory of filename$ already exists.
Sub highscr.save(filename$)
  ' If there is no file-system then do not save high-scores.
  If Not highscr.has_fs%() Then Exit Sub

  Open filename$ For Output As #1
  Local i%
  For i% = 0 To Bound(highscr.values$())
    Print #1, highscr.values$(i%)
  Next
  Close #1
End Sub

' Shows the high-score table for a specified duration or until the user presses
' START/FIRE/SPACE.
'
' @param  ctrls$     controllers to poll.
' @param  duration%  duration in milliseconds; if 0 then indefinite.
' @return            controller driver if user pressed button/key,
'                    empty string if the duration expired.
Function highscr.show_table$(ctrls$(), duration%)
  Const ch$ = Chr$(205), X_OFFSET% = MM.HRes \ 2, Y_OFFSET% = MM.VRes \ 2
  Local col_idx%, i%, name$, score$, y%
  Local expires% = Choice(duration%, Timer + duration%, &h7FFFFFFFFFFFFFFF)
  Local colours%(3) = (Rgb(Red), Rgb(Yellow), Rgb(Cyan), Rgb(Green))

  Cls
  Text X_OFFSET%, Y_OFFSET% - 95, ch$ + ch$ + " HIGH SCORES " + ch$ + ch$, "CT", 1, 1, Rgb(White)

  ctrl.init_keys()

  Do While Timer < expires% And highscr.show_table$ = ""

    For i% = 0 To Bound(highscr.values$(), 1) + 1
      If i% <= Bound(highscr.values$(), 1) Then
        name$ = str.rpad$(Field$(highscr.values$(i%), 1), highscr.MAX_NAME_LEN%)
        score$ = str.lpad$(Field$(highscr.values$(i%), 2), 5)
        y% = Y_OFFSET% - 75 + 15 * i%
        Text X_OFFSET%, y%, score$ + "  " + name$, "CT", 1, 1, colours%(col_idx%)
      EndIf
      col_idx% = (col_idx% + 1) Mod 4
    Next

    If Not(InStr(Mm.Device$, "PicoMite")) Then Page Copy 1 To 0, B

    highscr.show_table$ = ctrl.poll_multiple$(ctrls$(), ctrl.A Or ctrl.B Or ctrl.START, 200)
  Loop
End Function

' Provides UI for editing an entry in the high-score table.
'
' @param  player%   player id, counting from 1.
' @param  idx%      index of entry in the highscr.values$ array.
' @param  colour_%  player colour.
' @param  ctrl$     controller driver for given player.
Sub highscr.edit(player%, idx%, colour_%, ctrl$)
  Const HEIGHT% = 16, WIDTH% = 16
  Const X_ORIGIN% = (MM.HRes - 10 * WIDTH%) \ 2
  Const Y_ORIGIN% = Int(5.5 * HEIGHT%)
  Const Y_FOOTER% = Mm.VRes - 16

  Local bg%, ch%, count%, fg%, grid$, i%, key%, p%, t%
  Local name$, s$, space_is_fire%, state%, x%, x_new%, y%, y_new%
  Local footer$(1) Length 40

  ' Initialise footer text.
  footer$(0) = "   Use * * * * and FIRE to select    "
  footer$(1) = " Or, type name and ENTER to confirm  "
  Poke Var footer$(0), 8, 146
  Poke Var footer$(0), 10, 147
  Poke Var footer$(0), 12, 148
  Poke Var footer$(0), 14, 149

  Cls

  ' Draw title.
  s$ = Chr$(205)
  Text Mm.HRes \ 2, 25, s$ + s$ + " " + Str$(idx% + 1) + "   PLACE HIGH SCORE " + s$ + s$, "CT", 1, 1, Rgb(White)
  Select Case idx%
    Case 0 : s$ = "ST"
    Case 1 : s$ = "ND"
    Case 2 : s$ = "RD"
    Case Else : s$ = "TH"
  End Select
  Text Choice(idx% = 9, 100, 96), 25, s$, "CT", 7, 1, Rgb(White)

  ' Draw player number.
  Text Mm.HRes \ 2, 3 * HEIGHT%, "PLAYER " + Str$(player%), "CT", 1, 1, colour_%

  ' Draw the character grid.
  Restore highscr.grid_data
  For y% = 0 To 4
    For x% = 0 To 9
      Read ch%
      Cat grid$, Chr$(ch%)
      If ch% = 10 Then ch% = 32 ' Use space as place-holder for OK / Line Feed.
      If ch% = 8 Then ch% = 149 ' Use left arrow character for backspace.
      Text X_ORIGIN% + x% * WIDTH% + 4, Y_ORIGIN% + y% * HEIGHT% + 3, Chr$(ch%), , 1, 1, Rgb(White)
    Next
  Next
  Text X_ORIGIN% + 9 * WIDTH% + 2, Y_ORIGIN + 4 * HEIGHT% + 5, "OK", , 7, 1, Rgb(White)

  ctrl.term_keys() ' Regain control of the keyboard for INKEY$
  Call ctrl$, ctrl.OPEN
  Do While highscr.get_input%(ctrl$) : Loop ' Wait for player to release controller.

  space_is_fire% = 1 : t% = Timer
  x% = -1 : x_new% = 0 : y% = -1 : y_new% = 0
  Do
    ' Draw current name and flashing cursor.
    p% = Mm.HRes / 2
    Inc p%, -4 * Min(Len(name$) + 1, highscr.MAX_NAME_LEN%)
    Text p% - 8, 4 * HEIGHT%, " ", , 1, 1
    For i% = 1 To Min(Len(name$) + 1, highscr.MAX_NAME_LEN%)
      bg% = Choice((i% = Len(name$) + 1) And (count% And &b1), colour_%, Rgb(Black))
      fg% = Choice((i% = Len(name$) + 1) And (count% And &b1), Rgb(Black), colour_%)
      s$ = Choice(i% = Len(name$) + 1, " ", Mid$(name$, i%, 1))
      Text p%, 4 * HEIGHT%, s$, , 1, 1, fg%, bg%
      Inc p%, 8
    Next
    Text p%, 4 * HEIGHT%, " ", , 1, 1
    Inc p%, 8

    ' Draw selection box.
    If x% <> x_new% Or y% <> y_new% Then
      If x% <> -1 Then
        Box X_ORIGIN% + x% * WIDTH%, Y_ORIGIN% + y% * HEIGHT% + 1, WIDTH%, HEIGHT%, 1, Rgb(Black)
      EndIf
      x% = x_new% : y% = y_new%
      Box X_ORIGIN% + x% * WIDTH%, Y_ORIGIN% + y% * HEIGHT% + 1, WIDTH%, HEIGHT%, 1, colour_%
    EndIf

    ' Draw footer text.
    If Timer > t% + 500 Then
      count% = (count% + 1) Mod 10
      t% = Timer
    EndIf
    Text Mm.HRes \ 2, Y_FOOTER%, footer$(count% >= 5), "CT", 1, 1, Rgb(White), Rgb(Black)

    If Not(InStr(Mm.Device$, "PicoMite")) Then Page Copy 1 To 0, B

    key% = highscr.get_input%(ctrl$)
    state% = key% > 0

    If key% > 0 Then
      If key% <> &h20 Then space_is_fire% = (key% > &h7F)
      If key% = &h20 And space_is_fire% Then key% = ctrl.A << 8
      If key% = ctrl.A << 8 Then key% = Asc(Mid$(grid$, x% + y% * 10 + 1, 1))

      Select Case key%
        Case &h08, &h7F ' Backspace and Delete
          If Len(name$) > 0 Then name$ = Left$(name$, Len(name$) - 1) Else state% = 2
        Case &h0A, &h0D ' LF and CR
          key% = -1 ' So we exit the DO LOOP.
        Case ctrl.UP << 8
          If y% > 0 Then y_new% = y% - 1 Else y_new% = 4
        Case ctrl.DOWN << 8
          If y% < 4 Then y_new% = y% + 1 Else y_new% = 0
        Case ctrl.LEFT << 8
          If x% > 0 Then x_new% = x% - 1 Else x_new% = 9
        Case ctrl.RIGHT << 8
          If x% < 9 Then x_new% = x% + 1 Else x_new% = 0
        Case &h20 To &hFF ' ASCII
          If Len(name$) < highscr.MAX_NAME_LEN% Then Cat name$, Chr$(key%) Else state% = 2
      End Select
    End If

    If state% Then
      If state% = 1 Then sound.play_fx(sound.FX_SELECT%()) Else sound.play_fx(sound.FX_BLART%())
      Pause 150
    EndIf

  Loop While key% <> -1

  ' Delete the footer text.
  Text Mm.HRes \ 2, Y_FOOTER%, Space$(40), "CT", 1, 1, Rgb(White), Rgb(Black)

  ' Don't allow empty names.
  name$ = str.trim$(name$)
  If name$ = "" Then name$ = "PLAYER " + Str$(player%)

  highscr.values$(idx%) = name$ + ", " + Field$(highscr.values$(idx%), 2)
End Sub

highscr.grid_data:
Data  65,  66,  67,  68,  69,  70,  71,  72, 73,  74  ' A .. J
Data  75,  76,  77,  78,  79,  80,  78,  82, 83,  84  ' K .. T
Data  85,  86,  87,  88,  89,  90,  42, 46,  64, 169  ' U .. Z, space, *, period, @
Data  48,  49,  50,  51,  52,  53,  54,  55, 56,  57  ' 0 .. 9
Data  63,  45, 137, 138, 139, 140, 159, 32,   8,  10  ' question-mark, hyphen, diamond, club,
                                                      ' spade, heart, star, backspace, enter
' Gets player input to edit entry in the high-score table.
'
' @param  ctrl$  controller driver to read - should already be OPEN.
' @return        ASCII code of key pressed, or value read from
'                controller shifted left 8 places.
Function highscr.get_input%(ctrl$)
  highscr.get_input% = Asc(UCase$(Inkey$))
  If highscr.get_input% Then
    Select Case highscr.get_input%
      Case &h80 : highscr.get_input% = ctrl.UP << 8
      Case &h81 : highscr.get_input% = ctrl.DOWN << 8
      Case &h82 : highscr.get_input% = ctrl.LEFT << 8
      Case &h83 : highscr.get_input% = ctrl.RIGHT << 8
    End Select
  Else
    Call ctrl$, highscr.get_input%
    If highscr.get_input% = ctrl.B Then highscr.get_input% = ctrl.A
    If highscr.get_input% Then highscr.get_input% = highscr.get_input% << 8
  EndIf
End Function
' END:       #Include "src/highscr.inc" ----------------------------------------
' BEGIN:     #Include "menu.inc" -----------------------------------------------
' Copyright (c) 2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.05

' Shows the game settings menu.
'
' @param[in, out]  ui_ctrl$    on entry the controller driver to use to navigate the menu,
'                              on exit the controller driver for first human player,
'                              unchanged if there are no human players.
' @param[in,out]   ctrls$()    on entry the current controller driver per player,
'                              on exit the new controller driver per player.
' @param[in]       colours%()  the player colours
' @return                      1 to continue, or 0 to QUIT.
Function menu.show%(ui_ctrl$, ctrls$(), colours%())
  Const x% = X_OFFSET% - 100
  Static initialised% = 0
  Local key%, i%, item% = 0, update% = 1
  Local sounds$(3) Length 10 = ("MUSIC & FX", "MUSIC ONLY", "FX ONLY   ", "NONE      ")
  Local sound_setting% = 3 - sound.get_state%()
  Local difficulties$(5) Length 6 = ("NOVICE", "1     ", "2     ", "3     ", "4     ", "5     ")

  If Not initialised% Then
    Dim menu.ctrls$(Bound(ctrls$(), 1)) Length 32
    initialised% = 1
  EndIf
  For i% = Bound(ctrls$(), 0) To Bound(ctrls$(), 1)
    menu.ctrls$(i%) = ctrls$(i%)
  Next

  ' Initialise menu.ctrls$(0) if all entries are currently "no" or "ai" control.
  Local count% = 0
  For i% = Bound(menu.ctrls$(), 0) To Bound(menu.ctrls$(), 1)
    Inc count%, Not InStr("ai_control|no_control", menu.ctrls$(i%))
  Next
  If count% = 0 Then menu.ctrls$(0) = ui_ctrl$

  Text X_OFFSET%, Y_OFFSET% + 90, "Game Version " + format_version$(VERSION%), "CM", 7, 1, Rgb(Cyan)

  ctrl.init_keys()
  Call ui_ctrl$, ctrl.OPEN

  Do

    If update% Then
      Text x%, Y_OFFSET% - 95, "START GAME", , 1, 1, Rgb(White)
      menu.txt_for_controller(x%, Y_OFFSET% - 75, 0, colours%(0))
      menu.txt_for_controller(x%, Y_OFFSET% - 55, 1, colours%(1))
      menu.txt_for_controller(x%, Y_OFFSET% - 35, 2, colours%(2))
      menu.txt_for_controller(x%, Y_OFFSET% - 15, 3, colours%(3))
      Text x%, Y_OFFSET% + 5,  "DIFFICULTY: " + difficulties$(difficulty%), , 1, 1, Rgb(White)
      Text x%, Y_OFFSET% + 25, "SOUND:      " + sounds$(sound_setting%), , 1, 1, Rgb(White)
      Text x%, Y_OFFSET% + 45, "QUIT", , 1, 1, Rgb(White)
      Text x% - 15, Y_OFFSET% - 95 + item% * 20, Chr$(137), , 1, 1, Rgb(Cyan)
      If Not InStr(Mm.Device$, "PicoMite") Then Page Copy 1 To 0, B
      Pause 200
      update% = 0
    EndIf

    Call ui_ctrl$, key%
    If key% = 0 Then keys_cursor(key%) ' Always respond to the cursor keys.
    If key% = ctrl.B Then key% = ctrl.A
    Select Case key%
      Case ctrl.START
        menu.show% = 1
        Exit Do

      Case ctrl.UP
        Text x% - 15, Y_OFFSET% - 95 + item% * 20, Chr$(137), , 1, 1, Rgb(Black)
        Inc item%, -1
        If item% < 0 Then item% = 7
        update% = 1

      Case ctrl.DOWN
        Text x% - 15, Y_OFFSET% - 95 + item% * 20, Chr$(137), , 1, 1, Rgb(Black)
        Inc item%
        If item% > 7 Then item% = 0
        update% = 1

      Case ctrl.LEFT, ctrl.RIGHT, ctrl.A
        Select Case item%
          Case 0
            If key% = ctrl.A Then menu.show% = 1 : Exit Do

          Case 1,2,3,4
            menu.update_controller(item% - 1, Choice(key% = ctrl.LEFT, -1, +1), ui_ctrl$)
            update% = 1

          Case 5 ' Difficulty
            Inc difficulty%, Choice(key% = ctrl.LEFT, -1, 1)
            If difficulty% < 0 Then difficulty% = 5
            If difficulty% > 5 Then difficulty% = 0
            update% = 1

          Case 6 ' Sound
            Inc sound_setting%, Choice(key% = ctrl.LEFT, -1, 1)
            If sound_setting% < 0 Then sound_setting% = 3
            If sound_setting% > 3 Then sound_setting% = 0
            If sound_setting% And &b10 Then
              sound.play_music(sound.NO_MUSIC%())
            Else
              sound.play_music(sound.MUSIC%())
            EndIf
            sound.enable_fx(Not (sound_setting% And &b01))
            update% = 1

          Case 7 ' Quit
            If key% = ctrl.A Then Exit Do

        End Select

    End Select

    If update% = 1 Then sound.play_fx(sound.FX_SELECT%(), 1)

  Loop

  Call ui_ctrl$, ctrl.CLOSE

  ' Copy controller settings back into parameter.
  For i% = Bound(ctrls$(), 0) To Bound(ctrls$(), 1)
    ctrls$(i%) = menu.ctrls$(i%)
  Next

  ' Update ui_ctrl$ parameter to be controller chosen for first human player.
  For i% = Bound(ctrls$(), 0) To Bound(ctrls$(), 1)
    If ctrls$(i%) <> "ai_control" And ctrls$(i%) <> "no_control" Then
      ui_ctrl$ = ctrls$(i%)
      Exit For
    EndIf
  Next
End Function

Sub menu.txt_for_controller(x%, y%, idx%, colour%)
  Local txt$ = "PLAYER " + Str$(idx% + 1) + ":   " + menu.get_controller_name$(idx%)
  Text x%, y%, txt$, , 1, 1, colour%
End Sub

Function menu.get_controller_name$(idx%)
  Local i%
  For i% = Bound(CTRL_DRIVER$(), 0) To Bound(CTRL_DRIVER$(), 1)
    If menu.ctrls$(idx%) = CTRL_DRIVER$(i%) Then
      menu.get_controller_name$ = CTRL_DESCRIPTION$(i%)
      Do While Len(menu.get_controller_name$) < 14 : Cat menu.get_controller_name$, " " : Loop
      Exit Function
    Endif
  Next
  Error "Unknown controller: " + menu.ctrls$(idx%)
End Function

Sub menu.update_controller(idx%, delta%, ui_ctrl$)
  ' Temporarily close UI controller.
  Call ui_ctrl$, ctrl.CLOSE

  ' Find index of currently selected controller.
  Local i%
  For i% = Bound(CTRL_DRIVER$(), 0) To Bound(CTRL_DRIVER$(), 1)
    If menu.ctrls$(idx%) = CTRL_DRIVER$(i%) Then Exit For
  Next
  If i% = Bound(CTRL_DRIVER$(), 1) + 1 Then Error "Unknown controller: " + menu.ctrls$(idx%)

  Local ok%
  Do
    Inc i%, delta%
    If i% < 0 Then i% = Bound(CTRL_DRIVER$(), 1)
    If i% > Bound(CTRL_DRIVER$(), 1) Then i% = 0

    ' Check there is no conflict with other player's controller choice.
    If Not InStr("ai_control|no_control", CTRL_DRIVER$(i%)) Then
      If menu.has_controller%(idx%, CTRL_DRIVER$(i%)) Then Continue Do
    EndIf
    Select Case CTRL_DRIVER$(i%)
      Case "atari_a"   : ok% = Not menu.has_controller%(idx%, "nes_a")
      Case "atari_b"   : ok% = Not menu.has_controller%(idx%, "nes_b")
      Case "atari_dx"  : ok% = Not menu.has_controller%(idx%, "nes_dx")
      Case "nes_a"     : ok% = Not menu.has_controller%(idx%, "atari_a")
      Case "nes_b"     : ok% = Not menu.has_controller%(idx%, "atari_b")
      Case "nes_dx"    : ok% = Not menu.has_controller%(idx%, "atari_dx")
      Case "keys_cegg" : ok% = Not menu.has_controller%(idx%, "keys_azxc", "keys_punc")
      Case "keys_azxc" : ok% = Not menu.has_controller%(idx%, "keys_cegg")
      Case "keys_punc" : ok% = Not menu.has_controller%(idx%, "keys_cegg")
      Case Else        : ok% = 1
    End Select

    ' Check that we can OPEN the controller.
    If ok% Then ok% = menu.can_open_controller%(CTRL_DRIVER$(i%))
  Loop Until ok%

  menu.ctrls$(idx%) = CTRL_DRIVER$(i%)

  ' Restore UI controller.
  Call ui_ctrl$, ctrl.OPEN
End Sub

' Can we OPEN the given controller ?
Function menu.can_open_controller%(ctrl$)
  On Error Ignore
  Call ctrl$, ctrl.OPEN
  On Error Abort
  Local ok% = Mm.ErrNo = 0
  If ok% Then Call ctrl$, ctrl.CLOSE
  menu.can_open_controller% = ok%
End Function

' Is any player other than idx% using the specified controller ?
Function menu.has_controller%(idx%, ctrl1$, ctrl2$)
  Local i%
  For i% = Bound(menu.ctrls$(), 0) To Bound(menu.ctrls$(), 1)
    If i% = idx% Then Continue For
    If menu.ctrls$(i%) = ctrl1$ Then menu.has_controller% = 1
    If menu.ctrls$(i%) = ctrl2$ Then menu.has_controller% = 1
  Next
End Function
' END:       #Include "src/menu.inc" -------------------------------------------

Const VERSION% = 10000 ' 1.0.0

If InStr(Mm.Device$, "PicoMite") Then
  If Val(Mm.Info(CpuSpeed)) < 252000000 Then
    Error "Requires OPTION CPUSPEED 252000 or 378000"
  EndIf
EndIf

Select Case Mm.Device$
  Case "Colour Maximite 2", "Colour Maximite 2 G2"
    Const USE_CONTROLLERS$ = "controller_data_cmm2"
    Const USE_PAGE_COPY% = 1
    Const USE_PATH% = 1
    Const USE_MODE% = 7
    Const START_TEXT$ = str.centre$("Press START, FIRE or SPACE", 40)
  Case "MMBasic for Windows"
    Const USE_CONTROLLERS$ = "controller_data_mmb4w"
    Const USE_PAGE_COPY% = 1
    Const USE_PATH% = 1
    Const USE_MODE% = 7
    Const START_TEXT$ = str.centre$("Press SPACE to play", 40)
  Case "PicoMite"
    Const USE_CONTROLLERS$ = "controller_data_pm"
    Const USE_PAGE_COPY% = 0
    Const USE_PATH% = 0
    Const USE_MODE% = 0
    Const START_TEXT$ = str.centre$("Press START to play", 40)
  Case "PicoMiteVGA"
    Const USE_CONTROLLERS$ = "controller_data_pmvga"
    Const USE_PAGE_COPY% = 0
    Const USE_PATH% = 0
    Const USE_MODE% = 2
    Const START_TEXT$ = str.centre$("Press START, FIRE or SPACE", 40)
  Case Else
    Error "Unsupported device: " + Mm.Device$
End Select

If USE_PATH% Then
  On Error Skip
  MkDir Mm.Info(Path) + "high-scores"
  Const HIGHSCORE_FILENAME$ = Mm.Info(Path) + "high-scores/lazer-cycle.csv"
Else
  On Error Skip
  MkDir "/high-scores"
  Const HIGHSCORE_FILENAME$ = "/high-scores/lazer-cycle.csv"
EndIf

If USE_MODE% Then Mode USE_MODE%
If USE_PAGE_COPY% Then Page Write 1
' Const WIDTH% = Mm.HRes \ 2
' Const HEIGHT% = (Mm.VRes - 20) \ 2
Const WIDTH% = Mm.HRes \ 3
Const HEIGHT% = (Mm.VRes - 20) \ 3
Const X_OFFSET% = MM.HRes \ 2
Const Y_OFFSET% = MM.VRes \ 2
Const NORTH% = 0, EAST% = 1, SOUTH% = 2, WEST% = 3
Const MAX_CYCLE_IDX% = 3
Const SCORE_Y% = Mm.VRes - 16
Const STATE_OK%    = &b000 ' 0; values 1-3 are "imminent death"
Const STATE_DYING% = &b100 ' 4
Const STATE_DEAD%  = &b101 ' 5
Const HORIZONTAL_MASK% = ctrl.LEFT Or ctrl.RIGHT
Const VERTICAL_MASK%   = ctrl.UP Or ctrl.DOWN
Const DIRECTION_MASK%  = HORIZONTAL_MASK% Or VERTICAL_MASK%

' These would be constants but MMBasic does not support constant arrays
Dim NEXT_DIR%(7)        = (EAST%, NORTH%, WEST%, SOUTH%, EAST%, NORTH%, WEST%, SOUTH%)
Dim SCORE_X%(3)         = (35, 105, 175, 245)
Dim DIRECTIONS%(3)      = (-WIDTH%, 1, WIDTH%, -1)
Dim COMPASS_TO_CTRL%(3) = (ctrl.UP, ctrl.RIGHT, ctrl.DOWN, ctrl.LEFT)
' Dim FRAME_DURATIONS%(5) = (33, 30, 27, 24, 21, 18)
Dim FRAME_DURATIONS%(5) = (42, 38, 34, 30, 26, 22)

Dim ui_ctrl$ ' Controller driver for controlling the UI.
Dim attract_mode% = 1
Dim score%
Dim difficulty% = Mm.Device$ <> "PicoMite"
Dim frame_duration%
Dim next_frame%

' Each cell of the arena takes up 1 byte:
'   bit  0   - occupied by cycle
'   bits 1-2 - index of cycle
'   bits 3-4 - direction cycle was going in when entered cell
'   bits 5-6 - unused
'   bit  7   - arena wall (other bits will be 0)
Dim arena%(HEIGHT% * WIDTH% \ 8)

Dim cycle.current% ' Current cycle index, set before calling controller subroutines.
Dim cycle.score%(MAX_CYCLE_IDX%)
Dim cycle.nxt%(MAX_CYCLE_IDX%)
Dim cycle.pos%(MAX_CYCLE_IDX%)
Dim cycle.dir%(MAX_CYCLE_IDX%)
Dim cycle.colour%(MAX_CYCLE_IDX%) = (Rgb(Red), Rgb(Yellow), Rgb(Cyan), Rgb(Green))
Dim cycle.ctrl$(MAX_CYCLE_IDX%) Length 32
Dim cycle.ctrl_setting$(MAX_CYCLE_IDX%) Length 32
Dim cycle.state%(MAX_CYCLE_IDX%)
Dim cycle.last_key%(MAX_CYCLE_IDX%)

Dim num_alive%
Dim num_humans%

Option Break 4
On Key 3, on_exit

init_globals()
clear_display()
sound.init("entertainer_music_data", "black_white_rag_music_data")
outer_loop()
End

Sub outer_loop()
  Local attract_mode% = 1, i%

  Do
    If attract_mode% Then wipe() : attract_mode% = Not show_title%(5000)
    If attract_mode% Then wipe() : attract_mode% = Not show_instructions%(15000)
    If attract_mode% Then wipe() : attract_mode% = Not show_highscore%(5000)
    If Not attract_mode% Then
      wipe()
      If Not menu.show%(ui_ctrl$, cycle.ctrl_setting$(), cycle.colour%()) Then on_exit()
    EndIf

    wipe()
    init_game(attract_mode%)
    draw_arena()
    If Not attract_mode% Then ready_steady_go()

    If game_loop%() Then
      ' Game loop interrupted after all human players dead.
      attract_mode% = 0
    ElseIf Not attract_mode% Then
      ' Game ended normally whilst not in attract mode.
      show_game_over()
      attract_mode% = Not show_highscore%(5000)
    EndIf

    close_controllers()
  Loop
End Sub

' Break handler to stop music & fx when Ctrl-C pressed.
Sub on_exit()
  sound.term()
  On Key 3, 0
  Option Break 3
  close_controllers()
  If Mm.Device$ = "PicoMiteVGA" Then Mode 1
  Cls
  End
End Sub

' Initialises global variables.
Sub init_globals()
  Local a%, i%, j%

  ' Initialise list of controllers.
  Restore USE_CONTROLLERS$
  Local num_ctrl%, num_poll%
  Read num_ctrl%, num_poll%
  Dim CTRL_DESCRIPTION$(num_ctrl% - 1)
  Dim CTRL_DRIVER$(num_ctrl% - 1)
  Dim CTRLS_TO_POLL$(Max(1, num_poll% - 1))
  j% = 0
  For i% = 0 To num_ctrl% - 1
    Read CTRL_DESCRIPTION$(i%), CTRL_DRIVER$(i%), a%
    If a% Then
      CTRLS_TO_POLL$(j%) = CTRL_DRIVER$(i%)
      Inc j%
    EndIf
  Next
  If num_poll% = 1 Then CTRLS_TO_POLL$(1) = CTRLS_TO_POLL$(0)

  ' Initialise controller settings.
  cycle.ctrl_setting$(0) = "ai_control"
  cycle.ctrl_setting$(1) = "ai_control"
  For i% = 2 To MAX_CYCLE_IDX% : cycle.ctrl_setting$(i%) = "no_control" : Next

  ' Initialise high-scores.
  highscr.init(HIGHSCORE_FILENAME$, "highscore_data")
End Sub

' Displays the title screen for a specified duration or until the user presses
' START/FIRE/SPACE.
'
' @param duration%  duration in milliseconds; if 0 then indefinite.
' @return           1 if the user pressed button/key,
'                   0 if the duration expired.
Function show_title%(duration%)
  Local platform$ = "Colour Maximite 2"
  Select Case Mm.Device$
    Case "PicoMite"
      platform$ = "PicoMite"
      platform$ = "PicoGAME LCD"
    Case "PicoMiteVGA"
      platform$ = "PicoGAME VGA"
  End Select

  Text X_OFFSET%, Y_OFFSET% - 27, "LAZER CYCLE", "CM", 1, 2, Rgb(White)
  Text X_OFFSET%, Y_OFFSET% - 10, platform$ + " Version", "CM", 7, 1, Rgb(Cyan)
  Text X_OFFSET%, Y_OFFSET% + 8, "(c) 2022-2023 Thomas Hugo Williams", "CM", 7, 1, Rgb(Cyan)
  Text X_OFFSET%, Y_OFFSET% + 20, "www.sockpuppetstudios.com", "CM", 7, 1, Rgb(Cyan)
  Text X_OFFSET%, Y_OFFSET% + 40, START_TEXT$, "CM", 1, 1, Rgb(White)
  If USE_PAGE_COPY% Then Page Copy 1 To 0, B
  show_title% = wait%(duration%)
End Function

' Displays the instructions screen for a specified duration or until the user presses
' START/FIRE/SPACE.
'
' @param duration%  duration in milliseconds; if 0 then indefinite.
' @return           1 if the user pressed button/key,
'                   0 if the duration expired.
Function show_instructions%(duration%)
  Const ch$ = Chr$(205)
  Local y% = Y_OFFSET% - 95
  Text X_OFFSET%, y%, ch$ + ch$ + " LAZER CYCLE " + ch$ + ch$, "CT", 1, 1, Rgb(White) : Inc y%, 20
  Text X_OFFSET%, y%, "An arcade game for 1-4 players.", "CT", 1, 1, Rgb(Red) : Inc y%, 20
  Text X_OFFSET%, y%, "Pilot your cycle around the", "CT", 1, 1, Rgb(Yellow) : Inc y%, 12
  Text X_OFFSET%, y%, "arena leaving a trail of light", "CT", 1, 1, Rgb(Yellow) : Inc y%, 12
  Text X_OFFSET%, y%, "behind, longest trail wins.", "CT", 1, 1, Rgb(Yellow) : Inc y%, 20
  Text X_OFFSET%, y%, "You are eliminated if you hit the", "CT", 1, 1, Rgb(Cyan) : Inc y%, 12
  Text X_OFFSET%, y%, "arena wall, or one of the trails.", "CT", 1, 1, Rgb(Cyan) : Inc y%, 20
  Text X_OFFSET%, y%, "Use keyboard, joystick or gamepad", "CT", 1, 1, Rgb(Green) : Inc y%, 12
  Text X_OFFSET%, y%, "UP, DOWN, LEFT and RIGHT to steer.", "CT", 1, 1, Rgb(Green) : Inc y%, 20
  Text X_OFFSET%, y%, "Good Luck!", "CT", 1, 1, Rgb(White)
  If USE_PAGE_COPY% Then Page Copy 1 To 0, B
  show_instructions% = wait%(duration%)
End Function

' Displays the highscore table for a specified duration or until the user presses
' START/FIRE/SPACE.
'
' @param duration%  duration in milliseconds; if 0 then indefinite.
' @return           1 if the user pressed button/key,
'                   0 if the duration expired.
Function show_highscore%(duration%)
  Local ctrl$ = highscr.show_table$(CTRLS_TO_POLL$(), 5000)
  If ctrl$ <> "" Then
    If ui_ctrl$ = "" Then ui_ctrl$ = ctrl$
    show_highscore% = 1
  EndIf
End Function

Sub clear_display()
   Box 0, 0, Mm.HRes, Mm.VRes, 1, Rgb(Black), Rgb(Black)
   If USE_PAGE_COPY% Then Page Copy 1 To 0, B
End Sub

' Waits a specified duration for the user to press START on a (S)NES gamepad
' connected to Port A, or FIRE on an ATARI joystick connected to Port A or
' SPACE on the keyboard.
'
' @param duration%  duration in milliseconds; if 0 then indefinite.
' @return           1 if the user pressed button/key,
'                   0 if the duration expired.
Function wait%(duration%)
  ctrl.init_keys()
  Local ctrl$ = ctrl.poll_multiple$(CTRLS_TO_POLL$(), ctrl.A Or ctrl.B Or ctrl.START, duration%)
  If ctrl$ <> "" Then
    If ui_ctrl$ = "" Then ui_ctrl$ = ctrl$
    wait% = 1
  EndIf
End Function

Sub init_game(attract_mode%)
  frame_duration% = FRAME_DURATIONS%(difficulty%)
  num_alive% = 0 ' Incremented later.
  num_humans% = 0
  score% = 0

  ' Initialise the arena.
  Local p_arena% = Peek(VarAddr arena%())
  Memory Set p_arena%, 0, HEIGHT% * WIDTH%
  Memory Set p_arena%, 128, WIDTH%
  Memory Set p_arena% + (HEIGHT% - 1) * WIDTH%, 128, WIDTH%
  Local y%
  For y% = 1 To HEIGHT% - 2
    Poke Byte p_arena% + y% * WIDTH%, 128
    Poke Byte p_arena% + (y% + 1) * WIDTH% - 1, 128
  Next

  ' Initialise game ports and keyboard routines.
  Local i%
  For i% = 0 To MAX_CYCLE_IDX%
    cycle.ctrl$(i%) = Choice(attract_mode%, "ai_control", cycle.ctrl_setting$(i%))
    On Error Ignore
    Call cycle.ctrl$(i%), ctrl.OPEN
    If Mm.ErrNo <> 0 Then cycle.ctrl$(i%) = "no_control"
    On Error Abort
  Next
  ctrl.init_keys()

  ' Initialise cycle state.
  cycle.dir%(0) = EAST%
  cycle.dir%(1) = WEST%
  cycle.dir%(2) = SOUTH%
  cycle.dir%(3) = NORTH%

  cycle.pos%(0) = WIDTH * (HEIGHT% \ 2) + 5
  cycle.pos%(1) = WIDTH% * (HEIGHT% \ 2) + WIDTH% - 6
  cycle.pos%(2) = 5.5 * WIDTH%
  cycle.pos%(3) = WIDTH% * (HEIGHT% - 6) + WIDTH% \ 2

  For i% = 0 To MAX_CYCLE_IDX%
    cycle.score%(i%) = 0
    cycle.last_key%(i%) = 0
    If cycle.ctrl$(i%) = "no_control" Then
      cycle.pos%(i%) = -1
      cycle.nxt%(i%) = -1
      cycle.state%(i%) = STATE_DEAD%
    Else
      Inc num_alive%
      Inc num_humans%, cycle.ctrl$(i%) <> "ai_control"
      cycle.nxt%(i%) = cycle.pos%(i%) + DIRECTIONS%(cycle.dir%(i%))
      Poke Byte p_arena% + cycle.pos%(i%), (cycle.dir%(i%) << 3) + (i% << 1) + 1
      Poke Byte p_arena% + cycle.nxt%(i%), (cycle.dir%(i%) << 3) + (i% << 1) + 1
      cycle.state%(i%) = STATE_OK%
    EndIf
  Next
End Sub

Sub draw_arena()
  ' Local a%, i%, j%
  ' For i% = 0 To Bound(arena%(), 1) - 1
  '   a% = arena%(i%)
  '   If a% = 0 Then Continue For
  '   For j% = 0 To 7
  '     If Peek(Var a%, j%) <> 128 Then Continue For
  '     Pixel 2 * (((i% * 8) Mod WIDTH%) + j%), 2 * ((i% * 8) \ WIDTH%), Rgb(Grey)
  '   Next
  ' Next
  Local x%
  For x% = 0 To (HEIGHT% * WIDTH%) - 1
    If Peek(Var arena%(), x%) <> 128 Then Continue For
    Box 3 * (x% Mod WIDTH%), 3 * (x% \ WIDTH%), 2, 2, , Rgb(Grey)
  Next
End Sub

Sub ready_steady_go()
  If sound.get_state%() And &b1 Then sound.stop_music()
  sound.play_fx(sound.FX_READY_STEADY_GO%(), 1)

  ' Draw cycle starting positions.
  Local i%
  For i% = 0 To MAX_CYCLE_IDX%
    If Not (cycle.state%(i%) And &b11) Then cycle.draw(i%)
  Next

  Local msg$(2) = ("READY", "STEADY", "GO!")
  For i% = 0 To 2
    Text X_OFFSET%, Y_OFFSET% - 10, msg$(i%), "CM", 1, 2, Rgb(White)
    If USE_PAGE_COPY% Then Page Copy 1 To 0, I
    Pause 1280
    If i% = 2 Then Pause 240
    Text X_OFFSET%, Y_OFFSET% - 10, msg$(i%), "CM", 1, 2, Rgb(Black)
  Next

  sound.start_music()
End Sub

' @return  0 - normal game over
'          1 - game interrupted after all human players died
Function game_loop%()
  Local d%, i%, key%, next_frame% = Timer + frame_duration%, tf%

  ' Change 0 => 1 to easily test high-score code.
  If 0 Then
    num_alive% = 0
    cycle.score%(0) = 3175
    cycle.score%(1) = 2175
    cycle.score%(2) = 1175
    cycle.score%(3) = 975
    score% = 3175
  EndIf

  Do While num_alive% > 0
    tf% = Timer
    Inc score%, 1
    If score% Mod 5 = 0 Then draw_score()

    ' When dying the cycle trail deletes at twice the rate.
    For i% = 0 To MAX_CYCLE_IDX%
      If cycle.state%(i%) = STATE_DYING% Then cycle.dying(i%)
    Next

    ' Draw cycles.
    For i% = 0 To MAX_CYCLE_IDX%
      If Not (cycle.state%(i%) And &b11) Then cycle.draw(i%)
    Next

    If USE_PAGE_COPY% Then Page Copy 1 To 0, I

    ' Move cycles.
    For i% = 0 To MAX_CYCLE_IDX%
      If Not (cycle.state%(i%) And &b11) Then cycle.pos%(i%) = cycle.nxt%(i%)
    Next

    ' Determine changes of direction and check for collisions.
    For i% = 0 To MAX_CYCLE_IDX%
      cycle.current% = i%
      Call cycle.ctrl$(i%), key%
      d% = cycle.dir%(i%)
      key% = key% And DIRECTION_MASK%
      If key% <> cycle.last_key%(i%) Then
        Select Case d%
          Case NORTH%, SOUTH%
            Select Case key% And HORIZONTAL_MASK%
              Case ctrl.LEFT : d% = WEST%
              Case ctrl.RIGHT : d% = EAST%
            End Select
          Case EAST%, WEST%
            Select Case key% And VERTICAL_MASK%
              Case ctrl.UP : d% = NORTH%
              Case ctrl.DOWN : d% = SOUTH%
            End Select
        End Select
        cycle.dir%(i%) = d%
        cycle.last_key%(i%) = key%
      EndIf
      cycle.nxt%(i%) = cycle.pos%(i%) + DIRECTIONS%(d%)
      If cycle.state%(i%) <> STATE_DEAD% Then cycle.check_collision(i%)
'      If i% = 0 Then draw_controller(i%, key%)
    Next

    ' Wait for next frame.
    Do While Timer < next_frame% : Loop
    Inc next_frame%, frame_duration%

'    If score% Mod 5 Then draw_framerate(1000 / (Timer - tf%))

    If num_humans% > 0 Then Continue Do

    ' Check for "attract mode" being interrupted.
    If ctrl.poll_single%(CTRLS_TO_POLL$(score% Mod (Bound(CTRLS_TO_POLL$(), 1) + 1)), ctrl.A Or ctrl.B Or ctrl.START) Then
      If ui_ctrl$ = "" Then ui_ctrl$ = CTRLS_TO_POLL$(score% Mod (Bound(CTRLS_TO_POLL$(), 1) + 1))
      num_alive% = 0
      game_loop% = 1
    EndIf

  Loop

  ' Ensure display updated at end of loop.
  If USE_PAGE_COPY% Then Page Copy 1 To 0, B

  ' Wait for current sound effect (if any) to complete.
  sound.wait_for_fx()
End Function

Sub draw_score()
  If num_humans% > 0 Or ((score% \ 100) And &b1) Then
    Local i%, s$ = Str$(score%, 5, 0, "0")
    For i% = 0 To MAX_CYCLE_IDX%
      If cycle.state%(i%) < STATE_DYING% Then
        Text SCORE_X%(i%), SCORE_Y%, s$, , 1, 1, cycle.colour%(i%)
      EndIf
    Next
    Exit Sub
  EndIf

  ' If there are no human players we toggle between the score and the "Press ..." text.
  If score% Mod 100 = 95 Then
    Local i%, sc%
    Text Mm.HRes \ 2, SCORE_Y%, Space$(40), "C", 1, 1, Rgb(White)
    For i% = 0 To MAX_CYCLE_IDX%
      sc% = Choice(cycle.state%(i%) < STATE_DYING%, score%, (cycle.score%(i%) \ 5) * 5)
      Text SCORE_X%(i%), SCORE_Y%, Str$(sc%, 5, 0, "0"), , 1, 1, cycle.colour%(i%)
    Next
  Else
    Text Mm.HRes \ 2, SCORE_Y%, START_TEXT$, "C", 1, 1, Rgb(White)
  EndIf
End Sub

' Shows controller input in the score area.
'
' @param  idx%  player number, 1-4
' @param  x%    input bitmap from controller driver.
Sub draw_controller(idx%, x%)
  Local s$ = cycle.ctrl$(idx%) + ": " + ctrl.bits_to_string$(x%)
  Text 0, SCORE_Y%, str.rpad$(s$, 40), , 1, 1, Rgb(White)
End Sub

' Shows framerate in the score area.
Sub draw_framerate(rate%)
  Text 0, SCORE_Y%, str.rpad$("Framerate: " + Str$(rate%) + " fps", 40), , 1, 1, Rgb(White)
End Sub

Sub wipe()
  Local y%
  sound.play_fx(sound.FX_WIPE%(), 1)
  For y% = 0 To Mm.VRes \ 2 Step 5
     Box Mm.HRes \ 2 - y% * 1.2, Mm.VRes \ 2 - y%, 2.4 * y%, 2 * y%, 5, Rgb(Cyan), Rgb(Black)
     If USE_PAGE_COPY% Then Page Copy 1 To 0, B
     Pause 30
  Next
  clear_display()
End Sub

' Draw cycle if STATE_OK% or STATE_DYING%.
Sub cycle.draw(idx%)
  ' Local p% = cycle.pos%(idx%), n% = cycle.nxt%(idx%)
  ' Line 2*(p% Mod WIDTH%), 2*(p%\WIDTH%), 2*(n% Mod WIDTH%), 2*(n%\WIDTH%), 1, cycle.colour%(idx%) * (cycle.state%(idx%) <> STATE_DYING%)
  Local p% = cycle.pos%(idx%), n% = cycle.nxt%(idx%), xn% = 3*(n% Mod WIDTH%), yn% = 3*(n%\WIDTH%)
  Local colour_% = cycle.colour%(idx%) * (cycle.state%(idx%) <> STATE_DYING%)
  Line 3*(p% Mod WIDTH%), 3*(p%\WIDTH%), xn%, yn%, 2, colour_%
  Box xn%, yn%, 2, 2, , colour_% ' BOX necessary to avoid missing pixel artefact in trace.
End Sub

Sub cycle.dying(idx%)
  cycle.draw(idx%)
  cycle.pos%(idx%) = cycle.nxt%(idx%) ' Move
  cycle.current% = idx%
  Local key%
  die_control(key%)
  Select Case key%
    Case ctrl.UP:    cycle.dir%(idx%) = NORTH%
    Case ctrl.DOWN:  cycle.dir%(idx%) = SOUTH%
    Case ctrl.LEFT:  cycle.dir%(idx%) = WEST%
    Case ctrl.RIGHT: cycle.dir%(idx%) = EAST%
  End Select
  cycle.nxt%(idx%) = cycle.pos%(idx%) + DIRECTIONS%(cycle.dir%(idx%))
  cycle.check_collision(idx%)
End Sub

Sub show_game_over()
  ' Sort scores and then round down to nearest 5.
  Local dummy%, i%, idx%(MAX_CYCLE_IDX%), j%, k%, winner%
  Sort cycle.score%(), idx%(), 1
  For i% = 0 To MAX_CYCLE_IDX%
    cycle.score%(i%) = (cycle.score%(i%) \ 5) * 5 ' Round down to nearest 5.
  Next
  winner% = idx%(0)

  Box X_OFFSET% - 130, Y_OFFSET% - 50, 260, 80, 0, Rgb(Black), Rgb(Black)

  If cycle.ctrl_setting$(winner%) = "ai_control" Then
    Text X_OFFSET%, Y_OFFSET% - 10, " COMPUTER WINS ", "CM", 1, 2, cycle.colour%(winner%)
    If USE_PAGE_COPY% Then Page Copy 1 To 0, B
  Else
    Local txt$ = " PLAYER " + Str$(winner% + 1) + " WINS "
    Text X_OFFSET%, Y_OFFSET% - 25, txt$, "CM", 1, 2, cycle.colour%(winner%)
    Text X_OFFSET%, Y_OFFSET% + 5, " SCORE: " + Str$(cycle.score%(0)) + " ", "CM", 1, 2, cycle.colour%(winner%)
    If USE_PAGE_COPY% Then Page Copy 1 To 0, B

    ' Determine bonus.
    Local multiplier% = -30 + 10 * difficulty%
    For i% = 0 To MAX_CYCLE_IDX%
      If cycle.ctrl_setting$(i%) <> "no_control" Then Inc multiplier%, 10
    Next

    If multiplier% > 1 Then
      Pause 1500
      Local s$ = " BONUS +" + Str$(multiplier%) + "% "
      Text X_OFFSET%, Y_OFFSET% + 5, s$ , "CM", 1, 2, RGB(White)
      If USE_PAGE_COPY% Then Page Copy 1 To 0, B
      Pause 1500
      Local bonus% = cycle.score%(0) * (1 + multiplier% / 100)
      Do While cycle.score%(0) < bonus%
        Select Case bonus% - cycle.score%(0)
          Case > 60 : Inc cycle.score%(0), 50
          Case > 15 : Inc cycle.score%(0), 10
          Case Else : Inc cycle.score%(0), 5
        End Select
        s$ = " SCORE: " + Str$(cycle.score%(0)) + " "
        Text X_OFFSET%, Y_OFFSET% + 5, s$, "CM", 1, 2, cycle.colour%(winner%)
        If USE_PAGE_COPY% Then Page Copy 1 To 0, B
        sound.play_fx(sound.FX_SELECT%(), 1)
        Pause 100
      Loop
    EndIf
  EndIf

  dummy% = wait%(5000)

  wipe()

  ' Insert into high-score table.
  ' For the moment only the winner can enter a high-score,
  ' to change that make the upper bound of the FOR statement = MAX_CYCLE_IDX%
  Local new_highscore%, player%
  For i% = 0 To 0
    player% = idx%(i%)
    If cycle.ctrl_setting$(player%) = "ai_control" Then Continue For
    For j% = 0 To Bound(highscr.values$())
      If cycle.score%(i%) > Val(Field$(highscr.values$(j%), 2)) Then
        For k% = Bound(highscr.values$(), 1) To j% Step -1
          If k% <> 0 Then highscr.values$(k%) = highscr.values$(k% - 1)
        Next
        highscr.values$(j%) = ", " + Str$(cycle.score%(i%))
        highscr.edit(player% + 1, j%, cycle.colour%(player%), cycle.ctrl_setting$(player%))
        new_highscore% = 1
        Exit For
      EndIf
    Next
  Next
  If new_highscore% Then highscr.save(HIGHSCORE_FILENAME$)
End Sub

Sub ai_control(x%)
  If x% < 0 Then Exit Sub

  Local idx% = cycle.current%
  Local d% = cycle.dir%(idx%)

  ' Random element.
  Local i% = Int(500 * Rnd)
  If i% < 4 Then d% = NEXT_DIR%(i% + idx%)

  ' Avoid collisions.
  Local nxt%
  For i% = 0 To MAX_CYCLE_IDX%
    nxt% = cycle.pos%(idx%) + DIRECTIONS%(d%)
    If Not Peek(Var arena%(), nxt%)) Then Exit For
    d% = NEXT_DIR%(i% + idx%)
  Next

  x% = COMPASS_TO_CTRL%(d%)
End Sub

Sub die_control(x%)
  If x% < 0 Then Exit Sub
  Local bits% = Peek(Var arena%(), cycle.pos%(cycle.current%)) >> 1
  If (bits% And &b11) = cycle.current% Then
    bits% = (bits% >> 2) And &b11
    x% = COMPASS_TO_CTRL%((bits% + 2) Mod 4)
  EndIf
End Sub

Sub no_control(x%)
  x% = 0
End Sub

Sub keys_cegg(x%)
  If x% < 0 Then Exit Sub
  x% =    ctrl.keydown%(32)  * ctrl.A     ' Space
  Inc x%, ctrl.keydown%(97)  * ctrl.UP    ' A
  Inc x%, ctrl.keydown%(122) * ctrl.DOWN  ' Z
  Inc x%, ctrl.keydown%(44)  * ctrl.LEFT  ' comma
  Inc x%, ctrl.keydown%(46)  * ctrl.RIGHT ' full-stop
End Sub

Sub keys_azxc(x%)
  If x% < 0 Then Exit Sub
  x% =    ctrl.keydown%(32)  * ctrl.A     ' Space
  Inc x%, ctrl.keydown%(97)  * ctrl.UP    ' A
  Inc x%, ctrl.keydown%(122) * ctrl.DOWN  ' Z
  Inc x%, ctrl.keydown%(120) * ctrl.LEFT  ' X
  Inc x%, ctrl.keydown%(99)  * ctrl.RIGHT ' C
End Sub

Sub keys_punc(x%)
  If x% < 0 Then Exit Sub
  x% =    ctrl.keydown%(32) * ctrl.A     ' Space
  Inc x%, ctrl.keydown%(39) * ctrl.UP    ' single-quote
  Inc x%, ctrl.keydown%(47) * ctrl.DOWN  ' slash
  Inc x%, ctrl.keydown%(44) * ctrl.LEFT  ' comma
  Inc x%, ctrl.keydown%(46) * ctrl.RIGHT ' full-stop
End Sub

Sub cycle.check_collision(idx%)
  ' Handle dying.
  If cycle.state%(idx%) = STATE_DYING% Then
    Poke Var arena%(), cycle.pos%(idx%), 0
    Local mask% = (idx% << 1) + 1
    If (Peek(Var arena%(), cycle.nxt%(idx%)) And mask%) <> mask% Then
      cycle.ctrl$(idx%) = "no_control"
      cycle.state%(idx%) = STATE_DEAD%
      cycle.pos%(idx%) = -1
    EndIf
    Exit Sub
  EndIf

  ' No collision occurred.
  If Not Peek(Var arena%(), cycle.nxt%(idx%)) Then
    Poke Var arena%(), cycle.nxt%(idx%), (cycle.dir%(idx%) << 3) + (idx% << 1) + 1
    cycle.state%(idx%) = STATE_OK%
    Exit Sub
  EndIf

  ' Collision occured - the player has a couple of frames to change direction.
  Inc cycle.state%(idx%)
  If cycle.state%(idx%) < STATE_DYING% Then Exit Sub

  ' Time to die.
  Inc num_alive%, -1
  If cycle.ctrl$(idx%) <> "ai_control" Then Inc num_humans%, -1
  cycle.ctrl$(idx%) = "die_control"
  cycle.nxt%(idx%) = cycle.pos%(idx%)
  cycle.score%(idx%) = score%
  sound.play_fx(sound.FX_DIE%(), 0)
End Sub

Sub close_controllers()
  Local i%
  For i% = 0 To MAX_CYCLE_IDX%
    close_controller_no_error(cycle.ctrl_setting$(i%))
  Next
End Sub

Sub close_controller_no_error(ctrl$)
  On Error Ignore
  Call ctrl$, ctrl.CLOSE
  On Error Abort
End Sub

controller_data_cmm2:

Data 11, 6
Data "KEYS: CURSOR",   "keys_cursor", 1
Data "KEYS: AZ,.",     "keys_cegg",   0
Data "KEYS: AZXC",     "keys_azxc",   0
Data "KEYS: '/,.",     "keys_punc",   0
Data "JOYSTICK DX",    "atari_dx",    1
Data "NES GAMEPAD DX", "nes_dx",      1
Data "WII CTRL I2C1",  "wii_any_1",   1
Data "WII CTRL I2C2",  "wii_any_2",   1
Data "WII CTRL I2C3",  "wii_any_3",   1
Data "AI",             "ai_control",  0
Data "NONE",           "no_control",  0

controller_data_mmb4w:

Data 6, 1
Data "KEYS: CURSOR",   "keys_cursor", 1
Data "KEYS: AZ,.",     "keys_cegg",   0
Data "KEYS: AZXC",     "keys_azxc",   0
Data "KEYS: '/,.",     "keys_punc",   0
Data "AI",             "ai_control",  0
Data "NONE",           "no_control",  0

controller_data_pm:

Data 7, 2
Data "KEYS: CURSOR", "keys_cursor", 1
Data "KEYS: AZ,.",   "keys_cegg",   0
Data "KEYS: AZXC",   "keys_azxc",   0
Data "KEYS: '/,.",   "keys_punc",   0
Data "GAMEPAD",      "nes_a",       1
Data "AI",           "ai_control",  0
Data "NONE",         "no_control",  0

controller_data_pmvga:

Data 10, 5
Data "KEYS: CURSOR", "keys_cursor", 1
Data "KEYS: AZ,.",   "keys_cegg",   0
Data "KEYS: AZXC",   "keys_azxc",   0
Data "KEYS: '/,.",   "keys_punc",   0
Data "GAMEPAD A",    "nes_a",       1
Data "GAMEPAD B",    "nes_b",       1
Data "JOYSTICK A",   "atari_a",     1
Data "JOYSTICK B",   "atari_b",     1
Data "AI",           "ai_control",  0
Data "NONE",         "no_control",  0

highscore_data:

Data "MICKEY, 4000"
Data "MIKE, 3000"
Data "PETER, 2000"
Data "DAVEY, 1500"
Data "JOHN, 1250"
Data "PAUL, 1000"
Data "GEORGE, 800"
Data "RINGO, 600"
Data "MIDDLE, 400"
Data "MODAL, 200"

entertainer_music_data:

Data 792 ' Number of bytes of music data.
Data 3   ' Number of channels.
Data &h3135000034000033, &h3500253D00313D00, &h00283D00283D0025, &h2A3D00293D002935
Data &h3D002C3D002A3D00, &h002E3D002E00002C, &h314100304000303F, &h4100293F00313D00
Data &h002A3C002A410029, &h253D002C3F002C3F, &h3D002C3D00253D00, &h00313D00313D002C
Data &h3135000034003133, &h3500253D00313D00, &h00283D00283D0025, &h2A3D00293D002935
Data &h3D002C3D002A3D00, &h002E3D002E3D002C, &h273700263800263A, &h41002B3D00273A00
Data &h002E3F002E41002B, &h2C3F00273A00273D, &h3F002A3F002C3F00, &h00293F00293F002A
Data &h2535002734002733, &h3500313D00253D00, &h00283D00283D0031, &h2A3D00293D002935
Data &h3D002C3D002A3D00, &h002E3D002E00002C, &h314100304000303F, &h4100293F00313D00
Data &h002A3C002A410029, &h313D002C3F002C3F, &h3D002C3D00313D00, &h00250000253D002C
Data &h3D4100253F00253D, &h41313D3F00003D31, &h00003D2F3B410000, &h3A4100003D2F3B3F
Data &h412E3A3F00003D2E, &h00003D2D39410000, &h384100003D2D393F, &h412C383F00003D2C
Data &h2C383C2C38410000, &h003D00003F00003F, &h3D202C3D00003D00, &h00003525313D202C
Data &h3538000037000036, &h3800363A31353831, &h2C00352C35380035, &h3538000037000036
Data &h3800363A31353831, &h2C00412C35380035, &h003A00003800003D, &h3F2A003D2A003C2A
Data &h2C003F2C00412A00, &h00382C003F2C003D, &h382C003825003825, &h3100353100382C00
Data &h3538000037000036, &h3800363A31353831, &h2C00352C35380035, &h3538000037000036
Data &h3800363A31353831, &h2C00382C35380035, &h003C32003B32003A, &h3C33000033003C33
Data &h27003A27003C3300, &h0038270033270037, &h382C00380000382C, &h2E00352E00380000
Data &h3538300037300036, &h3800363A31353831, &h2C00352C35380035, &h3538000037000036
Data &h3800363A31353831, &h2C00412C35380035, &h003A00003800003D, &h3F2A003D2A003C2A
Data &h2C003F2C00412A00, &h003D2C003F2C003D, &h3D2C003D25003D25, &h31003831003D2C00
Data &h363D000038000037, &h3D2A363A00003D2A, &h00003A2B373D0000, &h383800003A2B373D
Data &h442C384100003D2C, &h0000412935440000, &h363A00003829353D, &h3D2A363D00003A2A
Data &h00003F2C38410000, &h3D3D00003F2C383F, &h3D2C383D313D3D31, &h25313D25313D2C38
Data &hFFFF000000000000, &hFFFFFFFFFFFFFFFF, &hFFFFFFFFFFFFFFFF

black_white_rag_music_data:
Data 888 ' Number of bytes of music data.
Data 3   ' Number of channels.
Data &h3440003A41003A41, &h3E00354100354100, &h00333F00333F0026, &h303C00303C002F3B
Data &h35002C38002A3600, &h0027330027330029, &h333F00330000333F, &h0000273F00330000
Data &h00330000333F0027, &h273F00273F00273F, &h3F00003F00270000, &h00003E00003E0000
Data &h314216273F16273D, &h4211223F27313D27, &h27313F27313D1122, &h283F1B273D1B2742
Data &h411D29421C28421C, &h1E2A3D1E2A3F1D29, &h3041202C3C202C3B, &h4120273C27303B27
Data &h27303C27303B2027, &h2D3C202C3B202C41, &h3F222E41212D4121, &h24303824303C222E
Data &h313C222E3D222E3D, &h3C1B273D27313D27, &h27313D27313D1B27, &h3139222E3A222E3A
Data &h391B273A27313A27, &h27313A27313A1B27, &h2400002000000000, &h0000000000270000
Data &h003300003000002C, &h003C000038000000, &h4400000000003F00, &h00004B0000480000
Data &h31421B273F1B273D, &h4216223F27313D27, &h27313F27313D1622, &h283F1B273D1B2742
Data &h411D29421C28421C, &h1E2A3D1E2A3F1D29, &h3041202C3C202C3B, &h411B273C27303B27
Data &h27303C27303B1B27, &h2D3C202C3B202C41, &h3F222E41212D4121, &h24303C24303D222E
Data &h3339212D35212D41, &h3F1D294129334129, &h29333C29333D1D29, &h313A222E39222E3A
Data &h3F1D294129314129, &h29313A29313D1D29, &h30381B27331B273C, &h381B273C27303C27
Data &h1E2A3A1E2A3A1B27, &h3338303338303338, &h443C3F4430333830, &h0000000000003C3F
Data &h314216273F16273D, &h4211223F27313D27, &h27313F27313D1122, &h283F1B273D1B2742
Data &h411D29421C28421C, &h1E2A3D1E2A3F1D29, &h3041202C3C202C3B, &h4120273C27303B27
Data &h27303C27303B2027, &h2D3C202C3B202C41, &h3F222E41212D4121, &h24303824303C222E
Data &h313C222E3D222E3D, &h3C1B273D27313D27, &h27313D27313D1B27, &h3139222E3A222E3A
Data &h391B273A27313A27, &h27313A27313A1B27, &h2400002000000000, &h0000000000270000
Data &h003300003000002C, &h003C000038000000, &h4400000000003F00, &h00004B0000480000
Data &h31421B273F1B273D, &h4216223F27313D27, &h27313F27313D1622, &h283F1B273D1B2742
Data &h411D29421C28421C, &h1E2A3D1E2A3F1D29, &h3041202C3C202C3B, &h411B273C27303B27
Data &h27303C27303B1B27, &h2D3C202C3B202C41, &h3F222E41212D4121, &h24303C24303D222E
Data &h3339212D35212D41, &h3F1D294129334129, &h29333C29333D1D29, &h313A222E39222E3A
Data &h3F1D294129314129, &h29313A29313D1D29, &h30381B27331B273C, &h381B273C27303C27
Data &h1E2A3A1E2A3A1B27, &h3338303338303338, &h443C3F4430333830, &h0000000000003C3F
Data &hFFFFFFFFFFFFFFFF, &hFFFFFFFFFFFFFFFF, &hFFFFFFFFFFFFFFFF
