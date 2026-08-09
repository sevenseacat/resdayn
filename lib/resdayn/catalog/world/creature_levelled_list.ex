defmodule Resdayn.Catalog.World.CreatureLevelledList do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "creature_levelled_lists"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false

    attribute :chance_none, :integer, allow_nil?: false, constraints: [min: 0, max: 100]

    # LEVC has no per-item flag: bit 0x2 is never set across the 1,168 creature
    # lists in MW/TB/BM/TR. LEVI uses both bits.
    attribute :from_all_lower_levels, :boolean, allow_nil?: false, default: false

    attribute :entries, {:array, Resdayn.Catalog.LevelledListEntry}, default: []
  end
end
