' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.08

Option Base 0
Option Default None
Option Explicit 1

Const VERSION = 300 ' 0.3.0

'!define NO_INCLUDE_GUARDS

#Include "splib/system.inc"

'!if defined(PICOMITEVGA)
  '!replace { Mode 7 } { Mode 2 }
'!elif defined(PICOMITE) || defined(PGLCD2)
  '!replace { Mode 7 } { }
'!endif

Mode 7
Cls
Dim y% = 80
Text 160, y%, "PicoGAME LCD v" + sys.format_version$(VERSION), CM
Inc y%, Mm.Info(FontHeight) + 1

If Mm.Device$ <> "PicoMite" Or ((sys.FIRMWARE < 5070808) And (sys.FIRMWARE <> 5070800)) Then
  Inc y%, Mm.Info(FontHeight) + 1
  Text 160, y%, "ERROR: Requires PicoMite firmware", CM, , , Rgb(Red)
  Inc y%, Mm.Info(FontHeight) + 1
  Text 160, y%, "       5.07.08b8 or later        ", CM, , , Rgb(Red)
  End
EndIf

Text 160, y%, "(c) 2023 Thomas Hugo Williams", CM
Inc y%, 2 * Mm.Info(FontHeight)
If Mm.Device$ = "PicoMite" Then Font 7
Dim title$ = "PicoMite MMBasic Version " + sys.format_version$(sys.FIRMWARE, 1)
If Mm.Info$(Device X) = "PicoGAME LCD" Then Cat title$, " - PGLCD"
Text 160, y%, title$, CM
Inc y%, Mm.Info(FontHeight) + 1
Text 160, y%, "Copyright 2011-2023 Geoff Graham", CM
Inc y%, Mm.Info(FontHeight) + 1
Text 160, y%, "Copyright 2016-2023 Peter Mather", CM
Font 1
Inc y%, 2 * Mm.Info(FontHeight)
Dim f$ = "A:/pglcd/menu.bas", x% = Mm.Info(Exists File f$)
If Not x% Then f$ = "B:/pglcd/menu.bas" : x% = Mm.Info(Exists File f$)
Dim msg$ = Choice(x%, "Loading menu ...", "Menu program not found!")
Text 160, y%, msg$, CM
Pause 500
If Len(f$) Then Run f$ Else End
