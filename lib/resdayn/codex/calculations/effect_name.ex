defmodule Resdayn.Codex.Calculations.EffectName do
  @moduledoc """
  Calculation for building user-friendly effect display names.

  Combines magic effect template name with skill/attribute name when applicable.
  For example: "Fortify Attribute" + "Strength" -> "Fortify Strength"
  """

  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context) do
    [skill: [:name], attribute: [:name], template: [:name]]
  end

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, &build_name/1)
  end

  defp build_name(record) do
    template_name = record.template.name

    cond do
      record.skill_id ->
        build_display_name(template_name, "Skill", record.skill.name)

      record.attribute_id ->
        build_display_name(template_name, "Attribute", record.attribute.name)

      true ->
        template_name
    end
  end

  defp build_display_name(template_name, suffix, target_name) when is_binary(target_name) do
    String.replace(template_name, " #{suffix}", " #{target_name}")
  end
end
