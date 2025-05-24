defmodule Resdayn.Importer.Record.Birthsign do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.Birthsign)
      |> Enum.map(fn record ->
        spells = 
          (record.data.special_ids || [])
          |> Enum.map(fn spell_id ->
            %{spell_id: spell_id}
          end)

        record.data
        |> Map.take([:id, :name, :description])
        |> Map.put(:artwork_filename, record.data.artwork)
        |> Map.put(:spells, spells)
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Characters.Birthsign,
      data: data
    }
  end
end