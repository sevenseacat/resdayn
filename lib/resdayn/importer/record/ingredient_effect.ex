defmodule Resdayn.Importer.Record.IngredientEffect do
  @moduledoc """
  Imports the many-to-many relationship between Ingredients and MagicEffects.
  """

  use Resdayn.Importer.Record

  alias Resdayn.Importer.Helpers

  def process(records, _opts) do
    template_lookup = Helpers.build_magic_effect_template_lookup(records)

    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Ingredient)
      |> Enum.map(fn record ->
        ingredient_effects =
          record.data
          |> Map.get(:effects, [])
          |> Enum.map(fn effect ->
            {skill_id, attribute_id} =
              Helpers.filter_magic_effect_values(
                effect.magic_effect_id,
                effect.skill_id,
                effect.attribute_id,
                template_lookup
              )

            magic_effect_id =
              Helpers.build_magic_effect_id(effect.magic_effect_id, skill_id, attribute_id)

            %{magic_effect_id: magic_effect_id}
          end)

        %{
          id: record.data.id,
          ingredient_effects: ingredient_effects
        }
      end)

    %{
      type: :bulk_relationship,
      parent_resource: Resdayn.Codex.Items.Ingredient,
      related_resource: Resdayn.Codex.Items.Ingredient.Effect,
      parent_key: :ingredient_id,
      id_field: :magic_effect_id,
      relationship_key: :ingredient_effects,
      on_missing: :destroy,
      records: processed_records
    }
  end
end
