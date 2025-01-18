' Copyright (c) 2023-2024 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 6.0

' Startup banner for the Game*Mite.

Option Base 0
Option Default None
Option Explicit 1

#Include "splib/system.inc"
#Include "splib/game.inc"

Const CONFIG$ = find_file$(".startup")
Const VERSION = Val(sys.get_config$("version", "0", CONFIG$))
Const MIN_FIRMWARE = Val(sys.get_config$("firmware", "9999999", CONFIG$))
Const FW = Mm.Info(FontWidth), FH = Mm.Info(FontHeight)

Dim s$, y% = FH

FrameBuffer Create
FrameBuffer Write F
Cls

' Splash image.
Load Image find_file$(sys.get_config$("splash", "unknown", CONFIG$)), 32, y%
Inc y%, 64 + FH

' Game*Mite version.
Text 320 - FW, 240 - FH, "v" + sys.format_version$(VERSION), RB
Inc y%, FH + 1

' Game*Mite copyright.
Text 160, y%, sys.get_config$("copyright", "unknown", CONFIG$), CM
Inc y%, 2 * FH

If Mm.Device$ <> "PicoMite" Or sys.FIRMWARE < MIN_FIRMWARE Then
  Inc y%, FH + 1
  Text 160, y%, "ERROR: Requires PicoMite firmware", CM, , , Rgb(Red)
  Inc y%, FH + 1
  Text 160, y%, "        " + sys.format_firmware_version$(MIN_FIRMWARE) + " or later         ", CM, , , Rgb(Red)
  End
EndIf

' MMBasic copyright.
If Mm.Device$ = "PicoMite" Then Font 7
s$ = "PicoMite MMBasic Version " + sys.format_firmware_version$()
Text 160, y%, s$, CM
Inc y%, FH + 1
Text 160, y%, sys.get_config$("mmbasic_copyright_1", "unknown", CONFIG$), CM
Inc y%, FH + 1
Text 160, y%, sys.get_config$("mmbasic_copyright_2", "unknown", CONFIG$), CM
Font 1
Inc y%, 2 * FH

Const f$ = find_file$(sys.get_config$("menu", "unknown", CONFIG$))
Const z% = Mm.Info(Exists File f$)
Dim msg$ = Choice(z%, "Loading menu ...", "Menu program not found!")
Text 160, y%, msg$, CM

FrameBuffer Copy F, N
FrameBuffer Write N

Pause 500
If Len(f$) Then Run f$ Else End

Function find_file$(f$)
  ' Paths are relative to "A:/GameMite" or "B:/GameMite".
  find_file$ = "A:/GameMite" + Choice(f$ = "", "", "/" + f$), x%
  x% = Mm.Info(Exists File find_file$)
  If Not x% Then
    find_file$ = "B" + Mid$(find_file$, 2)
    On Error Skip ' Handle SD Card not present error.
    x% = Mm.Info(Exists File find_file$)
  EndIf
  If Not x% Then find_file$ = "A" + Mid$(find_file$, 2)
End Function
