
# [Mattel Intellivision][https://en.wikipedia.org/wiki/Intellivision] for [MiSTer Platform](https://github.com/MiSTer-devel/Wiki_MiSTer/wiki)

## Presentation

Intellivision is a 1979 game console based on the General Instrument CP1610 16bits microprocessor.

This core features several extensions modules :
- Intellivoice : Voice synthesiser, supported by a few games.
- ECS : Keyboard + BASIC ROM + Additional sound chip.
- JLP : Cartridge emulator with extra features such as multiplication accelerator, FLASH save game sectors...


## BIOS
This core needs copies of original ROMs in the Intellivision folder

**Either use boot0..3.rom files**

Name      | Original   | Content
----------|------------|--------------------
boot0.rom | exec.bin   | System ROM (8kB)
boot1.rom | grom.bin   | Character generator ROM (2kB)
boot2.rom | sp0256-012.bin | Intellivoice ROM (2kB)
boot3.rom | ecs.bin    | ECS extension ROM (24kB)

**Or merge all 4 ROMs into a single boot.rom file**
```
cp exec.bin boot.rom
cat grom.bin >>boot.rom
cat sp0256-012.bin >>boot.rom
cat ecs.bin >>boot.rom
```

## Cartridges

Address decoding is partly done in the cartridges, there are many different ROM mappings. Some cartridges have additional RAM.

**This core supports several ROM formats :**

- Raw ROM. Automatically selects one of the standard mappings using CRCs. (Can be overriden with the MAP menu)

- Intellicart format. This format includes headers and attributes that defines cartridge ROM, or RAM areas. It is autodetected.

- Raw ROM + Configuration file. .CFG are text files that define ROM areas. They also support paged memory, RAM areas. (Select "FORMAT: CFG Mapping" menu)
