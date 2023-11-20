' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

' Startup banner for the GameMite.

Option Base 0
Option Default None
Option Explicit 1

'!define NO_INCLUDE_GUARDS

#Include "splib/system.inc"
#Include "splib/gamemite.inc"

Const CONFIG$ = gamemite.file$(".startup")
Const VERSION = Val(sys.get_config$("version", "0", CONFIG$))
Const MIN_FIRMWARE = Val(sys.get_config$("firmware", "9999999", CONFIG$))
Const FW = Mm.Info(FontWidth), FH = Mm.Info(FontHeight)

Dim s$, y% = FH

FrameBuffer Create
FrameBuffer Write F
Cls

' Splash image.
Load Image gamemite.file$(sys.get_config$("splash", "unknown", CONFIG$)), 32, y%
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

Const f$ = gamemite.file$(sys.get_config$("menu", "unknown", CONFIG$))
Const z% = Mm.Info(Exists File f$)
Dim msg$ = Choice(z%, "Loading menu ...", "Menu program not found!")
Text 160, y%, msg$, CM

FrameBuffer Copy F, N
FrameBuffer Write N

Pause 500
If Len(f$) Then Run f$ Else End

