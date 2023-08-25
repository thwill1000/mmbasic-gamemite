' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMB4L 0.6.0

' Utility to create installation package for PicoGAME LCD.

Option Base 0
Option Default None
Option Explicit 1

'!define NO_INCLUDE_GUARDS

#Include "src/splib/system.inc"
#Include "src/splib/file.inc"
#Include "src/splib/string.inc"

Const BUILD_DIR$ = "build/pglcd"
Const SOFTWARE_DIR$ = "/pico-game-lcd/software/"
Const VERSION% = get_version%()

main()
End

Sub main()
  If Right$(Mm.Info$(Path), Len(SOFTWARE_DIR$)) <> SOFTWARE_DIR$ Then Error "Invalid path"

  ? "Creating directory:"
  ? "  " + BUILD_DIR$
  If file.exists%(BUILD_DIR$) Then
    If file.delete%(BUILD_DIR$, 20) <> sys.SUCCESS Then Error sys.err$
  EndIf
  If file.mkdir%(BUILD_DIR$) <> sys.SUCCESS Then Error sys.err$

  ? "Transpiling and copying:"
  Local src$, dst$
  Do
    Read src$, dst$
    If Not Len(src$) Then Exit Do
    dst$ = str.replace$(dst$, "${BUILD}", BUILD_DIR$)
    trans_and_copy(src$, dst$)
  Loop

  Const zip_file$ = "pglcd-" + sys.format_version$(version%) + ".zip"
  ? "Creating archive:"
  ? "  " + zip_file$
  System "cd build && zip -r " + zip_file$ + " pglcd"
End Sub

Function get_version%()
  Open "src/startup.bas" For Input As #1
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

Sub trans_and_copy(src$, dst$)
  ? "  " src$ " => " dst$ " ..."
  Local cmd$ = "sptrans -q -DPGLCD2 " + src$ + " " + dst$
  System cmd$
End Sub

Data "src/fm.bas", "${BUILD}/fm.bas"
Data "src/install-a.bas", "${BUILD}/install-a.bas"
Data "src/menu.bas", "${BUILD}/menu.bas"
Data "src/startup.bas", "${BUILD}/startup.bas"
Data "../../mmbasic-sptools/src/splib/examples/ctrl-demo-2.bas", "${BUILD}/ctrl-demo-2.bas"
Data "../../mmbasic-sptools/src/splib/examples/sound-demo.bas", "${BUILD}/sound-demo.bas"
Data "../../mmbasic-lazer-cycle/src/lazer-cycle.bas", "${BUILD}/lazer-cycle.bas"
Data "../../mmbasic-third-party/pico-vaders/pico-vaders.bas", "${BUILD}/pico-vaders.bas"
Data "../../mmbasic-third-party/3d-maze/3d-maze.bas", "${BUILD}/3d-maze.bas"
Data "../../cmm2-kingdom/src/kingdom.bas", "${BUILD}/kingdom.bas"
Data "", ""
