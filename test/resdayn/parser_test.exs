defmodule Resdayn.ParserTest do
  use ExUnit.Case, async: true

  alias Resdayn.Parser

  @master_index_path Path.join([:code.priv_dir(:resdayn), "data", "master_index.esp"])

  describe "read_binary/1" do
    test "produces identical results to read/1" do
      file_records = Parser.read(@master_index_path) |> Enum.to_list()
      binary_records = Parser.read_binary(File.read!(@master_index_path))

      assert file_records == binary_records
    end
  end
end
