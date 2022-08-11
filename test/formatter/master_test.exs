defmodule Resdayn.Formatter.MasterTest do
  use ExUnit.Case, async: true

  alias Resdayn.Formatter.Master

  describe "format/1" do
    test "TES3 record from Tribunal.esm" do
      record = %{
        flags: %{blocked: false, persistent: false},
        subrecords: [
          {"HEDR",
           %{
             company: "Bethesda Softworks",
             description: "The main data file for Tribunal.\r\n(requires Morrowind.esm to run)",
             record_count: 9999,
             version: 1.3
           }},
          {"MAST", "Morrowind.esm"},
          {"DATA", 79_837_557}
        ],
        type: "TES3"
      }

      assert Master.format(record) == %{
               type: :master,
               flags: %{blocked: false, persistent: false},
               company: "Bethesda Softworks",
               description: "The main data file for Tribunal.\n(requires Morrowind.esm to run)",
               record_count: 9999,
               version: 1.3,
               dependencies: [%{name: "Morrowind.esm", size: 79_837_557}]
             }
    end
  end
end
