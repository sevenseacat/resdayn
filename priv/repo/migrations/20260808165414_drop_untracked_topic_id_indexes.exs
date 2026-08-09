defmodule Resdayn.Repo.Migrations.DropUntrackedTopicIdIndexes do
  @moduledoc """
  Drops two indexes nothing ever asked for.

  `index?` is false in every snapshot, but ash_postgres 2.11.0 adds a reference
  index when a plain column becomes a foreign key: it compares the old attribute's
  `index?` (nil, since there was no references block) against the new one (false),
  and `nil != false`. The same comparison fires when a foreign key is removed,
  which is what collided in 20260808114540.

  Codegen can't generate this, since by its own snapshots there is nothing to drop.
  """

  use Ecto.Migration

  def up do
    drop_if_exists(index(:actor_involvements, [:dialogue_response_topic_id]))
    drop_if_exists(index(:transitions, [:dialogue_response_topic_id]))
  end

  def down do
    create_if_not_exists(index(:actor_involvements, [:dialogue_response_topic_id]))
    create_if_not_exists(index(:transitions, [:dialogue_response_topic_id]))
  end
end
