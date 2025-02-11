defmodule Resdayn.Repo.Migrations.CreateEnchantments do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:enchantments, primary_key: false) do
      add(:id, :text, null: false, primary_key: true)
      add(:type, :text, null: false)
      add(:cost, :bigint, null: false)
      add(:charge, :bigint, null: false)
      add(:autocalc, :boolean, null: false)
      add(:effects, {:array, :map}, null: false, default: [])
      add(:flags, {:array, :text}, null: false, default: [])
    end
  end

  def down do
    drop(table(:enchantments))
  end
end
