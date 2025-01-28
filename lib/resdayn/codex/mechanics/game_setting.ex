defmodule Resdayn.Codex.Mechanics.GameSetting do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Mechanics,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "game_settings"
    repo Resdayn.Repo
  end

  attributes do
    attribute :name, :string, primary_key?: true, allow_nil?: false
    attribute :value, __MODULE__.Value, allow_nil?: true

    attribute :flags, Resdayn.Codex.Flags, allow_nil?: false
  end
end
