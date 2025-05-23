defmodule Resdayn.Codex.Mechanics do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource __MODULE__.Attribute
    resource __MODULE__.DataFile
    resource __MODULE__.Enchantment
    resource __MODULE__.GameSetting
    resource __MODULE__.MagicEffect
    resource __MODULE__.Script
    resource __MODULE__.GlobalVariable
    resource __MODULE__.Spell
  end
end
