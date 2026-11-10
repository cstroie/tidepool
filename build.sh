#!/bin/sh
# Build TIDEPOOL: art.inc from art.txt (Node.js), then TIDEPOOL.COM with pasmo
# (apt install pasmo, or set PASMO=/path/to/pasmo).
# DEST=<dir> also copies the program there (DigitalRerun's shelf disk).
set -e
cd "$(dirname "$0")"
node mkart.js
${PASMO:-pasmo} tidepool.asm TIDEPOOL.COM
if [ -n "$DEST" ]; then cp TIDEPOOL.COM "$DEST"/; fi
ls -l TIDEPOOL.COM
