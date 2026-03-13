defmodule Resdayn.Codex.Export.Override.ResourceType do
  @types %{
    tool: Resdayn.Codex.Items.Tool
  }

  use Ash.Type.Enum, values: Map.keys(@types)

  def type_to_resource(type) do
    Map.fetch!(@types, type)
  end

  def resource_to_type(module) do
    Enum.find(@types, fn {_, mod} -> mod == module end)
    |> elem(0)
  end
end
