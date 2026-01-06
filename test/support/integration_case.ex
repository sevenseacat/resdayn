defmodule Resdayn.IntegrationCase do
  @moduledoc """
  This module defines the setup for integration tests that require
  the Morrowind.esm data to be imported into the database.

  The import is run exactly once, before the first integration test runs,
  regardless of how many test modules use this case.

  ## Usage

      use Resdayn.IntegrationCase

  Note: Integration tests cannot be async because they share the imported data.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Resdayn.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Resdayn.IntegrationCase

      @moduletag :integration
    end
  end

  setup_all do
    ensure_morrowind_imported()
    :ok
  end

  setup tags do
    # Integration tests must not be async - they share the imported data
    if tags[:async] do
      raise "Integration tests cannot be async: true because they share imported data"
    end

    # Use shared mode for the sandbox since we're not async
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Resdayn.Repo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end

  @doc """
  Ensures Morrowind.esm has been imported exactly once.
  Safe to call from multiple test modules - only the first call will run the import.
  """
  def ensure_morrowind_imported do
    case :persistent_term.get(:morrowind_imported, false) do
      true ->
        :ok

      false ->
        # Use a lock to prevent race conditions if tests somehow start in parallel
        :global.set_lock({__MODULE__, :import_lock})

        try do
          # Double-check after acquiring lock
          if :persistent_term.get(:morrowind_imported, false) do
            :ok
          else
            do_import()
            :persistent_term.put(:morrowind_imported, true)
          end
        after
          :global.del_lock({__MODULE__, :import_lock})
        end
    end
  end

  defp do_import do
    # Truncate all tables before importing
    truncate_all_tables()

    # Run the import
    Resdayn.Importer.Runner.run("Morrowind.esm")
  end

  @doc """
  Returns the parsed Morrowind records, parsing them if not already cached.
  Useful for re-import tests.
  """
  def get_morrowind_records do
    case :persistent_term.get(:test_morrowind_records, nil) do
      nil ->
        path = Path.join([:code.priv_dir(:resdayn), "data", "Morrowind.esm"])
        records = Resdayn.Parser.read(path) |> Enum.to_list()
        :persistent_term.put(:test_morrowind_records, records)
        records

      records ->
        records
    end
  end

  defp truncate_all_tables do
    # Get all table names from public schema
    %{rows: rows} =
      Resdayn.Repo.query!("""
        SELECT tablename FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename != 'schema_migrations'
      """)

    tables = rows |> List.flatten() |> Enum.join(", ")

    if tables != "" do
      Resdayn.Repo.query!("TRUNCATE #{tables} CASCADE")
    end
  end
end
