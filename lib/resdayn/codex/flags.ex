defmodule Resdayn.Codex.Flags do
  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :blocked, :boolean, allow_nil?: false, public?: true
    attribute :persistent, :boolean, allow_nil?: false, public?: true
    attribute :disabled, :boolean, allow_nil?: false, public?: true
    attribute :deleted, :boolean, allow_nil?: false, public?: true
  end
end
