defmodule Resdayn.Repo.Migrations.CreateAttributes do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:attributes, primary_key: false) do
      add(:id, :bigint, null: false, primary_key: true)
      add(:name, :text, null: false)
    end
  end

  def down do
    drop(table(:attributes))
  end
end
