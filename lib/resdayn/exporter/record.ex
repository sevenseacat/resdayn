defmodule Resdayn.Exporter.Record do
  @moduledoc """
  Convention-based lookup from Ash resource modules to exporter encoder modules.
  """

  def encoder_for(resource_module) do
    base = resource_module |> Module.split() |> List.last()
    Module.concat(__MODULE__, base)
  end
end
