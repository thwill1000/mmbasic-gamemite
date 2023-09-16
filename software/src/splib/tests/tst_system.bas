' Copyright (c) 2020-2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default None
Option Base InStr(Mm.CmdLine$, "--base=1") > 0

#Include "../system.inc"
#Include "../array.inc"
#Include "../list.inc"
#Include "../string.inc"
#Include "../file.inc"
#Include "../vt100.inc"
#Include "../../sptest/unittest.inc"

add_test("test_provides")
add_test("test_provides_given_duplicates")
add_test("test_provides_given_too_many")
add_test("test_requires")
add_test("test_format_version")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_provides()
  Local i%
  For i% = 1 To sys.MAX_INCLUDES% : sys.includes$(i%) = "" : Next

  sys.provides("foo")
  sys.provides("bar")

  assert_no_error()
  If Mm.Info(Option Base) = 0 Then assert_string_equals("", sys.includes$(0))
  assert_string_equals("foo", sys.includes$(1))
  assert_string_equals("bar", sys.includes$(2))
  For i% = 3 To sys.MAX_INCLUDES% : assert_string_equals("", sys.includes$(i%)) : Next
End Sub

Sub test_provides_given_duplicates()
  Local i%
  For i% = 1 To sys.MAX_INCLUDES% : sys.includes$(i%) = "" : Next
  sys.provides("list")
  sys.provides("set")
  assert_no_error()

  sys.provides("list")
  assert_error("file already included: list.inc")
End Sub

Sub test_provides_given_too_many()
  Local i%
  For i% = 1 To sys.MAX_INCLUDES% : sys.includes$(i%) = "foo" + Str$(i%) : Next
  assert_no_error()

  sys.provides("wombat")
  assert_error("too many includes")
End Sub

Sub test_requires()
  Local i%
  sys.includes$(1) = "foo"
  sys.includes$(2) = "bar"
  For i% = 3 To sys.MAX_INCLUDES% : sys.includes$(i%) = "" : Next

  sys.requires("bar")
  assert_no_error()

  sys.requires("wombat")
  assert_error("required file(s) not included: wombat.inc")

  sys.requires("snafu")
  assert_error("required file(s) not included: snafu.inc")

  sys.requires("wombat", "snafu")
  assert_error("required file(s) not included: wombat.inc, snafu.inc")

  sys.requires("a", "bar", "c", "d", "e", "foo", "g", "h", "i", "j")
  assert_error("required file(s) not included: a.inc, c.inc, d.inc, e.inc, g.inc, h.inc, i.inc, j.inc")
End Sub

Sub test_format_version()
  assert_string_equals("10.07.08b7", sys.format_version$(10070807, 1))
  assert_string_equals("5.07.08b7", sys.format_version$(5070807, 1))
  assert_string_equals("5.06.00", sys.format_version$(5060000, 1))
  assert_string_equals("5.6.0", sys.format_version$(50600))
  assert_string_equals("0.9.9", sys.format_version$(909))
End Sub
