defmodule Resdayn.Repo.Migrations.CreateClasses do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:classes, primary_key: false) do
      add(:id, :text, null: false, primary_key: true)
      add(:name, :text, null: false)
      add(:description, :text)
      add(:services_offered, {:array, :text}, null: false, default: [])
      add(:playable, :boolean, null: false)
      add(:specialization, :text, null: false)
      add(:items_vendored, {:array, :text}, null: false, default: [])
      add(:flags, {:array, :text}, null: false, default: [])

      add(
        :attribute1_id,
        references(:attributes,
          column: :id,
          name: "classes_attribute1_id_fkey",
          type: :bigint,
          prefix: "public"
        ),
        null: false
      )

      add(
        :attribute2_id,
        references(:attributes,
          column: :id,
          name: "classes_attribute2_id_fkey",
          type: :bigint,
          prefix: "public"
        ),
        null: false
      )
    end

    create table(:class_skills, primary_key: false) do
      add(:category, :text, null: false)
      add(:flags, {:array, :text}, null: false, default: [])

      add(
        :class_id,
        references(:classes,
          column: :id,
          name: "class_skills_class_id_fkey",
          type: :text,
          prefix: "public"
        ),
        primary_key: true,
        null: false
      )

      add(
        :skill_id,
        references(:skills,
          column: :id,
          name: "class_skills_skill_id_fkey",
          type: :bigint,
          prefix: "public"
        ),
        primary_key: true,
        null: false
      )
    end
  end

  def down do
    drop(constraint(:class_skills, "class_skills_class_id_fkey"))

    drop(constraint(:class_skills, "class_skills_skill_id_fkey"))

    drop(table(:class_skills))

    drop(constraint(:classes, "classes_attribute1_id_fkey"))

    drop(constraint(:classes, "classes_attribute2_id_fkey"))

    drop(table(:classes))
  end
end
