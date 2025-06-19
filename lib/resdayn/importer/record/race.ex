defmodule Resdayn.Importer.Record.Race do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Race)
    |> Enum.map(fn record ->
      record.data
      |> Map.take([:id, :name, :description, :playable, :beast])
      |> Map.put(:male_stats, transform_stats(record.data.male_attributes))
      |> Map.put(:female_stats, transform_stats(record.data.female_attributes))
      |> Map.put(:special_spells, transform_special_spells(record.data.special_ids || []))
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Characters.Race, opts)
  end

  defp transform_stats(attrs) do
    starting_attributes =
      attrs
      |> Map.drop([:height, :weight])
      |> Enum.map(fn {attr_name, value} ->
        %{
          attribute_id: attribute_name_to_id(attr_name),
          value: value
        }
      end)

    %{
      height: attrs.height,
      weight: attrs.weight,
      starting_attributes: starting_attributes
    }
  end

  defp transform_special_spells(spell_ids) do
    Enum.map(spell_ids, fn spell_id ->
      %{spell_id: spell_id}
    end)
  end

  # Map attribute names to their IDs based on the existing Attribute resource
  defp attribute_name_to_id(:strength), do: 0
  defp attribute_name_to_id(:intelligence), do: 1
  defp attribute_name_to_id(:willpower), do: 2
  defp attribute_name_to_id(:agility), do: 3
  defp attribute_name_to_id(:speed), do: 4
  defp attribute_name_to_id(:endurance), do: 5
  defp attribute_name_to_id(:personality), do: 6
  defp attribute_name_to_id(:luck), do: 7
end
