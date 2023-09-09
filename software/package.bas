#!/usr/local/bin/mmbasic

' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMB4L 0.6.0

' Utility to create installation package for GameMite.

Option Base 0
Option Default None
Option Explicit 1

#Include "src/splib/system.inc"
#Include "src/splib/file.inc"
#Include "src/splib/string.inc"

Const NAME$ = "GameMite"
Const VERSION% = get_version%()
Const VERSION_STR$ = sys.format_version$(VERSION%)
Const NAME_AND_VERSION$ = NAME$ + "-" + VERSION_STR$
Const BUILD_DIR$ = "build/" + NAME$
Const SOFTWARE_DIR$ = "/mmbasic-gamemite/software/"
Const FIRMWARE_DIR$ = "../../picomite-firmware"
Const UF2_FILE$ = NAME_AND_VERSION$ + "-fw-only.uf2"
Const ZIP_FILE$ = NAME_AND_VERSION$ + "-appendix-d.zip"

If Right$(Mm.Info$(Path), Len(SOFTWARE_DIR$)) <> SOFTWARE_DIR$ Then Error "Invalid path"

create_build_dir()
build_firmware()
build_software()
create_archive()
copy_archive()

End

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

Sub create_build_dir()
  ? "Creating directory:"
  ? "  " + BUILD_DIR$
  If file.exists%(BUILD_DIR$) Then
    If file.delete%(BUILD_DIR$, 20) <> sys.SUCCESS Then Error sys.err$
  EndIf
  If file.mkdir%(BUILD_DIR$) <> sys.SUCCESS Then Error sys.err$
End Sub

Sub build_firmware()
  ? "Building firmware:"
  System "cd " + FIRMWARE_DIR$ + "/build" + " && cmake ../PicoMite && make"
  Copy FIRMWARE_DIR$ + "/build/GameMite.uf2" To BUILD_DIR$ + "/../" + UF2_FILE$
End Sub

Sub build_software()
  ? "Building software:"
  Local src$, dst$
  Do
    Read src$, dst$
    If Not Len(src$) Then Exit Do
    dst$ = str.replace$(dst$, "${BUILD}", BUILD_DIR$)
    trans_and_copy(src$, dst$)
  Loop
End Sub

Sub trans_and_copy(src$, dst$)
  ? "  " src$ " => " dst$ " ..."
  Local cmd$ = "sptrans -q -DGAMEMITE " + src$ + " " + dst$
  System cmd$
End Sub

Sub create_archive()
  ? "Creating archive:"
  ? "  " + ZIP_FILE$
  System "cd build && zip -r " + ZIP_FILE$ + " " + NAME$ + " " + UF2_FILE$
End Sub

Sub copy_archive()
  Const src$ = "build/" + ZIP_FILE$
  Const dst$ = "../download/" + ZIP_FILE$
  ? "Copying archive to:"
  ? "  " + dst$
  Copy src$ To dst$
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
Data "../../mmbasic-kingdom/src/kingdom.bas", "${BUILD}/kingdom.bas"
Data "", ""
