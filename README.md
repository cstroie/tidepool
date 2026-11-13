# Tidepool (TIDEPOOL)

A very slow garden you can't control, written in **Z80 assembly** for **CP/M 2.2**. 4 MHz, 80x24,
VT100 (line drawing, dim, bold, blink, reverse) / VT52 / ADM-3A. No hurry, nothing to win.

![Tidepool: forty days on, a sea star among the mussels on a rock with a cairn](docs/screenshot.png)

Ten rocks and a tide table. Things settle and grow while the tide is in, and the only thing you decide
is what not to disturb. It is an idle game built around the real-time clock: the pool keeps the time
of the machine, so come back after a week away, fourteen tides later, and something will have settled,
grown, been eaten or torn away.

- Ten rocks with names you can change. Algae, barnacles, kelp, mussels, anemones and sea stars settle
  on them; hermit crabs and urchins only pass through.
- Five cairn stones. A rock with a cairn is left alone; when you go, you wade out across the rocks
  that have none, and what lives there is stepped on and starts smaller.
- The rare things (anemones, sea stars) only come to rocks that stay quiet for days. Visit often and
  the common species crowd them out.
- A sun and a moon across the sky, a tide curve, a bell when a tide turns, and four seasons that set the
  pace by the real date.
- A tide table, a journal of what the pool did, names for your rocks, and a save file.

## Playing

You need a CP/M 2.2 machine (or an emulator) with a VT100, VT52 or ADM-3A console. Take `TIDEPOOL.COM`
from the [releases](https://github.com/cstroie/tidepool/releases) and copy it onto a disk, then run:

```
A>TIDEPOOL          asks for your terminal the first time
A>TIDEPOOL /100     VT100        /52   VT52        /ADM   ADM-3A
```

The pool is saved in `TIDEPOOL.SAV` next to the program; `R` starts a new one. A real-time clock on
port 20 gives the date and time; without one every visit is a single tide. It sits on the shelf of
[DigitalRerun](https://github.com/cstroie/digital-rerun), a CP/M computer in the browser: *Games*,
*Tidepool*, *Insert*, then type `PLAY`.

### Keys

The bottom line of the screen always shows the keys that work just then.

| Key | |
|---|---|
| `1`-`0` | pick a rock |
| `SPACE` | put a cairn on it, or lift it |
| `N` | name the rock |
| `T` `J` | the tide table; the journal |
| `B` | the bell on and off |
| `R` `?` `Q` | a new pool (asks first); help; quit (the pool carries on without you) |

### How it goes

A tide takes 12 hours 25 minutes. While you are away the tides go on, and the next time you start the
pool is brought up to date tide by tide (at most 2000 of them, nearly three years) and TIDEPOOL tells
you what happened. Winter halves the growth and brings storms; spring is when things settle eagerly;
summer is a quarter faster and calm; autumn brings the storms back. There is nothing to win: choose,
then give it time.

The full player's text is in [`docs/PLAYING.txt`](docs/PLAYING.txt). I will not spoil the rest.

## Building

You need [pasmo](https://pasmo.speccy.org/) (`apt install pasmo`) and Node.js.

```
sh build.sh                  art.inc from art.txt (mkart.js), then TIDEPOOL.COM (pasmo)
PASMO=/path/to/pasmo sh build.sh
DEST=/some/disk/dir sh build.sh      also copy the program there
```

The pictures are in `art.txt` (eight columns, a fixed order; `mkart.js` checks them and writes
`art.inc`). `TIDEPOOL.COM` is not kept in git: the releases carry it.
The version is in [VERSION](VERSION), the history in [CHANGELOG.md](CHANGELOG.md).

## Source

| File | Role |
|------|------|
| `tidepool.asm` | start, key dispatch, the live clock, catching up, a new pool, leaving, memory map |
| `clock.asm`, `term.asm` | the clock device and 32-bit arithmetic, the tide; the terminal driver |
| `sim.asm` | one tide, the species rules, the journal ring, trampling |
| `ui.asm`, `text.asm` | every screen: header, pool, strip, pane, tide table, journal, welcome-back; the words |
| `save.asm` | `TIDEPOOL.SAV`: three records straight from the state |
| `art.txt`, `mkart.js` | the pictures, and their checker and packer |

[`DESIGN.md`](DESIGN.md) is the design document: the time, the tide, the rules and the formats.

## Testing

```
ROOT=/path/to/digital-rerun node --test test/*.test.js     (build first)
```

The art tests need nothing else. The game tests play the real program in the emulator of a
[DigitalRerun](https://github.com/cstroie/digital-rerun) checkout (default: a `digital-rerun` folder
next to this one): a first visit, a cairn, leaving, a week away, a very long absence, seasons, the bell.
`tools/visit.js` gives a machine with a clock you set, and `tools/screen.js` runs the program and prints
the screen.

## Licence

MIT, see [LICENSE](LICENSE). Copyright (c) 2026 Costin Stroie. Tidepool is a separate project from
DigitalRerun: DigitalRerun only ships the built `TIDEPOOL.COM`, under this same licence, and its own
licence terms do not apply to it.
