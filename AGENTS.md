# AGENTS.md

TIDEPOOL: a very slow idle game in Z80 assembly for CP/M 2.2 (80x24, VT100/VT52/ADM-3A).
Standalone project; DigitalRerun only ships the built `TIDEPOOL.COM`. Read `DESIGN.md` first.

- Build: `sh build.sh` (needs `node` and `pasmo`). `art.inc` is generated from `art.txt`: edit
  `art.txt`, never `art.inc`. `TIDEPOOL.COM` is not in git; releases carry it.
- Test: `ROOT=<digital-rerun checkout> node --test test/` (build first). The tests run the real
  program in DigitalRerun's emulator; `tools/screen.js` and `tools/visit.js` do the same by hand.
- Screen: 80 columns. Messages start at column 2, so keep any string in `text.asm` to 78
  characters or fewer, or it wraps onto the key bar.
- Strings live in `text.asm`, the screens in `ui.asm`, the pool's rules in `sim.asm`. Tests match
  on screen text, so change a string and its test together.
- Version: `VERSION` and `CHANGELOG.md`; tag releases `vX.Y.Z`.
- Commit messages: `feat:`, `fix:`, `docs:`, `release:`.
