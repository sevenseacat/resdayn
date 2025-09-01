defmodule Resdayn.Repo.Migrations.DropImportEvents do
  use Ecto.Migration

  def up do
    drop_if_exists(table(:import_events))
  end

  def down do
    create table(:import_events, primary_key: false) do
      add(:id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true)
      add(:event_type, :text, null: false)
      add(:resource_type, :text, null: false)
      add(:resource_id, :text, null: false)
      add(:source_file_id, :text, null: false)
      add(:changes, :map, null: false, default: %{})
      add(:occurred_at, :utc_datetime_usec, null: false, default: fragment("now()"))
    end

    alter table(:import_events) do
      add(:source_file_id_fkey, references(:data_files, column: :filename, type: :text))
    end
  end
end
