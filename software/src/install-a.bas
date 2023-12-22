' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

' Utility to copy Game*Mite software to "A:/"

Option Base 0
Option Default None
Option Explicit 1

'!define NO_INCLUDE_GUARDS

#Include "splib/system.inc"

main()
End

Sub main()
  Const version% = get_version%()
  Const drive$ = Mm.Info(Drive)
  Const dst_dir$ = "A:/GameMite"

  ?
  ? "Installing Game*Mite " sys.format_version$(version%) " to A:/"
  ?

  If Not Mm.Info(Exists Dir dst_dir$) Then
    If drive$ <> "A:" Then Drive "A:"
    MkDir dst_dir$
    Drive drive$
  EndIf

  Local dst$, src$
  src$ = Dir$(Mm.Info(Path) + "*", File)
  Do While Len(src$)
    If src$ = "install-a.bas" Then src$ = Dir$() : Continue Do
    dst$ = dst_dir$ + "/" + src$
    src$ = Mm.Info(Path) + src$
    ? "Copying " src$ " => " dst$
    Copy src$ To dst$
    src$ = Dir$()
  Loop

  ?
  ? "To configure autorun of Game*Mite type:"
  ?
  ? "  FLASH ERASE 1 ' fails harmlessly if flash slot 1 is empty"
  ? "  LOAD " + Chr$(34) + dst_dir$ + "/startup.bas" + Chr$(34)
  ? "  FLASH SAVE 1"
  ? "  OPTION AUTORUN 1,NORESET"
  ? "  OPTION PLATFORM " + Chr$(34) + "Game*Mite" + Chr$(34)
  ?
End Sub

Function get_version%()
  get_version% = Val(sys.get_config$("version", "1", Mm.Info(Path) + ".startup"))
End Function
