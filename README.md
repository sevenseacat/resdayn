# Resdayn

An Elixir application for reading, parsing and formatting data from ESM data files from [The Elder Scrolls III: Morrowind](https://en.wikipedia.org/wiki/The_Elder_Scrolls_III:_Morrowind). This is everything you can see and edit by loading the ESM file in the Construction Set, but in code format.

This uses the amazing work of Dave Humphrey, who detailed the format of ESM files (and has also been running UESP for many years!): http://www.uesp.net/morrow/tech/mw_esm.txt

## Example usage

```elixir
iex> Resdayn.load("path/to/your/Morrowind.esm")
[
  %{
    company: "Bethesda Softworks",
    dependencies: [],
    description: "The main data file For Morrowind",
    flags: %{blocked: false, persistent: false},
    record_count: 48295,
    type: :master,
    version: 1.2
  },
  ...
]
```

## Data types parsed and verified

Most are interesting, some are not, but all will be ticked off, one at a time...

- [x] `TES3` (Main header record)
- [ ] `GMST` (Game settings)
- [ ] `GLOB` (Global variables)
- [ ] `CLAS` (Class definitions)
- [ ] `FACT` (Faction definitions)
- [ ] `RACE` (Race definitions)
- [ ] `SOUN` (Sounds)
- [ ] `SKIL` (Skills)
- [ ] `MGEF` (Magic effects)
- [ ] `SCPT` (Scripts)
- [ ] `REGN` (Regions)
- [ ] `BSGN` (Birthsigns)
- [ ] `LTEX` (Land textures)
- [ ] `STAT` (Statics)
- [ ] `DOOR` (Door definitions)
- [ ] `MISC` (Misc items)
- [ ] `WEAP` (Weapons)
- [ ] `CONT` (Containers)
- [ ] `SPEL` (Spells)
- [ ] `CREA` (Creatures)
- [ ] `BODY` (Body parts!?)
- [ ] `LIGH` (Lights)
- [ ] `ENCH` (Enchanting effects)
- [ ] `NPC_` (NPCs)
- [ ] `ARMO` (Armour)
- [ ] `CLOT` (Clothing)
- [ ] `REPA` (Repair items)
- [ ] `ACTI` (Activators)
- [ ] `APPA` (Alchemy apparatus)
- [ ] `LOCK` (Lockpicking items)
- [ ] `PROB` (Probes)
- [ ] `INGR` (Ingredients)
- [ ] `BOOK` (Books)
- [ ] `ALCH` (Alchemy?)
- [ ] `LEVI` (Levelled items)
- [ ] `LEVC` (Levelled creatures)
- [ ] `CELL` (Cells)
- [ ] `LAND` (Landscape)
- [ ] `PGRD` (Path grid)
- [ ] `SNDG` (Sound generator)
- [ ] `DIAL` (Dialogue and journals)
- [ ] `INFO` (Records that belong to dialogues and journals)
