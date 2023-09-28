' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

' Startup banner for the GameMite.

Option Base 0
Option Default None
Option Explicit 1

Const VERSION = 101300 ' 1.1.0

'!define NO_INCLUDE_GUARDS

#Include "splib/system.inc"

'!if defined(PICOMITEVGA)
  '!replace { Mode 7 } { Mode 2 }
'!elif defined(PICOMITE) || defined(GAMEMITE)
  '!replace { Mode 7 } { }
'!endif

Mode 7
Cls

Const FW = Mm.Info(FontWidth), FH = Mm.Info(FontHeight)
Dim s$ = "Game*Mite v" + sys.format_version$(VERSION)
Const x% = (Mm.HRes - Len(s$) * FW) \ 2
Dim y% = 6 * FH
Text x%, y%, Left$(s$, 4), LM, 1, 1
Text x% + 4 * FW + 1, y%, Chr$(&h9F), LM, 1, 1
Text x% + 5 * FW + 3, y%, Mid$(s$, 6), LM, 1, 1
Inc y%, FH + 1

If Mm.Device$ <> "PicoMite" Or ((sys.FIRMWARE < 5070900) And (sys.FIRMWARE <> 5070800)) Then
  Inc y%, FH + 1
  Text 160, y%, "ERROR: Requires PicoMite firmware", CM, , , Rgb(Red)
  Inc y%, FH + 1
  Text 160, y%, "        5.07.08 or later         ", CM, , , Rgb(Red)
  End
EndIf

Text 160, y%, "(c) 2023 Thomas Hugo Williams", CM
Inc y%, 2 * FH

If Mm.Device$ = "PicoMite" Then Font 7
Dim title$ = "PicoMite MMBasic Version " + sys.format_firmware_version$()
If Mm.Info$(Device X) = "GameMite" Then Cat title$, " - GameMite"
Text 160, y%, title$, CM
Inc y%, FH + 1

Text 160, y%, "Copyright 2011-2023 Geoff Graham", CM
Inc y%, FH + 1

Text 160, y%, "Copyright 2016-2023 Peter Mather", CM
Font 1
Inc y%, 2 * FH

Dim f$ = "A:/GameMite/menu.bas", z% = Mm.Info(Exists File f$)
If Not z% Then f$ = "B:/GameMite/menu.bas" : z% = Mm.Info(Exists File f$)
Dim msg$ = Choice(z%, "Loading menu ...", "Menu program not found!")
Text 160, y%, msg$, CM
Pause 500
If Len(f$) Then Run f$ Else End
