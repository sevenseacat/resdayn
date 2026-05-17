defmodule Resdayn.Codex.QuestAnalysis.Transition do
  use Ash.TypedStruct

  typed_struct do
    field :id, :string, allow_nil?: false

    field :from_min, :integer
    field :from_max, :integer
    field :index, :integer, allow_nil?: false

    # Triggers
    field :trigger_type, :atom do
      constraints one_of: [:dialogue_response, :script]
    end

    field :trigger_id, :ci_string, allow_nil?: false
    # Dialogue triggers only
    field :trigger_topic_id, :ci_string
  end

  @doc """
  Generate a deterministic, human-readable id for a transition from its
  trigger_id and target index. Stable across runs.
  """
  def make_id(trigger_id, index) do
    "#{to_string(trigger_id)}_#{index}"
  end
end
