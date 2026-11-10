'use strict';
/*
 * mkart.js: art.txt -> art.inc, the pictures as numbers (no quoting trouble, backslashes included).
 * Every picture is 8 columns wide; the rock has 3 rows, every other picture 5; the sequence is
 * fixed (rock, then 8 species x 4 stages), so the program finds a picture by arithmetic.
 */
const fs = require('node:fs');
const path = require('node:path');

const SPECIES = ['film', 'barnacles', 'kelp', 'mussels', 'anemone', 'star', 'crab', 'urchin'];

function parse(text) {
    const pics = [];
    let cur = null;
    text.split('\n').forEach((line, i) => {
        if (/^\s*(#|$)/.test(line)) return;
        const m = /^\|(.*)\|$/.exec(line);
        if (!m) { cur = { name: line.trim(), rows: [] }; pics.push(cur); return; }
        if (!cur) throw new Error(`art.txt:${i + 1}: a row before any name`);
        if (m[1].length !== 8) throw new Error(`art.txt:${i + 1}: ${cur.name} has a row of ${m[1].length} columns, not 8`);
        cur.rows.push(m[1]);
    });
    const want = ['rock'];
    for (const s of SPECIES) for (let k = 0; k < 4; k++) want.push(`${s} ${k}`);
    if (pics.map(p => p.name).join() !== want.join()) throw new Error('art.txt: the pictures are not in the fixed order');
    for (const p of pics) if (p.rows.length !== (p.name === 'rock' ? 3 : 5)) throw new Error(`art.txt: ${p.name} has ${p.rows.length} rows`);
    return pics;
}

function build(text) {
    const pics = parse(text);
    const out = ['; art.inc: made by mkart.js from art.txt. Do not edit.'];
    const emit = p => {
        out.push(`; ${p.name}`);
        for (const r of p.rows) out.push('        db      ' + [...r].map(c => c.charCodeAt(0)).join(','));
    };
    out.push('rockart:'); emit(pics[0]);
    out.push('art:');
    pics.slice(1).forEach(emit);
    return out.join('\n') + '\n';
}

module.exports = { parse, build };

if (require.main === module) {
    const dir = __dirname;
    fs.writeFileSync(path.join(dir, 'art.inc'), build(fs.readFileSync(path.join(dir, 'art.txt'), 'utf8')));
    console.log('art.inc written');
}
