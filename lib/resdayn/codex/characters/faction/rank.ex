defmodule Resdayn.Codex.Characters.Faction.Rank do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Characters,
    data_layer: :embedded

  attributes do
    attribute :name, :string, allow_nil?: false, public?: true

    attribute :required_reputation, :integer,
      allow_nil?: false,
      public?: true,
      constraints: [min: 0]

    attribute :required_attribute_levels, {:array, :integer},
      constraints: [min_length: 2, max_length: 2, items: [min: 0]],
      public?: true

    attribute :required_skill_levels, {:array, :integer},
      constraints: [min_length: 2, max_length: 2, items: [min: 0]],
      public?: true
  end
end
