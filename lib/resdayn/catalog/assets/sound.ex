defmodule Resdayn.Catalog.Assets.Sound do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Assets,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "sounds"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false

    attribute :filename, :string, allow_nil?: true
    attribute :volume, :integer, allow_nil?: false, constraints: [min: 0, max: 255]

    attribute :range, Resdayn.Catalog.Types.Range,
      allow_nil?: false,
      constraints: [validate?: false]
  end
end
