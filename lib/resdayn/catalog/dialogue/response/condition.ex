defmodule Resdayn.Catalog.Dialogue.Response.Condition do
  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :function, Resdayn.Catalog.Dialogue.Response.Function, public?: true
    attribute :name, :string, public?: true
    attribute :operator, Resdayn.Catalog.Dialogue.Response.Operator, public?: true
    attribute :value, Resdayn.Catalog.Types.Number, public?: true
  end
end
