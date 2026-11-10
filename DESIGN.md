# Tidepool (TIDEPOOL)

An idle game on the clock. Z80 assembly, CP/M 2.2, 4 MHz, 80x24, one `.COM` and one save file.

## Files

| File | Role |
|------|------|
| `tidepool.asm` | start, key dispatch, the live clock (`poll`), `catchup`, a new pool, leaving, memory map |
| `clock.asm` | the clock device, 32-bit `mul32`/`div32`, the tide (`level`, `evnext`), `delay` |
| `sim.asm` | one tide (`simtide`), the species rules, the journal ring, `trample` |
| `ui.asm` | every screen: header, pool, strip, pane, tide table, journal, welcome-back, name entry |
| `term.asm` | terminal driver, console, decimal, random, `/100 /52 /ADM` (Signal Seeker, Cold Storage) |
| `save.asm` | `TIDEPOOL.SAV`: two records straight from `state` |
| `text.asm` | the words |
| `art.txt`, `mkart.js` | the pictures (checked: 8 columns, fixed order) and `art.inc` |
| `tools/visit.js` | a DigitalRerun machine with a clock you set, for tests; `tools/screen.js` runs and prints |

## Time

DigitalRerun's clock (OUT 20 latches, 15 INs read: days since 31 Dec 1977, BCD hour/minute) gives
`M`, minutes since that day. A tide is 745 minutes: `cnow = M / 745`, `pnow = M mod 745` (0 high
water, 372 low). The save keeps `st_last` (the last tide simulated) and `st_seen` (the `M` of the
last visit). On start `catchup` runs `simtide` for every tide in between (capped at `CAP` = 2000)
and the journal records what happened; `welcome` lists the entries newer than `oldlast`. While
the program runs `poll` reads the clock about ten times a second and does the same for each new
tide, redraws when the minute, the water level or the sun moves, and moves the waves. `cnow` is
16 bits: 2070. Without a clock device one visit is one tide.

## The pool

A rock is four bytes: species, growth (a picture per 64), calm (tides since stepped on), cairn.
`simtide` rolls a storm (about 3.5%), then each rock: calm counts up; a storm tears barnacles,
kelp and mussels; then the species' rule: bare rock gets a film (or a crab), a film that has
grown settles barnacles, kelp or mussels, the settled grow and eventually let go (leaving a film),
a quiet barnacle rock opens an anemone (calm >= 24), quiet grown mussels meet a sea star (calm
>= 16), grown kelp meets an urchin, visitors leave. `trample` runs when you leave: rocks without
a cairn lose a quarter of their growth and a bit more (a film is only reset), visitors go, calm
returns to zero. Rare things need calm, and calm needs cairns: that is the whole decision.

## Journal

16 entries of 4 bytes: tide (word), rock (255 = the pool), event<<4 | species. `jprint` formats
with `%s` (species), `%S` (capitalised), `%r` (the rock's name), so a rename rewrites history.

## Screen

Rows 1-3 header, 4-15 the pool (12 rows composed in `scn`, drawn row by row: air bold, surface
waves, below it creatures plain and water dim), 16-18 strip, 19-22 pane in a VT100 line-drawing
frame (`gfxon`, `gc` with ASCII stand-ins), 23 latest, 24 keys. Nothing is written at column 80
of row 24. `art.inc` has the rock (3 rows) then 8 species x 4 sizes of 5 rows, 8 columns; a space
is transparent, so the water shows through a sprite.

## Rules of thumb

- `putc` keeps every register; `gc` spends `C`; `pdec` and `setattr` spend `B`, `C`, `DE`
  (`attrset` keeps them); `rnd` returns 8 bits in `A` and keeps `HL`.
- `jr` runs out of range over the main loop: use `jp` there.
- `LOW`, `HIGH` and friends are pasmo keywords: do not name an `equ` after one.
