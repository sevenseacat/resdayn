defmodule Resdayn.Parser.Record do
  @types %{
    "TES3" => __MODULE__.MainHeader,
    "GMST" => __MODULE__.GameSetting,
    "GLOB" => __MODULE__.GlobalVariable,
    "CLAS" => __MODULE__.Class,
    "FACT" => __MODULE__.Faction,
    "RACE" => __MODULE__.Race,
    "SOUN" => __MODULE__.Sound,
    "SKIL" => __MODULE__.Skill,
    "MGEF" => __MODULE__.MagicEffect,
    "SCPT" => __MODULE__.Script,
    "REGN" => __MODULE__.Region,
    "BSGN" => __MODULE__.Birthsign,
    "LTEX" => __MODULE__.LandTexture,
    "STAT" => __MODULE__.Static,
    "DOOR" => __MODULE__.Door,
    "MISC" => __MODULE__.MiscellaneousItem,
    "WEAP" => __MODULE__.Weapon,
    "CONT" => __MODULE__.Container,
    "SPEL" => __MODULE__.Spell,
    "CREA" => __MODULE__.Creature,
    "BODY" => __MODULE__.BodyPart,
    "LIGH" => __MODULE__.Light,
    "ENCH" => __MODULE__.Enchantment,
    "NPC_" => __MODULE__.NPC,
    "ARMO" => __MODULE__.Armour,
    "CLOT" => __MODULE__.Clothing,
    "REPA" => __MODULE__.RepairItem,
    "ACTI" => __MODULE__.Activator,
    "APPA" => __MODULE__.AlchemyApparatus,
    "LOCK" => __MODULE__.Lockpick,
    "PROB" => __MODULE__.Probe,
    "INGR" => __MODULE__.Ingredient,
    "BOOK" => __MODULE__.Book,
    "ALCH" => __MODULE__.Potion,
    "LEVI" => __MODULE__.LevelledItem,
    "LEVC" => __MODULE__.LevelledCreature,
    "CELL" => __MODULE__.Cell,
    "LAND" => __MODULE__.Land,
    "PGRD" => __MODULE__.PathGrid,
    "SNDG" => __MODULE__.SoundGenerator,
    "DIAL" => __MODULE__.DialogueTopic,
    "INFO" => __MODULE__.DialogueResponse
  }

  @doc """
  Convert a record type string into a meaningful constant.
  """
  def to_module(type) do
    Map.fetch!(@types, type)
  end

  @doc "Generate a function to process and store a printable string"
  defmacro process_basic_string(raw, key) do
    quote do
      def process({unquote(raw), value}, data) do
        record_value(data, unquote(key), printable!(__MODULE__, unquote(raw), value))
      end
    end
  end

  @doc "Generate a function to process and store a list of printable strings"
  defmacro process_basic_list(raw, key) do
    quote do
      def process({unquote(raw), value}, data) do
        record_list(data, unquote(key), printable!(__MODULE__, unquote(raw), value))
      end
    end
  end

  @doc """
  Generate a function to process and store a list of held items/quantities
  Used for container contents, and NPC/creature inventories
  """
  defmacro process_inventory(raw, key) do
    quote do
      def process({unquote(raw), value}, data) do
        <<count::uint32(), id::char(32)>> = value

        record_list(data, unquote(key), %{
          count: abs(count),
          id: printable!(__MODULE__, unquote(key), id),
          restocking: count < 0
        })
      end
    end
  end

  @doc "Process a single subrecord for thhis record type."
  @callback process({key :: String.t(), value :: any}, data :: map) :: map

  defmacro __using__(_opts) do
    quote do
      @behaviour Resdayn.Parser.Record
      require Resdayn.Parser.Record
      import Resdayn.Parser.{DataSizes, Helpers, Record}

      @doc "Process a collection of subrecords for this record type"
      def process(records) do
        Enum.reduce(records, %{}, &process/2)
      end

      @doc """
      Record a single value for a record.
      Used when a record only has one instance of a given subrecord type.

      eg. all records only have one NAME subrecord
      """
      def record_value(map, key, value) do
        Map.put(map, key, value)
      end

      @doc """
      Merge a map of data into the record as a whole.
      Used when a record stores a lot of data into a single field, that should really
      be stored at the top level with other data.

      eg. a Class record stores a lot of stuff in a CLDT field, such as
      favoured attributes, specialization, and services provided (for NPCs)
      """
      def record_unnested_value(map, new_data) do
        if key = Enum.find(Map.keys(new_data), &Map.has_key?(map, &1)) do
          raise RuntimeError,
                "Unnesting data #{inspect(new_data)} for record #{inspect(map)} would overwrite key `#{key}`"
        end

        Map.merge(map, new_data)
      end

      @doc """
      Record a list of values for a record.
      Used when a record has multiple instances of a given subrecord type.
      Lists will maintain their order as they appear in the source file.

      eg. a Faction record has ten RNAM (rank name) subrecords
      """
      def record_list(map, key, value) do
        Map.update(map, key, [value], &(&1 ++ [value]))
      end

      @doc """
      Record a list of values for a record, when fields always appear in pairs.
      Lists will maintain their order as they appear in the source file.

      eg. a MainHeader record can have multiple pairs of MAST/DATA subrecords,
      representing dependency names and sizes.
      """
      def record_pair_key(map, pair_key, record_key, value) do
        Map.update(map, pair_key, [%{record_key => value}], &[%{record_key => value} | &1])
      end

      def record_pair_value(map, pair_key, record_key, value) do
        Map.update!(map, pair_key, fn [head | tail] ->
          if Map.has_key?(head, record_key) do
            raise RuntimeError,
                  "Pair #{pair_key} (#{inspect(head)}) already has key `#{record_key}`"
          end

          tail ++ [Map.put(head, record_key, value)]
        end)
      end

      @doc """
      Pop an already-processed subrecord from a record.
      This may be necessary when subrecords are paired together but are more
      complex than simple scalars

      eg. a Faction record stores a list of rank names in one subrecord, and a
      list of rank details in another subrecord - when processing the details,
      they can be zipped together with the names and then the names can be deleted
      """
      def pop_value(map, key, default \\ nil) do
        Map.pop(map, key, default)
      end
    end
  end
end
