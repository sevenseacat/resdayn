defmodule Resdayn.ParserTest do
  use ExUnit.Case, async: true

  alias Resdayn.Parser

  def read_single_record(binary) do
    {:ok, stream} = StringIO.open(binary)
    {[record], ^stream} = Parser.read_record(stream)
    record
  end

  describe "read_record/1" do
    test "TES3 record from Tribunal.esm" do
      record =
        read_single_record(
          <<84, 69, 83, 51, 90, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 69, 68, 82, 44, 1, 0, 0, 102,
            102, 166, 63, 1, 0, 0, 0, 66, 101, 116, 104, 101, 115, 100, 97, 32, 83, 111, 102, 116,
            119, 111, 114, 107, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 84, 104, 101, 32,
            109, 97, 105, 110, 32, 100, 97, 116, 97, 32, 102, 105, 108, 101, 32, 102, 111, 114,
            32, 84, 114, 105, 98, 117, 110, 97, 108, 46, 13, 10, 40, 114, 101, 113, 117, 105, 114,
            101, 115, 32, 77, 111, 114, 114, 111, 119, 105, 110, 100, 46, 101, 115, 109, 32, 116,
            111, 32, 114, 117, 110, 41, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15,
            39, 0, 0, 77, 65, 83, 84, 14, 0, 0, 0, 77, 111, 114, 114, 111, 119, 105, 110, 100, 46,
            101, 115, 109, 0, 68, 65, 84, 65, 8, 0, 0, 0, 117, 57, 194, 4, 0, 0, 0, 0>>
        )

      assert record ==
               %{
                 flags: %{blocked: false, persistent: false},
                 subrecords: [
                   {"HEDR",
                    %{
                      company: "Bethesda Softworks",
                      description:
                        "The main data file for Tribunal.\r\n(requires Morrowind.esm to run)",
                      record_count: 9999,
                      version: 1.3
                    }},
                   {"MAST", "Morrowind.esm"},
                   {"DATA", 79_837_557}
                 ],
                 type: "TES3"
               }
    end
  end
end
