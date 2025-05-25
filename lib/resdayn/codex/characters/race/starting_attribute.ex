defmodule Resdayn.Codex.Characters.Race.StartingAttribute do
  use Ash.Resource,
    otp_app: :resdayn,
    data_layer: :embedded

  attributes do
    attribute :value, :integer, allow_nil?: false, public?: true
  end

  relationships do
    belongs_to :attribute, Resdayn.Codex.Mechanics.Attribute,
      attribute_type: :integer,
      allow_nil?: false,
      public?: true
  end
end
