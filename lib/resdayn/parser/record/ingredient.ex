defmodule Resdayn.Parser.Record.Ingredient do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "FNAM", :name
  process_basic_string "ITEX", :icon
  process_basic_string "SCRI", :script_id

  def process({"IRDT", value}, data) do
    <<weight::float32(), value::uint32(), effects::char(16), skill_ids::char(16),
      attribute_ids::char(16)>> = value

    record_unnested_value(data, %{
      weight: float(weight),
      value: value,
      effects: effects(effects, skill_ids, attribute_ids)
    })
  end

  defp effects(<<>>, <<>>, <<>>), do: []

  defp effects(
         <<-1::int32(), effects::binary>>,
         <<_::int32(), skill_ids::binary>>,
         <<_::int32(), attribute_ids::binary>>
       ) do
    effects(effects, skill_ids, attribute_ids)
  end

  defp effects(
         <<effect::int32(), effects::binary>>,
         <<skill_id::int32(), skill_ids::binary>>,
         <<attribute_id::int32(), attribute_ids::binary>>
       ) do
    [
      %{magic_effect_id: effect, skill_id: skill_id, attribute_id: attribute_id}
      | effects(effects, skill_ids, attribute_ids)
    ]
  end
end
