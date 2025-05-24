defmodule Resdayn.Codex.Items do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Codex.Items.Ingredient
    resource Resdayn.Codex.Items.MiscellaneousItem
  end
end
