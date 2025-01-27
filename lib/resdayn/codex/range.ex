defmodule Resdayn.Codex.Range do
  @constraints [
    validate?: [
      type: :boolean,
      default: true,
      doc: "Enforces that the maximum is always greater than or equal to the minimum"
    ]
  ]

  @moduledoc """
  Defines a range type, with min and max values.

  ### Constraints

  #{Spark.Options.docs(@constraints)}
  """
  use Ash.Type

  @impl true
  def storage_type(_), do: {:array, :integer}

  @impl true
  def constraints, do: @constraints

  @impl true
  def cast_input(nil, _), do: {:ok, nil}
  def cast_input([min, max], _), do: {:ok, %{min: min, max: max}}
  def cast_input(%{min: _, max: _} = value, _), do: {:ok, value}

  @impl true
  def cast_stored(nil, _), do: {:ok, nil}
  def cast_stored([min, max], _), do: {:ok, %{min: min, max: max}}

  @impl true
  def dump_to_native(nil, _), do: {:ok, nil}
  def dump_to_native(%{min: min, max: max}, _), do: {:ok, [min, max]}

  def apply_constraints(nil, _), do: {:ok, nil}

  def apply_constraints(%{min: min, max: max} = value, constraints) do
    errors =
      Enum.reduce(constraints, [], fn
        {:validate?, validate}, errors ->
          if validate && min > max do
            [[message: "min must be less than or equal to max", min: min, max: max] | errors]
          else
            errors
          end
      end)

    case errors do
      [] -> {:ok, value}
      errors -> {:error, errors}
    end
  end
end
