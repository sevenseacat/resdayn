defmodule Resdayn.Codex.Mechanics.Script do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Mechanics,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "scripts"
    repo Resdayn.Repo
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false, public?: true

    attribute :text, :string, allow_nil?: false, public?: true
    attribute :local_variables, {:array, :string}, default: [], public?: true
    attribute :start_script, :boolean, default: false, public?: true

    attribute :flags, Resdayn.Codex.Flags, allow_nil?: false, public?: true
  end
end
