defmodule Resdayn.Repo.Migrations.CreateBirthsigns do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:birthsigns, primary_key: false) do
      add(:id, :text, null: false, primary_key: true)
      add(:name, :text, null: false)
      add(:description, :text)
      add(:artwork_filename, :text)
      add(:spells, {:array, :map}, null: false, default: [])
      add(:flags, {:array, :text}, null: false, default: [])
    end
  end

  def down do
    drop(table(:birthsigns))
  end
end
