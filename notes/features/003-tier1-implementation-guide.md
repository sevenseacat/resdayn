# Tier 1 Implementation Guide

## Proven Pattern (from MISC implementation)

Based on the successful implementation of miscellaneous items, here's the refined step-by-step guide for each remaining record type.

## Step-by-Step Process

### 1. Analyze Parser Structure
```bash
# Check the parser file to understand data structure
cat lib/resdayn/parser/record/<record_name>.ex
```

Key things to identify:
- Required vs optional fields
- Field name mappings (parser vs resource names)
- Special data transformations needed
- Flag structures

### 2. Create Ash Resource

Location: `lib/resdayn/codex/<domain>/<resource_name>.ex`

Template:
```elixir
defmodule Resdayn.Codex.<Domain>.<ResourceName> do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.<Domain>,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "<table_name>"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: false
    # Add other attributes based on parser structure
  end

  relationships do
    belongs_to :script, Resdayn.Codex.Mechanics.Script, attribute_type: :string
    # Add other relationships as needed
  end
end
```

### 3. Create Importer Module

Location: `lib/resdayn/importer/record/<record_name>.ex`

Template:
```elixir
defmodule Resdayn.Importer.Record.<RecordName> do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.<ParserName>)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :name, :value, :weight, :script_id, ...])
        |> Map.put(:nif_model_filename, record.data.nif_model)
        # Add other field mappings as needed
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.<Domain>.<ResourceName>,
      data: data
    }
  end
end
```

### 4. Add to Domain

Update `lib/resdayn/codex/<domain>.ex`:
```elixir
resources do
  # existing resources...
  resource Resdayn.Codex.<Domain>.<ResourceName>
end
```

### 5. Generate Migration

```bash
mix ash.codegen create_<table_name>
mix ecto.migrate
```

### 6. Add to Import Task

Update `lib/mix/tasks/resdayn/import_codex.ex` in the `run_importer` function:
```elixir
[
  # existing importers...
  Record.<RecordName>
]
```

### 7. Test Import

```bash
mix resdayn.import_codex Morrowind.esm <RecordName>
```

## Domain Organization

### Assets Domain (`lib/resdayn/codex/assets/`)
- REGN → Region
- LTEX → LandTexture  
- STAT → StaticObject
- LIGH → Light
- ACTI → Activator

### Items Domain (`lib/resdayn/codex/items/`)
- ✓ MISC → MiscellaneousItem (COMPLETED)
- REPA → RepairItem
- APPA → AlchemyApparatus
- LOCK → Lockpick
- PROB → Probe
- ALCH → Potion

### Characters Domain (`lib/resdayn/codex/characters/`)
- BSGN → Birthsign
- BODY → BodyPart

## Record-Specific Implementation Notes

### REPA (Repair Items)
- Simple item structure similar to MISC
- Check parser for repair-specific fields (repair quality, uses)

### LOCK (Lockpicking Items)
- Simple item structure
- Check for lockpicking quality/level fields

### PROB (Probe Items)  
- Simple item structure
- Check for probe quality/uses fields

### APPA (Alchemy Apparatus)
- Item structure with alchemy-specific properties
- Check for apparatus type (mortar, alembic, etc.)

### ALCH (Potions)
- Item structure with effects
- May have magical effects similar to spells

### STAT (Static Objects)
- Basic asset with 3D model
- No interactive properties

### ACTI (Activators)
- Similar to STAT but with script capability
- Interactive world objects

### LIGH (Lights)
- Asset with light properties (radius, color, etc.)
- May reference scripts

### BSGN (Birth signs)
- Character-related
- May reference special abilities/spells

### BODY (Body Parts)
- Character system component
- Define body part types and properties

### REGN (Regions)
- World/environment data
- Weather patterns, sounds, map colors

### LTEX (Land Textures)
- Terrain system component
- Texture definitions for landscape

## Common Issues to Watch For

1. **Optional Fields**: Use `Map.take/2` to handle missing fields gracefully
2. **Field Name Mappings**: Parser field names may differ from resource field names
3. **Nested Data**: Some records have complex nested structures
4. **Enums/Constants**: Convert numeric codes to meaningful atom values
5. **References**: Validate foreign key relationships exist

## Testing Strategy

For each record:
1. Test single record import
2. Check record count makes sense
3. Verify data integrity in database
4. Test that no errors occur during import

## Success Metrics

- All records import without errors
- Record counts are reasonable (hundreds to thousands per type)
- Data appears correctly structured in database
- No foreign key constraint violations