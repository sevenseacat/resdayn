defmodule Resdayn.Codex.Calculations.ReferenceCounts do
  use Ash.Resource.Calculation

  def load(_query, _opts, _context) do
    [referencable_object: [:cell_references_count, :inventory_items_count]]
  end

  def calculate(records, opts, _context) do
    field = opts[:field]

    Enum.map(records, fn record ->
      case record.referencable_object do
        %{^field => count} when is_integer(count) -> count
        _ -> 0
      end
    end)
  end
end
