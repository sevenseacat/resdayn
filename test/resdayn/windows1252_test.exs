defmodule Resdayn.Windows1252Test do
  use ExUnit.Case, async: true

  alias Resdayn.Windows1252

  describe "decode/1" do
    test "passes ASCII through unchanged" do
      assert Windows1252.decode("Bethesda Softworks") == "Bethesda Softworks"
    end

    test "maps 0xA0..0xFF to their Latin-1 code points" do
      assert Windows1252.decode(<<"caf", 0xE9>>) == "café"
    end

    test "maps the 0x80..0x9F range via the special table" do
      assert Windows1252.decode(<<0x91, ?H, 0x92>>) == "‘H’"
      assert Windows1252.decode(<<0x80, 0x99, 0x97, 0x85>>) == "€™—…"
    end

    test "drops the five undefined bytes, keeping surrounding text" do
      assert Windows1252.decode(<<?a, 0x81, 0x8D, 0x8F, 0x90, 0x9D, ?b>>) == "ab"
    end

    test "truncates at the first null (fixed-width field padding)" do
      assert Windows1252.decode(<<"Iron Key", 0, 0, 0>>) == "Iron Key"
    end

    test "normalizes CRLF to LF" do
      assert Windows1252.decode(<<"line1", 0x0D, 0x0A, "line2">>) == "line1\nline2"
    end

    test "strips control-character corruption but keeps tab and newline" do
      assert Windows1252.decode(<<"TR_m7_Trap", 0x01>>) == "TR_m7_Trap"
      assert Windows1252.decode("a\tb\nc") == "a\tb\nc"
    end

    test "normalizes non-breaking space and soft hyphen to ASCII" do
      assert Windows1252.decode(<<"Mournhold", 0xAD, "a girl", 0xA0, "child">>) ==
               "Mournhold-a girl child"
    end
  end

  describe "encode/1" do
    test "encodes curly quotes to their Windows-1252 bytes" do
      assert Windows1252.encode("“Hello”") == <<0x93, ?H, ?e, ?l, ?l, ?o, 0x94>>
    end

    test "encodes high-range characters a partial reverse table would miss" do
      assert Windows1252.encode("…€™Œ") == <<0x85, 0x80, 0x99, 0x8C>>
    end

    test "drops characters with no Windows-1252 representation" do
      assert Windows1252.encode("a😀b") == "ab"
    end
  end
end
