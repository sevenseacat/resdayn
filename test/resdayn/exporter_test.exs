defmodule Resdayn.ExporterTest do
  use ExUnit.Case, async: true

  alias Resdayn.Exporter

  describe "build/1" do
    test "builds a valid ESP from a DataFile" do
      data_file = %{
        version: Decimal.new("1.3"),
        master: false,
        company: "Test Author",
        description: "Test plugin",
        dependencies: [%{filename: "Morrowind.esm", size: 79_837_557}]
      }

      {:ok, binary} = Exporter.build([data_file])

      [record] = Resdayn.Parser.read_binary(binary)

      assert record.type == Resdayn.Parser.Record.MainHeader
      assert record.data.header.version == 1.3
      assert record.data.header.company == "Test Author"
      assert record.data.header.description == "Test plugin"
      assert record.data.header.record_count == 0
      assert record.data.header.flags.master == false
      assert [%{filename: "Morrowind.esm", size: 79_837_557}] = record.data.dependencies
    end
  end
end
