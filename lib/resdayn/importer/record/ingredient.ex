defmodule Resdayn.Importer.Record.Ingredient do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    # Need a magic effect mapping to know which invalid ingredient effect values need to be removed
    magic_effects =
      of_type(records, Resdayn.Parser.Record.MagicEffect)
      |> Enum.reduce(%{}, fn effect, acc ->
        with_flags(acc, effect.data.id, %{
          skill_id: String.ends_with?(effect.data.game_setting_id, "Skill"),
          attribute_id: String.ends_with?(effect.data.game_setting_id, "Attribute")
        })
      end)

    data =
      records
      |> of_type(Resdayn.Parser.Record.Ingredient)
      |> Enum.map(fn record ->
        record.data
        |> Map.update!(:effects, fn effects ->
          Enum.map(effects, fn effect ->
            ref = Map.fetch!(magic_effects, effect.magic_effect_id)

            effect
            |> remove_invalid_ref(ref, :skill_id)
            |> remove_invalid_ref(ref, :attribute_id)
          end)
        end)
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Items.Ingredient,
      data: data
    }
  end

  defp remove_invalid_ref(data, [key], key), do: data
  defp remove_invalid_ref(data, _, key), do: Map.put(data, key, nil)
end
