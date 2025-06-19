defmodule Resdayn.Codex.Dialogue.Response.Condition do
  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :function, Resdayn.Codex.Dialogue.Response.Function, public?: true
    attribute :name, :string, public?: true
    attribute :operator, Resdayn.Codex.Dialogue.Response.Operator, public?: true
    attribute :value, Resdayn.Codex.Types.Number, public?: true
  end
end
