defmodule Resdayn.Importer.Record.Class do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Class)
    |> Enum.map(fn record ->
      record.data
      |> Map.take([
        :id,
        :description,
        :value,
        :specialization,
        :playable
      ])
      |> Map.put(:name, record.data.name || record.data.id)
      |> Map.put(:attribute1_id, Enum.at(record.data.attribute_ids, 0))
      |> Map.put(:attribute2_id, Enum.at(record.data.attribute_ids, 1))
      |> with_flags(:flags, record.flags)
      |> with_flags(:items_vendored, record.data.vendor_for)
      |> with_flags(:services_offered, record.data.services)
    end)
    |> separate_for_import(Resdayn.Codex.Characters.Class, opts)
  end
end
