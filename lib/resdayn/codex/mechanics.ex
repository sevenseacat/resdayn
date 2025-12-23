defmodule Resdayn.Codex.Mechanics do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource __MODULE__.Attribute
    resource __MODULE__.DataFile
    resource __MODULE__.GameSetting

    resource __MODULE__.MagicEffect do
      define :list_magic_effects, action: :read
    end

    resource __MODULE__.MagicEffectTemplate

    resource __MODULE__.Script do
      define :get_script_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.GlobalVariable

    resource __MODULE__.Enchantment do
      define :get_enchantment_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.Spell do
      define :get_spell_by_id, action: :read, get_by: :id
    end
  end
end
