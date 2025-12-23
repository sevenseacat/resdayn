defmodule Resdayn.Importer.Record.Ingredient do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Ingredient)
      |> Enum.map(fn record ->
        record.data
        |> Map.drop([:effects])
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Items.Ingredient,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
