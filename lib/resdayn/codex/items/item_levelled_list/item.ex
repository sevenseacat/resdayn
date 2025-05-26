defmodule Resdayn.Codex.Items.ItemLevelledList.Item do
  use Ash.Type.NewType,
    subtype_of: :map,
    constraints: [
      fields: [item_id: [type: :string], item_type: [type: :atom], player_level: [type: :integer]]
    ]
end
