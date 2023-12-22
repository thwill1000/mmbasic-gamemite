#!/usr/local/bin/mmbasic

' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMB4L 0.6.0

' Utility to create installation package for Game*Mite.

Option Base 0
Option Default None
Option Explicit 1

#Include "src/splib/system.inc"
#Include "src/splib/file.inc"
#Include "src/splib/string.inc"

Const NAME$ = "GameMite"
Const VERSION% = get_version%()
Const VERSION_STR$ = str.replace$(sys.format_version$(VERSION%), " ", "-")
Const NAME_AND_VERSION$ = NAME$ + "-" + VERSION_STR$
Const BUILD_DIR$ = "build/" + NAME$
Const SOFTWARE_DIR$ = "/mmbasic-gamemite/software/"
Const FIRMWARE_DIR$ = "../../picomite-firmware"
Const UF2_FILE$ = NAME_AND_VERSION$ + "-fw-only.uf2"
Const ZIP_FILE$ = NAME_AND_VERSION$ + "-appendix-d.zip"

If Right$(Mm.Info$(Path), Len(SOFTWARE_DIR$)) <> SOFTWARE_DIR$ Then Error "Invalid path"

? "Version:"
? "  " + VERSION_STR$
create_build_dir()
' build_firmware() - No longer necessary,  using standard PicoMite firmware.
build_software()
create_archive()
copy_archive()

End

Function get_version%()
  get_version% = Val(sys.get_config$("version", "1", "src/dot_startup"))
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
    If file.get_extension$(src$) = ".bas" Then
      trans_and_copy(src$, dst$)
    Else
      just_copy(src$, dst$)
    EndIf
  Loop
End Sub

Sub trans_and_copy(src$, dst$)
  ? "  TRANSPILE " src$ " => " dst$ " ..."
  Local cmd$ = "sptrans -q -T -n -e=1 -i=1 -DGAMEMITE " + src$ + " " + dst$
  System cmd$
End Sub

Sub just_copy(src$, dst$)
  ? "  COPY " src$ " => " dst$ " ..."
  Local cmd$ = "cp " + src$ + " " + dst$
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

Data "src/dot_startup", "${BUILD}/.startup"
Data "src/LICENSE", "${BUILD}/LICENSE.txt"
Data "../ChangeLog", "${BUILD}/ChangeLog.txt"
Data "src/splash.bmp", "${BUILD}/splash.bmp"
Data "src/fm.bas", "${BUILD}/fm.bas"
Data "src/install-a.bas", "${BUILD}/install-a.bas"
Data "src/menu.bas", "${BUILD}/menu.bas"
Data "src/startup.bas", "${BUILD}/startup.bas"
Data "../../mmbasic-sptools/src/splib/examples/ctrl-demo-2.bas", "${BUILD}/ctrl-demo-2.bas"
Data "../../mmbasic-sptools/src/splib/examples/sound-demo.bas", "${BUILD}/sound-demo.bas"
Data "../../mmbasic-lazer-cycle/src/lazer-cycle.bas", "${BUILD}/lazer-cycle.bas"
Data "../../mmbasic-third-party/circle/circle-1p-gm.bas", "${BUILD}/circle.bas"
Data "../../mmbasic-third-party/circle/circle.mod", "${BUILD}/circle.mod"
Data "../../mmbasic-third-party/pico-vaders/pico-vaders.bas", "${BUILD}/pico-vaders.bas"
Data "../../mmbasic-third-party/3d-maze/3d-maze.bas", "${BUILD}/3d-maze.bas"
Data "../../mmbasic-kingdom/src/kingdom.bas", "${BUILD}/kingdom.bas"
Data "", ""
