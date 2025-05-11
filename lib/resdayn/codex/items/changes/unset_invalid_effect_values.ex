defmodule Resdayn.Codex.Items.Changes.UnsetInvalidEffectValues do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    magic_effect_id = Ash.Changeset.get_attribute(changeset, :magic_effect_id)
    effect = Ash.get!(Resdayn.Codex.Mechanics.MagicEffect, magic_effect_id)

    changeset
    |> maybe_unset(!String.ends_with?(effect.game_setting_id, "Skill"), :skill_id)
    |> maybe_unset(!String.ends_with?(effect.game_setting_id, "Attribute"), :attribute_id)
  end

  defp maybe_unset(changeset, false, _key) do
    changeset
  end

  defp maybe_unset(changeset, true, key) do
    Ash.Changeset.change_attribute(changeset, key, nil)
  end
end
