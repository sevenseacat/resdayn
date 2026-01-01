defmodule Resdayn.Importer.Quests.Script do
  @moduledoc """
  An AST definition for a parsed in-game script.
  This can be used for both standalone scripts, and dialogue response scripts.
  """

  defmodule Ast do
    # For dialogue scripts, name and locals will be nil
    defstruct [:name, :locals, :body]
  end

  defmodule IfBlock do
    defstruct [:condition, :body, :else_clause]
  end

  defmodule Journal do
    defstruct [:quest_id, :index]
  end

  defmodule Effect do
    defstruct [:type, :data]
  end

  defmodule Condition do
    defstruct [:type, :data]
  end
end
