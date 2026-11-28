# MSX (MSX1/MSX2/MSX2+/turbo R) pro [MiSTer Board](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

[English](Readme.md) | **Česky**

> [!CAUTION]
> **Upozornění (WIP)**: Toto jádro je ve vývoji (**Work in Progress**). Některé součásti jsou rozpracované a mohou obsahovat ladicí výstupy nebo experimentální funkce. Některé funkce zatím nemusí fungovat stoprocentně. Viz [Známá omezení](#známá-omezení).

## Přehled jádra
Jádro (na MiSTeru `MSX`, složka `games/MSX`) není přímou syntézou konkrétního počítače MSX. Poskytuje **dynamicky konfigurovatelné hardwarové prostředí**, které se za běhu sestaví z vybrané definice (*ROM PACK*). Každá definice stroje obsahuje nejen zapojení hardware, ale i příslušný **obsah ROM.** Jádro umí spustit:

- stroje **MSX1** (VDP řady TMS9918),
- stroje **MSX2** (Yamaha V9938, RTC, paměťový mapper),
- stroje **MSX2+** (Yamaha V9958 s barevnými režimy YJK a vodorovným posunem; Panasonic, Sanyo, Sony a CIEL Expert Turbo; ROM Kanji, MSX-MUSIC a turbo 5,37 / 7,16 MHz tam, kde je stroj má),
- **MSX turbo R** Panasonic FS-A1ST a FS-A1GT (V9958, S1990, režim R800 – jeho rychlost viz [Známá omezení](#známá-omezení)),
- **1chipMSX** (ve stylu OCM-PLD, třída MSX2+, V9958), který zavádí BIOS z obrazu SD karty.

Pro plnou funkci jádro potřebuje také **konfiguraci rozšiřujících modulů** (*FW PACK*) s dalšími ROM. Je **nezávislá na konkrétním modelu MSX** a umožňuje:
- více jazykových variant (lokalizované ROM),
- snadné budoucí rozšiřování o nový hardware.

Třetím konfiguračním souborem je **databáze ROM podle CRC32** (*DB MAPPERS*), která známým kontrolním součtům přiřazuje správný typ mapperu. Jádro tak pro každý načtený obraz ROM samo vybere vhodný mapper.

## Podporované modely MSX
**[Podporované modely MSX](ComputersModel.cs.md)** – 227 definic strojů od 36 výrobců:

| Generace | Strojů |
|---|---|
| MSX1 | 135 (124 s VDP TMS99xx, 11 s V9938 a BIOSem MSX1) |
| MSX2 | 80 |
| MSX2+ | 9 |
| MSX turbo R | 2 (Panasonic FS-A1ST, FS-A1GT) |
| 1chipMSX / OCM (třída MSX2+) | 1 |

Sedm strojů z openMSX zatím podporováno není: šest potřebuje hardware, který jádro nemá, Aucnet NIA-2001 jen nemá definici; jsou vypsané na konci seznamu modelů. Obrazy ROM strojů nejsou součástí tohoto repozitáře, viz [Začínáme](#začínáme).

## Začínáme
Jádro potřebuje **alespoň balíček stroje** (ROM PACK). Zbytek závisí na tom, co chcete spustit. Soubory dejte na SD kartu MiSTeru do `/media/fat/games/MSX/`:

| Soubor | Potřeba? | Poznámky |
|---|---|---|
| Balíček stroje `<model>.msx` | **Ano** | Bez něj nic neběží. Vytvoří se z ROM stroje pomocí `createComp.py`. Stroje C-BIOS (MSX, MSX2) a 1chipMSX lze vytvořit bez komerčních ROM, jejich ROM jsou součástí repozitáře. |
| FW balíček `CART_FW_EN.msx` nebo `CART_FW_JP.msx` | Pro **jakoukoli cartridge** | Potřeba pro každý typ cartridge, **včetně obyčejné ROM**. Obsahuje ROM cartridge (BIOS FM-PAC, `GM2.ROM`, `VY0010.ROM`, `mfrsd.ROM`, `yrw801.rom`, ...). Vytvoří se pomocí `createDev.py`. Balíčky EN a JP se liší jen ROM FM-PAC. Cartridge, jejíž ROM v balíčku chybí, se do něj nezahrne. |
| Databáze mapperů `vampier.db` | Volitelná | Potřeba pro ROM větší než 64 KB a pro ROM se speciálním mapperem. ROM do 64 KB běží bez ní jako obyčejná ROM. Hotový soubor: `tools/CreateCRC/vampier.db`. |
| Obrazy ROM `.ROM`, disků `.DSK`, pásek `.CAS` | Volitelné | `.DSK` musí být surový obraz 720K, 640K, 360K nebo 320K. |
| Obraz SD karty `.VHD` | 1chipMSX: ano | FAT16 **s tabulkou oddílů** a `OCM-BIOS.DAT` jako prvním souborem. Volitelný pro cartridge MegaFlashROM SCC+ SD. |

Balíčky pak načtěte v OSD (**Load ROM PACK**, **Load FW PACK**, **Load DB MAPPERS**). MiSTer si tyto tři soubory **pamatuje a při příštím startu jádra je načte automaticky**; ROM cartridge, disky a pásky si nepamatuje. Každé načtení znovu sestaví celý stroj.

Přechod z jádra pod dřívějším jménem `MSX1`: přesuňte `games/MSX1` do `games/MSX` a `saves/MSX1` do `saves/MSX` a tři balíčky načtěte ještě jednou. Nastavení v OSD začíná na výchozích hodnotách.

Jak balíčky a databázi vytvořit:
- [Přehled nástrojů](tools/README.cs.md)
- [CreateMSXpack – tvorba ROM PACK a FW PACK](tools/CreateMSXpack/README.cs.md)
- Pro vývojáře (formát XML stroje, přidávání zařízení): [DEVELOPERS.cs.md](tools/CreateMSXpack/DEVELOPERS.cs.md)

Stručně: nainstalujte **Python 3**, ROM dejte do adresáře `ROM` v `tools/CreateMSXpack` nebo jinou složku předejte volbou `--rom-dir` (soubory se hledají podle SHA1, na názvech nezáleží) a spusťte `python3 createComp.py` (stroje) a `python3 createDev.py` (cartridge); volby vypíše `--help`. Soubory `.msx` vzniknou v `MSX/`.

### Bez modulu SDRAM

Jádro běží i **bez přídavné desky SDRAM**, ale jen v menších sestavách. Uvnitř FPGA má 256 KB paměti. Tam se ukládá nejdřív vše, co stroj potřebuje: jeho ROM, jeho RAM a pak cartridge ve slotech A a B. Teprve to, co se nevejde, jde do SDRAM.

**Bez SDRAM funguje:**
- **189 z 227 strojů**: téměř všechny MSX1 a většina MSX2 s 64 nebo 128 KB RAM (např. Philips VG 8020, NMS 8245/8250, VG 8235, Sony HB-F1, HB-F9P).
- Cartridge, pokud se vejdou do zbytku z 256 KB. Zbývá asi **160 KB** u běžného MSX1 (64 KB RAM) a asi **64 KB** u běžného MSX2 (128 KB RAM). Cartridge zabere velikost své ROM a k tomu svou SRAM nebo RAM: FM-PAC 72 KB, Game Master 2 136 KB, SCC+ 128 KB.

**Potřebuje SDRAM:**
- Těchto 38 strojů (ROM s kanji, 256 KB RAM a víc nebo velký vestavěný software):
  - MSX1: National FS-4000, Sony HB-11, Al Alamiah AX230
  - MSX2: Daewoo CPC-400S, Hitachi MB-H70, Mitsubishi ML-G30 (oba modely), National FS-4500, FS-4600F, FS-4700F, FS-5000F2, FS-5500F1, FS-5500F2, Panasonic FS-A1F, Al Alamiah AX370, Sony HB-F700D/F/P/S, HB-F900, HB-G900AP, HB-T600, Yamaha AX350II, AX350IIF, AX500, YIS-805/256
  - MSX2+: Panasonic FS-A1FX, FS-A1WX, FS-A1WSX, Sanyo PHC-35J, PHC-70FD, PHC-70FD2, Sony HB-F1XDJ, HB-F1XV, CIEL Expert Turbo
  - MSX turbo R: Panasonic FS-A1ST, FS-A1GT; a 1chipMSX
- MoonSound, MegaFlashROM SCC+ SD, ASCII16-X, Konami Ultimate Collection, Yamanooto, MegaRAM a MegaSCC.
- Každá ROM cartridge větší než volné místo: většina her MegaROM na MSX2, ROM od 256 KB na jakémkoli stroji.

**Co se stane, když se to nevejde:** nahrávání skončí hlášením **SMALL MEMORY** v OSD a jádro zůstane v resetu. Nahrajte menší stroj nebo cartridge, nebo osaďte desku SDRAM. Velikost SDRAM jádro zná od menu jádra MiSTeru, které modul při startu zjišťuje. Spustí-li se jádro bez menu (neobvyklé), velikost nezná a nekontroluje. Konfigurace, která se nevejde, pak nad 256 KB čte nesmysly.

Se SDRAM stačí modul 32 MB. Největší stroj (1chipMSX) potřebuje asi 8 MB, MoonSound 4 MB, ASCII16-X, Konami Ultimate Collection i Yamanooto 8 MB. Nevešly by se jen dvě ROM po 16 MB (SMALL MEMORY).

## Funkce OSD

| Položka OSD | Poznámky |
|---|---|
| Load ROM PACK (`.MSX`) | Balíček stroje. Pamatuje se a načte se při startu jádra. |
| Load FW PACK (`.MSX`) | Balíček cartridge/rozšíření. Pamatuje se a načte se při startu jádra. |
| Load DB MAPPERS (`.DB`) | Databáze mapperů podle CRC32. Pamatuje se a načte se při startu jádra. Načtení stroj neresetuje, použije se až při dalším načtení ROM. |
| Mount Drive 1 / 2 (`.DSK`) | Zobrazuje se podle počtu mechanik stroje (nebo cartridge FDC). Dvě mechaniky jen u Philips NMS 8255. |
| Slot1 / Slot2 | Typ cartridge v slotu, viz [Rozšiřující cartridge](#podporované-rozšiřující-cartridge). Změna znovu načte konfiguraci. Na 1chipMSX se nezobrazuje, ten má vlastní volby. |
| Slot1 / Slot2 ROM Load (`.ROM`) | Zobrazuje se, je-li slot nastaven na ROM. Až 16 MB. |
| Load SD card (`.VHD`) | 1chipMSX (MegaSD) nebo MegaFlashROM SCC+ SD ve slotu 1. |
| Tape Input | File nebo ADC (analogový vstup MiSTeru). Na 1chipMSX se nezobrazuje. |
| Tape Monitor | On (výchozí) / Off: signál z pásky je slyšet ve zvuku, dokud běží motor. Na 1chipMSX se nezobrazuje. |
| Cas File (`.CAS`) | Obraz pásky, zobrazuje se při Tape Input = File. |
| Tape Rewind | Přetočí obraz pásky na začátek. |
| Firmware switch | Off / On, jen u strojů, které přepínač mají: turbo R a stroje Panasonic, National a Sanyo se zařízením Matsushita (switched I/O). |
| R800 speed | Real (rychlost skutečného R800) / T-states (počty taktů Z80, jeden na takt 21,5 MHz) / 10.7MHz (počty taktů Z80 na 10,7 MHz). Zobrazuje se s přepínačem firmwaru, používá ho turbo R; projeví se při příštím zapnutí R800. |
| Mouse | Port 1 (výchozí) / Port 2: joystickový port, který myš PS/2 převezme, když se pohne; joystick na tom portu ho vrátí. |
| MIDI | **User Port**: MT32-pi (výchozí; [MT32-pi](https://github.com/dwhinham/mt32-pi) nebo jen MIDI OUT na pinu 1), MIDI In/Out (adaptér MIDI: OUT na pinu 1, IN na pinu 0), Off. Jakmile se MT32-pi najde, objeví se jeho volby: Use MT32-pi, Show Info (No / Yes: zpráva při změně jeho režimu / LCD-On / LCD-Auto: jeho displej v levém horním rohu obrazu, stále nebo 3 s po změně), výchozí Synth (Munt, FluidSynth), Munt ROM, SoundFont a Reset Hanging Notes. |
| Video | Poměr stran, scandoubler (None, HQ2x, CRT 25/50/75 %), Vertical Crop, Scale (Normal, V-Integer, Narrower/Wider HV-Integer, HV-Integer), Border (platí pro VDP TMS i V99xx). |
| Pause when OSD open | No (výchozí) / Yes: stroj stojí, dokud je OSD otevřené (CPU drženo, zvuk ztlumený, obraz na HDMI zamrzne). |
| Reset | Reset stroje. |
| Reset & Detach ROM Cartridge | Vyprázdní ROM cartridge v obou slotech a znovu načte. Na 1chipMSX se nezobrazuje. |
| Reset and close OSD | Reset a zavření menu. |
| SRAM Save / SRAM Load | Zobrazují se, má-li cartridge SRAM, ale **nic nedělají** (viz [Známá omezení](#známá-omezení)). |

1chipMSX má navíc blok: CPU speed (Normal / Turbo, přepíná F11), CPU type (Z80 / R800 – jen násobicí instrukce R800), Slot1, Slot2, Internal Mapper (2048 / 4096 KB), Joysticks Swap, Reset after Mount.

### Chybová hlášení OSD
Když načtení selže, informační řádek OSD zobrazí jedno z těchto hlášení. Po kterémkoli z nich se stroj nespustí: jádro zůstane v resetu do dalšího načtení (nový pack, ROM nebo volba cartridge).

| Hlášení | Význam |
|---|---|
| BAD MSX CONF | Soubor načtený jako ROM PACK není balíčkem stroje. |
| NOT SUPPORTED CONF | Balíček obsahuje neznámý záznam – verze balíčku a jádra si neodpovídají. |
| NOT SUPPORTED BLOCK | Balíček obsahuje neznámý typ bloku – verze balíčku a jádra si neodpovídají. |
| BAD MSX FW CONF | Soubor načtený jako FW PACK není FW balíčkem. |
| NOT FW CONF | FW balíček není načten, ale vybraná cartridge jej potřebuje (každý typ cartridge včetně obyčejné ROM), nebo v FW balíčku chybí ROM, kterou cartridge potřebuje (např. `yrw801.rom` pro MoonSound). |
| DEVICE MISSING | Konfigurace potřebuje víc kopií zařízení, než jádro obsahuje, např. FM-PAC v obou slotech na stroji s MSX-MUSIC, MoonSound v obou slotech. |
| Device not in this core build | Cartridge FDC ve slotu 2 nebo pozice FDC, kterou tento build jádra nemá. |
| No CRC32 DB | ROM větší než 64 KB potřebuje mapper, ale databáze mapperů není načtena. |
| Not find CRC32 in DB | ROM větší než 64 KB není v databázi mapperů. |
| FDC already in machine | Dva FDC na stejné pozici – chyba definice stroje. |
| SMALL MEMORY | Stroj s cartridgemi potřebuje víc paměti, než je k dispozici: bez modulu SDRAM víc než 256 KB (viz [Bez modulu SDRAM](#bez-modulu-sdram)), s modulem 32 nebo 64 MB víc než jeho velikost. |
| ROM too big | Soubor ROM je větší než 16 MB. |

## Podporované hardwarové součásti
Jádro obsahuje tyto hardwarové moduly:
- `PPI` – [Programmable Peripheral Interface](https://www.msx.org/wiki/Programmable_Peripheral_Interface)
- `RTC` – [hodiny reálného času Ricoh RP-5C01](https://www.msx.org/wiki/Ricoh_RP-5C01) (čas se bere z MiSTeru; obsah CMOS se neukládá)
- `PSG` – [generátor zvuku AY-3-8910 / YM2149](https://www.msx.org/wiki/General_Instrument_AY-3-8910)
- `VDP` – [grafický procesor řady TMS](https://www.msx.org/wiki/Texas_Instruments_TMS9918), PAL nebo NTSC podle definice stroje
- `VDP` – Yamaha [V9938](https://www.msx.org/wiki/Yamaha_V9938) / [V9958](https://www.msx.org/wiki/Yamaha_V9958), 128 KB VRAM
- `CPU` – [Z80](https://www.msx.org/wiki/Z80) na 3,58 MHz s čekacím stavem MSX v každém výběru operačního kódu; chování NMOS nebo CMOS podle [MSX-Engine](https://www.msx.org/wiki/MSX-Engine) stroje (T9769 i s čekacím stavem na portech VDP); turbo 5,37 MHz u Panasonic FS-A1FX, FS-A1WX a FS-A1WSX, turbo 7,16 MHz u CIEL Expert Turbo; režim R800 u turbo R, viz [Známá omezení](#známá-omezení)
- `MEM_MAPPER` – paměťový mapper MSX2
- `KANJI` – [Kanji ROM](https://www.msx.org/wiki/Kanji_ROM) (úrovně 1 a 2; varianty pro hangul)
- `FDD` – emulace disketové mechaniky nad surovými obrazy `.DSK` (720K, 640K, 360K, 320K; podporována výměna disku)
- `WD2793` – [řadič disket](https://www.msx.org/wiki/Western_Digital_WD2793), čtení i zápis včetně Write Track (formátování); obraz chráněný proti zápisu zápisy ignoruje
- `TC8566AF` – řadič disket Toshiba v Panasonic FS-A1F a FS-A1ST, čtení i zápis
- `OPLL` – [YM2413](https://www.msx.org/wiki/Yamaha_YM2413), [MSX-MUSIC](https://www.msx.org/wiki/MSX-MUSIC) / [FM-PAC](https://www.msx.org/wiki/FM-PAC)
- `OPM` – [YM2151](https://www.msx.org/wiki/Yamaha_YM2151) (SFG-01) a YM2164 (SFG-05), vestavěný ve strojích Yamaha CX5M/CX11 a CX5MII/CX7M/AX200
- `SCC` – [Konami SCC](https://www.msx.org/wiki/Konami_SCC)
- `SCC+` – [Konami 052539 Enhanced SCC](https://www.msx.org/wiki/Konami_052539)
- `OPL4` – [Yamaha YMF278B](https://www.msx.org/wiki/MoonSound) (MoonSound: FM OPL3 a 24kanálová vlnová syntéza)
- `DAC` – 8bitový DAC Konami Synthesizer a Konami Ultimate Collection
- `YM2148` – rozhraní MIDI modulů Yamaha SFG, MIDI IN i MIDI OUT přes UART MiSTeru nebo uživatelský port
- `MSX_MIDI` – [MSX-MIDI](https://www.msx.org/wiki/MSX-MIDI) (UART i8251 + časovač i8254, I/O porty E8h–EFh), MIDI IN i MIDI OUT přes UART MiSTeru nebo uživatelský port
- `SFG01` – [Yamaha SFG-01](https://www.msx.org/wiki/Yamaha_SFG-01)
- `SFG05` – [Yamaha SFG-05](https://www.msx.org/wiki/Yamaha_SFG-05)
- Matsushita switched I/O (MSX2 / MSX2+ Panasonic, National a Sanyo): přepínač turba, přepínač firmware, 2 KB SRAM firmwaru
- S1985 MSX-Engine switched I/O: 16 bajtů zálohované paměti, registr barvy / vzoru
- CIEL Expert Turbo: přepínač turba
- turbo R: řadič systému `S1990` (přepínání Z80/R800 a ROM/DRAM, přepínač firmware), PCM, klávesa Pause s LED, systémový časovač; viz [MSX turbo R](https://www.msx.org/wiki/MSX_turbo_R)
- [1chipMSX](https://www.msx.org/wiki/1chipMSX): IPL ROM, přepínané I/O porty 40-4F, ESE-RAM, MegaSD s SD kartou (VHD), turbo 3,58 / 5,37 / 10,74 MHz

Neimplementováno: MSX-AUDIO, V9990 / GFX9000, tiskárna, pádla, světelná pistole, RS-232.

## Podporované ROM mappery
ROM cartridge se k mapperu přiřazují podle databáze CRC32 (`vampier.db`, vytvořená nástrojem [tools/CreateCRC](tools/CreateCRC/README.cs.md) z dumpu [romdb.vampier.net](https://romdb.vampier.net/)). ROM, které v databázi nejsou a mají do 64 KB, se umístí jako obyčejná ROM (první řádky tabulky).

| Mapper (název v DB) | Popis |
|---|---|
| obyčejná ROM (`0x0000`, `0x4000`, `0x8000`, `Page12`, `Page2`, `Normal`) | ROM umístěná na dané adrese; také záloha bez databáze |
| zrcadlená ROM (`Mirrored`, `Mirrored0000`, `Mirrored4000`, `Mirrored8000`) | obyčejná ROM zrcadlená přes adresní prostor; počáteční adresa `Mirrored` se určí z hlavičky ROM |
| `16kb`, `8kB` | obecné přepínání bank 16 KB a obecné 8 KB |
| `Konami` | standardní mapper Konami (banky 8 KB) |
| `KonamiSCC` | mapper Konami se zvukem SCC |
| `ASCII8` | mapper ASCII 8 KB |
| `ASCII8SRAM2`, `ASCII8SRAM8` | mapper ASCII 8 KB se 2 / 8 KB SRAM |
| `ASCII16` | mapper ASCII 16 KB |
| `ASCII16SRAM2`, `ASCII16SRAM8` | mapper ASCII 16 KB se 2 / 8 KB SRAM |
| `ASCII16-X` | mapper [ASCII16-X](https://www.grauw.nl/projects/ascii-x/ascii16-x/) s 8 MB flash ROM (změny se neukládají) |
| `KonamiUltimateCollection` | Konami Ultimate Collection: mapper Konami a Konami SCC s registrem offsetu, SCC/SCC+ a DAC na 8 MB flash ROM (změny se neukládají) |
| `YAMANOOTO` | Yamanooto (Konami Neo-Ultimate Collection): mapper Konami SCC a Konami4 s registrem offsetu, SCC/SCC+ a druhým PSG na portech 10h–11h na 8 MB flash ROM (změny se neukládají) |
| `NEO-8`, `NEO-16` | mappery NEO-8 (šest bank 8 KB) a NEO-16 (tři banky 16 KB) s 12bitovým číslem banky, ROM do 16 MB |
| `R-Type` | mapper R-Type |
| `Wizardry` | Wizardry (varianta ASCII 8 KB s SRAM) |
| `KoeiSRAM32` | hry KOEI s 32 KB SRAM |
| `GameMaster2` | ROM Konami Game Master 2 s 8 KB SRAM |
| `CrossBlaim` | mapper specifický pro Cross Blaim |
| `HarryFox` | mapper specifický pro Harry Fox |
| `Zemina80in1` | mapper multicartridge Zemina 80-in-1 |
| `Zemina90in1` | mapper multicartridge Zemina 90-in-1 (používá port 77h) |
| `SuperSwangi`, `MSXWrite` | speciální varianty ASCII 16 KB |
| `Synthesizer` | obyčejná ROM s DAC Konami Synthesizer |
| `MSXDOS2` | cartridge MSX-DOS2: banka 16 KB v 4000-7FFF přepínaná na 6000h. Online databáze ROM MSX-DOS2 nemá: CRC32 ROM doplňte do [tools/CreateCRC/mappersOverride.txt](tools/CreateCRC/mappersOverride.txt) a databázi znovu sestavte. MSX-DOS 2.20 upravený pro mapper ASCII8 tam už je. Potřebuje disketovou mechaniku: počítač s řadičem, nebo FDC cartridge ve slotu 1 a MSX-DOS2 ve slotu 2 |

Typy ROM z databáze, pro které jádro nemá konfiguraci, se do `vampier.db` nezapisují (např. MatraCompilation, Namco, Manbow2, cartridge Halnote). Taková ROM do 64 KB poběží jako obyčejná ROM, větší skončí hláškou *Not find CRC32 in DB*. Úplný seznam s počty je v [tools/CreateCRC/report.md](tools/CreateCRC/report.md). Nepodporován je také MU-PACK.

Mappery uvnitř stroje (National FS-4600F, Yamaha SFG, Panasonic turbo R, firmwarový mapper Halnote u Sony HB-F1XDJ / HB-F1XV, paměťový mapper, ESE RAM) vycházejí z definice stroje a nelze je volit.

## Podporované rozšiřující cartridge
OSD nabízí v **Slot1** a **Slot2** tyto typy:

| Typ | Sloty | Požadavky / poznámky |
|---|---|---|
| ROM | 1, 2 | ROM se načte položkou pod slotem. Mapper z databáze, nebo obyčejná ROM. Vyžaduje FW balíček. |
| Empty | 1, 2 | |
| FDC | jen 1 | Disketové rozhraní Philips VY-0010 (WD2793, 1 mechanika); potřebuje `VY0010.ROM` v FW balíčku. **Jen na stroji bez vlastního FDC** – má-li stroj vlastní FDC, cartridge se vynechá a použije se FDC stroje. |
| SCC | 1, 2 | Zvuková cartridge Konami SCC |
| SCC+ | 1, 2 | [Konami Sound Cartridge](https://www.msx.org/wiki/Konami_Sound_Cartridge) s SCC+ a 128 KB RAM (Snatcher, SD Snatcher) |
| FM-PAC | 1, 2 | Potřebuje BIOS FM-PAC v FW balíčku; 8 KB SRAM (neukládá se). Na stroji, který už MSX-MUSIC má, se vejde jen jeden FM-PAC. |
| MegaSCC+ 1MB | jen 1 | ESE MegaSCC+ |
| MegaSCC+ 2MB | jen 2 | ESE MegaSCC+ |
| MegaRAM ASCII-8K 1MB | jen 2 | ESE [MegaRAM](https://www.msx.org/wiki/MegaRAM) |
| MegaRAM ASCII-16K 2MB | jen 2 | ESE MegaRAM |
| MegaFlashROM SCC+ SD | jen 1 | [MegaFlashROM SCC+ SD](https://www.msx.org/wiki/MegaFlashROM_SCC%2B_SD); potřebuje `mfrsd.ROM` (obraz 8 MB) v FW balíčku; SD karta přes **Load SD card** (VHD); zápisy do flash se neukládají |
| Game Master 2 | jen 1 | [Konami Game Master 2](https://www.msx.org/wiki/Konami_Game_Master_2); potřebuje `GM2.ROM` v FW balíčku; 8 KB SRAM (neukládá se) |
| MoonSound | 1, 2 | [MoonSound](https://www.msx.org/wiki/MoonSound) (OPL4); potřebuje `yrw801.rom` v FW balíčku; jen jeden MoonSound najednou; 4 MB SDRAM; na 1chipMSX není k dispozici |
| MSX-MIDI | 1, 2 | Rozhraní MSX-MIDI bez ROM (jako MIDI Interface 3), I/O porty E8h–EFh; slot sám zůstává prázdný; jen jedno najednou; na 1chipMSX není k dispozici |

1chipMSX má vlastní volby Slot1 (Empty, MegaSCC+ 1MB) a Slot2 (Empty, MegaSCC+ 2MB, MegaRAM 1MB / 2MB) a do slotů nelze načítat ROM.

## Podpora platformy MiSTerFPGA
Jádro se integruje s MiSTerFPGA a podporuje tyto funkce platformy:
- `Joystick` – dva joystickové porty MSX (čtyři směry a dvě tlačítka, v mapování tlačítek MiSTeru pojmenovaná Fire 1 / Fire 2) z prvních dvou joysticků MiSTeru; volba prohození joysticků existuje jen na 1chipMSX
- `Klávesnice` – klávesnice PS/2, maticové rozložení pro každý stroj (`kbd_layout` v definici stroje, generuje [CreateKeyMap](tools/CreateKeyMap/README.cs.md)); klávesa Pause pozastaví stroj (CPU drženo, zvuk ztlumený, obraz na HDMI zamrzne; u turbo R ji jako na skutečném stroji čte BIOS z portu A7h), F11 = turbo na 1chipMSX
- `Myš` – myš PS/2 jako myš MSX na všech strojích, v joystickovém portu 1 nebo 2 (OSD **Mouse**); port převezme, když se pohne, joystick na tom portu ho vrátí
- `Kazeta` – přehrávání souborů `.CAS` (musí být zapnutý motor MSX) nebo skutečná páska přes analogový vstup MiSTeru (ADC); páska je slyšet. Výstup na pásku neexistuje.
- `MIDI` – MIDI IN i MIDI OUT u YM2148 (stroje Yamaha) a MSX-MIDI, dvěma cestami:
  - UART MiSTeru v režimu MIDI (31250 Bd): MidiLink posílá MIDI OUT do USB MIDI zařízení nebo softwarového syntezátoru (MUNT, FluidSynth) a přivádí MIDI IN z USB MIDI zařízení
  - uživatelský port: [MT32-pi](https://github.com/dwhinham/mt32-pi) (MIDI OUT; jeho zvuk se přimíchá do zvukového výstupu a jeho displej lze zobrazit přes obraz) nebo adaptér MIDI (MIDI OUT na pinu 1, MIDI IN na pinu 0)

  MIDI IN se bere z uživatelského portu, je-li nastaven na MIDI In/Out, jinak z UART. MIDI OUT jde na obojí; jen když hraje MT32-pi a UART je v režimu MIDI, MidiLink nedostává nic, aby hudba nezněla dvakrát
- `Video` – nativní časování MSX, PAL/NTSC podle definice stroje (TMS) nebo softwarově (V99xx), volby škálování a scandoubleru
- `LED` – aktivita SD/VHD, pauza (stroj pozastavený nebo LED pause u turbo R), LED turbo (R800 u turbo R, turbo u MSX2+ Panasonic a u CIEL Expert Turbo)
- `Podpora SDRAM` – volitelná; potřebují ji větší stroje a cartridge, viz [Bez modulu SDRAM](#bez-modulu-sdram)

## Známá omezení
- **Nic se neukládá trvale:** SRAM cartridge (FM-PAC, Game Master 2, KOEI, ASCII se SRAM), zápisy do flash (MegaFlashROM, ASCII16-X, Konami Ultimate Collection, Yamanooto), SRAM strojů (SRAM mapperů Panasonic a National, SRAM zařízení Matsushita a S1985) a CMOS RTC začínají při každém načtení s hodnotou FFh. Položky **SRAM Save / SRAM Load** nic nedělají.
- **Disky:** jen surové obrazy `.DSK` (720K, 640K, 360K, 320K); žádné 40stopé, 1,44 MB, XSA, D88, HFE ani DMK. Cartridge FDC funguje jen ve slotu 1 a jen na strojích bez FDC; cartridge s TC8566AF neexistuje.
- **Páska:** jen přehrávání, žádné ukládání.
- **R800:** R800 u turbo R běží rychlostí skutečného čipu (zlom stránky, vnitřní ROM a externí sloty, I/O, násobení, refresh DRAM a odstup přístupů k VDP jako v openMSX). Kód, který pracuje jen v registrech, je o 7 až 26 % pomalejší než na skutečném R800. Nedokumentované chování (bity příznaků 3 a 5, SLL, DD / FD před běžnou instrukcí) má jako Z80. Chybí mikrofon turbo R.
- **ROM:** ROM nad 64 KB potřebuje záznam v databázi, mapper se z hlavičky ROM nerozpoznává.
- **V99x8:** chybí sprity v overscanu a okno FH v textových režimech. Nastavení rychlosti VDP a hlasitosti na 1chipMSX se ukládají bez účinku.
- **1chipMSX:** bez MoonSound, bez zvláštních kláves PrintScreen/ScrollLock (Pause je obecná pauza stroje).
- **Pauza:** stojí jen CPU; kazeta (CAS) a řadiče disket běží dál, takže pauza během nahrávání může skončit chybou čtení.
- Žádná hlasitost ani ztlumení po zdrojích v OSD, žádné V9990.

## Poděkování
Velký dík patří komunitě MSX na Discordu za testování na skutečném hardware, hlášení chyb a rady;
bez ní by toto jádro zdaleka nefungovalo tak dobře. Zvláštní poděkování:
- **Vampier** – za databázi ROM [romdb.vampier.net](https://romdb.vampier.net/), ze které vzniká
  databáze mapperů `vampier.db`, a za testování a rady.
- **wark91** – za testování a rady.

Projekty, na kterých jádro staví nebo podle kterých bylo ověřováno:
- [MSX_MiSTer](https://github.com/MiSTer-devel/MSX_MiSTer) od Sorgeliga – port OCM-PLD od KdL na MiSTer a inspirace pro toto jádro. Stroj 1chipMSX byl převeden z něj: IPL ROM, systémové I/O porty a řízení rychlosti CPU, ESE-RAM s MegaSD, MegaSCC/MegaRAM a myš PS/2.
- [OCM-PLD](https://github.com/gnogni/ocm-pld-dev) od KdL a ESE Artists' Factory (Kazuhiro Tsujikawa) s ESE-VDP od Kunihiko Ohnaky – původ CPU T80 (přepsaného do SystemVerilogu), VDP V99x8, SCC a kódu MegaSD/MegaRAM.
- [muhanpong/MSX1_MiSTer](https://github.com/muhanpong/MSX1_MiSTer) (větev `nextz80_v9990`) – fork tohoto jádra. Jeho analýzy chyb a hlášení ze skutečného hardware upozornily na chyby v emulaci flash a na úskalí mapperu ASCII16-X a MoonSound. Žádný kód z něj nebyl převzat; zdejší implementace jsou nezávislé.
- [openMSX](https://openmsx.org/) – reference pro chování mapperu ASCII16-X a jeho flash čipu, cartridge Konami Ultimate Collection a Yamanooto, mapperů NEO-8 a NEO-16, vlnové části OPL4 (YMF278B), sběrnicového rozhraní a časovačů a časování V99x8.
- [Grauw](https://www.grauw.nl/projects/ascii-x/ascii16-x/) – specifikace mapperu ASCII16-X.
- [Nuked OPL3](https://github.com/nukeykt/Nuked-OPL3) od Nuke.YKT – model OPL3, proti kterému se FM část MoonSound kontroluje vzorek po vzorku. Jeho zdroj (LGPL-2.1-or-later) používá pouze test (`rtl/peripheral/SOUND/opl4/tb/nuked`).

## Licence
Toto jádro je licencováno pod GNU General Public License, verze 3 nebo novější
(viz `LICENSE`, `SPDX-License-Identifier: GPL-3.0-or-later` v hlavičkách zdrojů).
Části převzaté z jiných projektů si ponechávají vlastní licence, jak je uvedeno v hlavičkách jejich souborů
(např. framework MiSTer v `sys/`, moduly FDC z X68000_MiSTer pod GPL-3.0,
soubory odvozené z ESE / OCM-PLD, jádra CPU T80 / TV80 a VDP).
