defmodule Resdayn.ExporterTest do
  use ExUnit.Case, async: true

  alias Resdayn.Exporter

  defp data_file do
    %Resdayn.Codex.Mechanics.DataFile{
      id: "test",
      filename: "test.esp",
      version: Decimal.new("1.3"),
      master: false,
      company: "Test Author",
      description: "Test plugin",
      dependencies: [%{filename: "Morrowind.esm", size: 79_837_557}]
    }
  end

  defp build_and_parse(records) do
    {:ok, binary} = Exporter.build([data_file() | records])
    Resdayn.Parser.read_binary(binary)
  end

  describe "build/1" do
    test "builds a valid ESP from a DataFile" do
      [record] = build_and_parse([])

      assert record.type == Resdayn.Parser.Record.MainHeader
      assert record.data.header.version == 1.3
      assert record.data.header.company == "Test Author"
      assert record.data.header.description == "Test plugin"
      assert record.data.header.record_count == 0
      assert record.data.header.flags.master == false
      assert [%{filename: "Morrowind.esm", size: 79_837_557}] = record.data.dependencies
    end

    test "exports a lockpick" do
      lockpick = %Resdayn.Codex.Items.Tool{
        id: "pick_apprentice",
        name: "Apprentice's Lockpick",
        type: :lockpick,
        nif_model_filename: "m/Pick_Apprentice.nif",
        icon_filename: "m/Tx_lockpick_Appr.tga",
        weight: 0.25,
        value: 12,
        uses: 25,
        quality: 0.5
      }

      [_header, record] = build_and_parse([lockpick])

      assert record.type == Resdayn.Parser.Record.Lockpick
      assert record.data.id == "pick_apprentice"
      assert record.data.name == "Apprentice's Lockpick"
      assert record.data.nif_model_filename == "m/Pick_Apprentice.nif"
      assert record.data.icon_filename == "m/Tx_lockpick_Appr.tga"
      assert record.data.weight == 0.25
      assert record.data.value == 12
      assert record.data.uses == 25
      assert record.data.quality == 0.5
    end
  end
end
