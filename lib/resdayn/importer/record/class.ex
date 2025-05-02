defmodule Resdayn.Importer.Record.Class do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.Class)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([
          :id,
          :description,
          :value,
          :specialization,
          :playable,
          :major_skill_ids,
          :minor_skill_ids
        ])
        |> Map.put(:name, record.data.name || record.data.id)
        |> Map.put(:attribute1_id, Enum.at(record.data.attribute_ids, 0))
        |> Map.put(:attribute2_id, Enum.at(record.data.attribute_ids, 1))
        |> with_flags(:flags, record.flags)
        |> with_flags(:items_vendored, record.data.vendor_for)
        |> with_flags(:services_offered, record.data.services)
      end)

    %{
      resource: Resdayn.Codex.Characters.Class,
      data: data
    }
  end
end
