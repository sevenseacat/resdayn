defmodule Resdayn.Catalog.Mechanics.Attribute do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Mechanics,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "attributes"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :integer, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: false
  end

  relationships do
    belongs_to :description_game_setting, Resdayn.Catalog.Mechanics.GameSetting do
      description "The game setting that holds the description text for the attribute"
    end
  end

  calculations do
    calculate :description, :string, expr(description_game_setting.value[:value])
  end
end
