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
    "ARMO" => __MODULE__.Armor,
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
    "INFO" => __MODULE__.DialogueResponse,
    "SSCR" => __MODULE__.StartScript
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
        <<count::int32(), id::char(32)>> = value

        record_list(data, unquote(key), %{
          count: abs(count),
          id: printable!(__MODULE__, unquote(key), id),
          restocking: count < 0
        })
      end
    end
  end

  @doc """
  Generate a function to process an enchantment's details
  This applies to spell effects, and also enchantments on clothing, weapons, etc.
  """
  defmacro process_enchantments(raw, key) do
    quote do
      def process({unquote(raw), value}, data) do
        spell_range_mapping = %{
          0 => :self,
          1 => :touch,
          2 => :target
        }

        <<effect::uint16(), skill::int8(), attribute::int8(), range::uint32(), area::uint32(),
          duration::uint32(), min::uint32(), max::uint32()>> = value

        record_list(data, unquote(key), %{
          magic_effect_id: effect,
          skill_id: nil_if_negative(skill),
          attribute_id: nil_if_negative(attribute),
          range: Map.fetch!(spell_range_mapping, range),
          area: area,
          duration: duration,
          magnitude: %{min: min, max: max}
        })
      end
    end
  end

  defmacro process_ai_packages do
    quote do
      def process({"AIDT", value}, data) do
        <<hello::uint8(), _::uint8(), fight::uint8(), flee::uint8(), alarm::uint8(), _::char(3),
          flags::uint32()>> =
          value

        record_value(data, :ai_data, %{
          hello: hello,
          fight: fight,
          flee: flee,
          alarm: alarm,
          flags:
            bitmask(flags,
              weapon: 0x00001,
              armor: 0x00002,
              clothing: 0x00004,
              books: 0x00008,
              ingredients: 0x00010,
              picks: 0x00020,
              probes: 0x00040,
              lights: 0x00080,
              apparatus: 0x00100,
              repair: 0x00200,
              misc: 0x00400,
              spells: 0x00800,
              magic_items: 0x01000,
              potions: 0x02000,
              training: 0x04000,
              spellmaking: 0x08000,
              enchanting: 0x10000,
              repair_item: 0x20000
            )
        })
      end

      def process({"CNDT" = v, value}, data) do
        record_list_of_maps_value(data, :ai_packages, :cell, printable!(__MODULE__, v, value))
      end

      def process({"AI_W", value}, data) do
        <<distance::uint16(), duration::uint16(), time_of_day::uint8(), idles::char(8),
          1::uint8(), _rest::binary>> = value

        record_list(data, :ai_packages, %{
          type: :wander,
          distance: distance,
          duration: duration(duration),
          time_of_day: time_of_day,
          idles: :binary.bin_to_list(idles)
        })
      end

      def process({"AI_E", value}, data) do
        follow_or_escort(data, :escort, value)
      end

      def process({"AI_F", value}, data) do
        follow_or_escort(data, :follow, value)
      end

      def process({"AI_T", value}, data) do
        <<x::float32(), y::float32(), z::float32(), 1::uint8(), _rest::binary>> = value

        record_list(data, :ai_packages, %{
          type: :travel,
          position: {float(x), float(y), float(z)}
        })
      end

      # Duration parameters in all packages are in hours. Any value greater than 24
      # should be divided by 100, and set to 24 if still greater than 24.
      defp duration(num), do: min(rem(num, 100), 24)

      defp follow_or_escort(data, type, value) do
        <<x::float32(), y::float32(), z::float32(), duration::uint16(), id::char(32),
          _rest::binary>> = value

        id = printable!(__MODULE__, type, id)

        if id == nil do
          raise RuntimeError,
                "check what the position is #{inspect({float(x), float(y), float(z)})}"
        end

        record_list(data, :ai_packages, %{
          type: type,
          position: {float(x), float(y), float(z)},
          duration: duration(duration),
          id: id
        })
      end
    end
  end

  defmacro process_body_coverings do
    quote do
      def process({"INDX", <<value::uint8()>>}, data) do
        record_list_of_maps_key(
          data,
          :body_part_coverings,
          :type,
          Map.fetch!(Resdayn.Parser.Record.BodyPart.coverables(), value)
        )
      end

      def process({"BNAM" = v, value}, data) do
        record_list_of_maps_value(
          data,
          :body_part_coverings,
          :base_nif_model_filename,
          printable!(__MODULE__, v, value)
        )
      end

      def process({"CNAM" = v, value}, data) do
        record_list_of_maps_value(
          data,
          :body_part_coverings,
          :female_nif_model_filename,
          printable!(__MODULE__, v, value)
        )
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
        if Map.has_key?(map, key) do
          raise RuntimeError, "Map key `#{key}` already exists in `#{inspect(map)}`"
        end

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

      **IMPORTANT**: Lists will be returned in reverse order than they appear in
      the source record - if order is important, make sure to reverse the list before use.

      eg. a Faction record has ten RNAM (rank name) subrecords
      """
      def record_list(map, key, value) do
        Map.update(map, key, [value], &[value | &1])
      end

      @doc """
      Record a list of values for a record, when fields always appear in sets.

      **IMPORTANT**: Lists will be returned in reverse order than they appear in
      the source record - if order is important, make sure to reverse the list before use.

      eg. a MainHeader record can have multiple pairs of MAST/DATA subrecords,
      representing dependency names and sizes.
      """
      def record_list_of_maps_key(map, pair_key, record_key, value) do
        Map.update(map, pair_key, [%{record_key => value}], &[%{record_key => value} | &1])
      end

      def record_list_of_maps_value(map, pair_key, record_key, value) do
        Map.update!(map, pair_key, fn [head | rest] ->
          if Map.has_key?(head, record_key) do
            raise RuntimeError,
                  "Pair #{pair_key} (#{inspect(head)}) already has key `#{record_key}`"
          end

          [Map.put(head, record_key, value) | rest]
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
