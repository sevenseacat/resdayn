defmodule Resdayn.Importer.Helpers do
  @moduledoc """
  Shared helper functions for importer record modules.
  """

  require Ash.Query

  @cell_size 8192

  @doc """
  Convert exterior coordinates into cell IDs.

  Each cell in Morrowind is a #{@cell_size}x#{@cell_size} square.
  """
  def coordinates_to_cell_id(%{x: x, y: y}) do
    grid_x = floor_div(x, @cell_size)
    grid_y = floor_div(y, @cell_size)

    "#{grid_x},#{grid_y}"
  end

  defp floor_div(value, divisor) do
    (value / divisor) |> Float.floor() |> trunc()
  end

  # =============================================================================
  # Magic Effect Helpers
  # =============================================================================

  @doc """
  Build a lookup map of template_id -> game_setting_id from parsed MagicEffect records.

  This is used to determine whether effects use skills or attributes.
  """
  def build_magic_effect_template_lookup do
    Resdayn.Codex.Mechanics.MagicEffectTemplate
    |> Ash.Query.select([:id, :game_setting_id])
    |> Ash.read!()
    |> Map.new(fn template ->
      {template.id, template.game_setting_id}
    end)
  end

  @doc """
  Filter out invalid skill_id/attribute_id values based on the effect template.

  Effects only use skill_id if the template's game_setting_id ends with "Skill".
  Effects only use attribute_id if the template's game_setting_id ends with "Attribute".

  Returns `{filtered_skill_id, filtered_attribute_id}`.
  """
  def filter_magic_effect_values(template_id, skill_id, attribute_id, template_lookup) do
    game_setting_id = Map.get(template_lookup, template_id, "")

    uses_skill = String.ends_with?(to_string(game_setting_id), "Skill")
    uses_attribute = String.ends_with?(to_string(game_setting_id), "Attribute")

    filtered_skill_id = if uses_skill, do: skill_id, else: nil
    filtered_attribute_id = if uses_attribute, do: attribute_id, else: nil

    {filtered_skill_id, filtered_attribute_id}
  end

  @doc """
  Build a composite magic_effect_id from template_id, skill_id, and attribute_id.

  Format: "template_id:skill_id:attribute_id" where nil values become empty strings.
  """
  def build_magic_effect_id(template_id, skill_id, attribute_id) do
    "#{template_id}:#{skill_id}:#{attribute_id}"
  end
end
