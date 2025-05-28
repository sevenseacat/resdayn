defmodule Resdayn.Codex.Items.ItemLevelledList do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "item_levelled_lists"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  changes do
    change {Resdayn.Codex.Changes.CreateReferencableObject, object_type: :item_levelled_list},
      on: [:create]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false

    attribute :chance_none, :integer, allow_nil?: false, constraints: [min: 0, max: 100]
    attribute :for_each_item, :boolean, allow_nil?: false, default: false
    attribute :from_all_lower_levels, :boolean, allow_nil?: false, default: false

    attribute :items, {:array, __MODULE__.Item}, default: []
  end

  relationships do
    belongs_to :referencable_object, Resdayn.Codex.World.ReferencableObject,
      source_attribute: :id,
      destination_attribute: :id,
      define_attribute?: false
  end
end
