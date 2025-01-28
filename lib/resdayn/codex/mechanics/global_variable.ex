defmodule Resdayn.Codex.Mechanics.GlobalVariable do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Mechanics,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "global_variables"
    repo Resdayn.Repo
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :value, Resdayn.Codex.Mechanics.Number, allow_nil?: false

    attribute :flags, Resdayn.Codex.Flags, allow_nil?: false
  end
end
