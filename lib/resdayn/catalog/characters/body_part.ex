defmodule Resdayn.Catalog.Characters.BodyPart do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "body_parts"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :nif_model_filename, :string
    attribute :type, __MODULE__.Type, allow_nil?: false
    attribute :equipment_type, __MODULE__.EquipmentType, allow_nil?: false
    attribute :vampire, :boolean, default: false
    attribute :body_part_flags, {:array, __MODULE__.Flag}, allow_nil?: false, default: []
  end

  relationships do
    belongs_to :race, Resdayn.Catalog.Characters.Race
  end
end
