defmodule Resdayn.Codex.Items do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Codex.Items.Ingredient
    resource Resdayn.Codex.Items.MiscellaneousItem
    resource Resdayn.Codex.Items.Tool
    resource Resdayn.Codex.Items.AlchemyApparatus
  end
end
