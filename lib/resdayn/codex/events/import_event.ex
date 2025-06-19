defmodule Resdayn.Codex.Events.ImportEvent do
  @moduledoc """
  Event tracking for import operations on importable resources.
  """
  use Ash.Resource,
    domain: Resdayn.Codex.Events,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshEvents.Event]

  postgres do
    table "import_events"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]

    create :create do
      primary? true
      accept [:event_type, :resource_type, :resource_id, :source_file_id, :changes]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :event_type, :atom do
      allow_nil? false
      constraints one_of: [:record_created, :record_updated]
      public? true
    end

    attribute :resource_type, :string do
      allow_nil? false
      public? true
    end

    attribute :resource_id, :string do
      allow_nil? false
      public? true
    end

    attribute :source_file_id, :string do
      allow_nil? false
      public? true
    end

    attribute :changes, :map do
      allow_nil? false
      default %{}
      public? true
    end

    create_timestamp :occurred_at
  end

  relationships do
    belongs_to :source_file, Resdayn.Codex.Mechanics.DataFile,
      source_attribute: :source_file_id,
      destination_attribute: :filename
  end
end
