defmodule Resdayn.Codex.Mechanics.DataFile.Dependency do
  use Ash.Resource, otp_app: :resdayn, data_layer: :embedded

  attributes do
    attribute :filename, :string, allow_nil?: false, public?: true
    attribute :size, :integer, allow_nil?: false, public?: true
  end
end
