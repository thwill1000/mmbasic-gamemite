' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

' Utility to copy GameMite software to "A:/"

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
  ? "Installing GameMite " sys.format_version$(version%) " to A:/"
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
  ? "To configure autorun of GameMite type:"
  ?
  ? "  FLASH ERASE 1 ' fails harmlessly if flash slot 1 is empty"
  ? "  LOAD " + Chr$(34) + dst_dir$ + "/startup.bas" + Chr$(34)
  ? "  FLASH SAVE 1"
  ? "  OPTION AUTORUN 1"
  ?
End Sub

Function get_version%()
  Open Mm.Info(Path) + "startup.bas" For Input As #1
  Local i%, s$
  Do While Not Eof(#1)
    Line Input #1, s$
    i% = InStr(s$, " VERSION")
    If i% Then
      Do While i% <= Len(s$)
        Select Case Mid$(s$, i%, 1)
          Case "0" To "9": Exit Do
        End Select
        Inc i%
      Loop
      If i% > Len(s$) Then Exit Do
      get_version% = Val(Mid$(s$, i%))
      Exit Function
    EndIf
  Loop
  Error "VERSION not found"
End Function
