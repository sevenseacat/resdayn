# Resdayn

An Elixir application for reading, parsing and formatting data from ESM data files from [The Elder Scrolls III: Morrowind](https://en.wikipedia.org/wiki/The_Elder_Scrolls_III:_Morrowind). This is everything you can see and edit by loading the ESM file in the Construction Set, but in code format.

This uses the amazing work of Dave Humphrey, who detailed the format of ESM files (and has also been running UESP for many years!): http://www.uesp.net/morrow/tech/mw_esm.txt

## Example usage

```elixir
iex> Resdayn.load("path/to/your/Morrowind.esm")
[
  %{
    flags: 0,
    subrecords: [
      {"HEDR",
       <<154, 153, 153, 63, 1, 0, 0, 0, 66, 101, 116, 104, 101, 115, 100, 97,
         32, 83, 111, 102, 116, 119, 111, 114, 107, 115, 0, 0, 0, 0, 0, 0, 0, 0,
         0, 0, 0, 0, 0, 0, 84, 104, 101, 32, ...>>}
    ],
    type: "TES3"
  },
  %{
    flags: 0,
    subrecords: [{"NAME", "sMonthMorningstar"}, {"STRV", "Morning Star"}],
    type: "GMST"
  },
  ...
]
```

## Data types parsed and verified

Most are interesting, some are not, but all will be ticked off, one at a time...

- [ ] `TES3` (Main header record)
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
