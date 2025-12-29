defmodule Resdayn.Codex.Items.AlchemyApparatus.Type do
  use Ash.Type.Enum,
    values: [
      mortar_and_pestle: [label: "Mortar and Pestle"],
      alembic: [label: "Alembic"],
      calcinator: [label: "Calcinator"],
      retort: [label: "Retort"]
    ]
end
