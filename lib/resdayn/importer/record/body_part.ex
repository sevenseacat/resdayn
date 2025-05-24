defmodule Resdayn.Importer.Record.BodyPart do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.BodyPart)
      |> Enum.map(fn record ->
        body_part_flags = 
          record.data.flags
          |> Enum.filter(fn {_key, value} -> value end)
          |> Enum.map(fn {key, _value} -> key end)

        record.data
        |> Map.take([:id, :race, :equipment_type, :vampire])
        |> Map.put(:nif_model_filename, record.data.nif_model)
        |> Map.put(:body_part_type, record.data.type)
        |> Map.put(:body_part_flags, body_part_flags)
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Characters.BodyPart,
      data: data
    }
  end
end