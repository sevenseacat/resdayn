defmodule Resdayn.Codex.Export.Override do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Export,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "overrides"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:record_id, :resource_type]
      upsert? true
      upsert_identity :unique_record
      upsert_fields [:updated_at]
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :record_id, :ci_string, allow_nil?: false, public?: true
    attribute :resource_type, __MODULE__.ResourceType, allow_nil?: false, public?: true

    timestamps()
  end

  identities do
    identity :unique_record, [:record_id, :resource_type]
  end
end
