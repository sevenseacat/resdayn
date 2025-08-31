defmodule Resdayn.Codex.Items.AlchemyApparatus.Type do
  use Ash.Type.Enum,
    values: [
      mortar_and_pestle: "Mortar and pestle",
      alembic: "Alembic",
      calcinator: "Calcinator",
      retort: "Retort"
    ]
end
