defmodule Resdayn.Importer.Record.MagicEffect do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    # These appear to be case insensitive - the sounds are parsed and inserted in
    # lowercase, but data in magic effects is Title Case?
    lowercase_fields = [:area_sound_id, :casting_sound_id, :hit_sound_id, :bolt_sound_id]

    data =
      records
      |> of_type(Resdayn.Parser.Record.MagicEffect)
      |> Enum.map(fn record ->
        {bool_flags, data} = Map.pop!(record.data, :flags)

        lowercase_fields
        |> Enum.reduce(data, fn field, acc ->
          Map.update(acc, field, nil, &String.downcase(&1))
        end)
        |> Map.merge(bool_flags)
        |> with_flags(record)
      end)

    %{resource: Resdayn.Codex.Mechanics.MagicEffect, data: data}
  end
end
