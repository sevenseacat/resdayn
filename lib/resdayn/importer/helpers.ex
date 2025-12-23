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

  First builds lookup from parsed records in the current import batch, then
  falls back to loading from the database for templates not in the batch
  (e.g., when importing a mod that depends on Morrowind.esm's templates).
  """
  def build_magic_effect_template_lookup(records) do
    # First, build lookup from parsed records in this batch
    from_records =
      records
      |> Enum.filter(&match?(%{type: Resdayn.Parser.Record.MagicEffect}, &1))
      |> Map.new(fn record ->
        {record.data.id, record.data.game_setting_id}
      end)

    # If we found templates in the batch, use them
    # Otherwise, load from database (for mods depending on base game templates)
    if map_size(from_records) > 0 do
      from_records
    else
      load_templates_from_database()
    end
  end

  defp load_templates_from_database do
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

    uses_skill = String.ends_with?(game_setting_id, "Skill")
    uses_attribute = String.ends_with?(game_setting_id, "Attribute")

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
