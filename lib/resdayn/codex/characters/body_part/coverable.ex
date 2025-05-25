defmodule Resdayn.Codex.Characters.BodyPart.Coverable do
  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :type, Resdayn.Codex.Characters.BodyPart.CoverableType, public?: true
    attribute :base_nif_model_filename, :string, public?: true
    attribute :female_nif_model_filename, :string, public?: true
  end
end
