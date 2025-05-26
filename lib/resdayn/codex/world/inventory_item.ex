defmodule Resdayn.Codex.World.InventoryItem do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "inventory_items"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    integer_primary_key :id

    attribute :count, :integer, allow_nil?: false, constraints: [min: 1], default: 1
    attribute :restocking?, :boolean, allow_nil?: false, default: false
  end

  relationships do
    belongs_to :npc, Resdayn.Codex.World.NPC, attribute_type: :string

    belongs_to :tool, Resdayn.Codex.Items.Tool, attribute_type: :string
    belongs_to :clothing, Resdayn.Codex.Items.Clothing, attribute_type: :string
    belongs_to :weapon, Resdayn.Codex.Items.Weapon, attribute_type: :string
    belongs_to :armor, Resdayn.Codex.Items.Armor, attribute_type: :string
    belongs_to :book, Resdayn.Codex.Items.Book, attribute_type: :string
    belongs_to :ingredient, Resdayn.Codex.Items.Ingredient, attribute_type: :string
    belongs_to :potion, Resdayn.Codex.Items.Potion, attribute_type: :string
    belongs_to :alchemy_apparatus, Resdayn.Codex.Items.AlchemyApparatus, attribute_type: :string
    belongs_to :light, Resdayn.Codex.Assets.Light, attribute_type: :string
    belongs_to :miscellaneous_item, Resdayn.Codex.Items.MiscellaneousItem, attribute_type: :string
    belongs_to :item_levelled_list, Resdayn.Codex.Items.ItemLevelledList, attribute_type: :string
  end

  calculations do
    calculate :item, :struct, __MODULE__.Item
  end
end
