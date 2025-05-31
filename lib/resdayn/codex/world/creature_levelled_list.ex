defmodule Resdayn.Codex.World.CreatureLevelledList do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable, Resdayn.Codex.Referencable]

  postgres do
    table "creature_levelled_lists"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false

    attribute :chance_none, :integer, allow_nil?: false, constraints: [min: 0, max: 100]
    attribute :for_each_item, :boolean, allow_nil?: false, default: false
    attribute :from_all_lower_levels, :boolean, allow_nil?: false, default: false

    attribute :creatures, {:array, __MODULE__.Creature}, default: []
  end
end
