defmodule Resdayn.Importer.Record.BodyPart do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.BodyPart)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :race_id, :type, :equipment_type, :vampire, :nif_model_filename])
        |> with_flags(:body_part_flags, record.data.flags)
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Characters.BodyPart,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
