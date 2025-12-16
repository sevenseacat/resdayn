defmodule Resdayn.Codex.Items do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource __MODULE__.Ingredient do
      define :get_ingredient_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.MiscellaneousItem

    resource __MODULE__.Tool do
      define :get_tool_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.AlchemyApparatus do
      define :get_alchemy_apparatus_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.Potion do
      define :get_potion_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.Book do
      define :get_book_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.Clothing do
      define :get_clothing_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.Weapon do
      define :get_weapon_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.Armor do
      define :get_armor_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.ItemLevelledList
  end
end
