defmodule Resdayn.Codex.Items do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource __MODULE__.Ingredient
    resource __MODULE__.MiscellaneousItem
    resource __MODULE__.Tool
    resource __MODULE__.AlchemyApparatus
    resource __MODULE__.Potion
  end
end
