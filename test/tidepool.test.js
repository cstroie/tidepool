'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { parse, build } = require('../mkart.js');

const APP = path.join(__dirname, '..');
const ROOT = process.env.ROOT || path.join(APP, '..', 'digital-rerun');
const haveRoot = fs.existsSync(path.join(ROOT, 'js/machine.js'));

test('art.inc is what art.txt builds to, and art.txt has the fixed 1 + 8 x 4 pictures', () => {
    const txt = fs.readFileSync(path.join(APP, 'art.txt'), 'utf8');
    assert.equal(parse(txt).length, 33);
    assert.equal(fs.readFileSync(path.join(APP, 'art.inc'), 'utf8'), build(txt));
});

test('mkart refuses a row of the wrong width, a missing row and a picture out of order', () => {
    const txt = fs.readFileSync(path.join(APP, 'art.txt'), 'utf8');
    assert.throws(() => parse(txt.replace('|  .--.  |', '|  .--.   |')), /not 8/);
    assert.throws(() => parse(txt.replace('|  .--.  |\n', '')), /rock has 2 rows/);
    assert.throws(() => parse(txt.replace('film 0', 'kelp 0')), /fixed order/);
});

// ---- the game itself, in DigitalRerun's emulator (needs the checkout: ROOT=<dir>)
const HOUR = 3600e3, DAY = 86400e3;
const T0 = Date.UTC(2026, 10, 10, 8, 0);

async function fresh() {
    const { newDisk, visit } = require('../tools/visit.js');
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'tidepool-'));
    fs.copyFileSync(path.join(APP, 'TIDEPOOL.COM'), path.join(dir, 'TIDEPOOL.COM'));
    return { disk: await newDisk(dir), visit };
}
const enter = (v, args = '/100') => { v.start(args); v.run(1); v.type(' '); v.run(1); };
const quiet = (v, key) => { v.type(key); v.run(0.3); return /Quiet for (\d+) tide/.exec(v.text())[1] | 0; };

test('a first visit, a cairn, leaving, and a week away: the pool has changed', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    let v = await visit(disk, T0);
    v.start('/100'); v.run(1);
    assert.match(v.text(), /A very slow garden you can't control/);
    v.type(' '); v.run(1);
    assert.match(v.text(), /day 1, /);
    assert.match(v.text(), /Cairn stones: o o o o o \(5 left\)/);
    v.type('3'); v.run(0.3); v.type(' '); v.run(0.5);
    assert.match(v.text(), /Cairn stones: \^ o o o o \(4 left\)/);
    assert.match(v.text(), /Old Tom\s+Saddle/);
    v.type('Q'); v.run(2);
    assert.match(v.text(), /The pool carries on without you[\s\S]*B>/);
    v.m.console.paste('DIR\r'); v.settle();
    assert.match(v.text(), /TIDEPOOL\s+SAV/);

    v = await visit(disk, T0 + 7 * DAY + 3 * HOUR + 25 * 60e3);
    v.start('/100'); v.run(8);
    assert.match(v.text(), /You were away for 7 days and 3 hours\./);
    const n = +/(\d+) tides came and went/.exec(v.text())[1];
    assert.ok(n === 13 || n === 14, `${n} tides in 7 days 3 h`);
    assert.match(v.text(), /While you were gone:/);
    assert.match(v.text(), /settled on/);
    v.type(' '); v.run(2);
    assert.match(v.text(), /day 8, /);
    assert.match(v.text(), /Cairn stones: \^ o o o o \(4 left\)/);
    // the cairn rock has been quiet for the whole of its time, the one you walked over since you left
    assert.equal(quiet(v, '3'), n + 1);
    assert.match(v.text(), /A cairn guards it\./);
    assert.equal(quiet(v, '1'), n);
    assert.match(v.text(), /You will cross it when you go\./);
});

test('the pool goes on while you watch: a tide turns and the quiet counts one more', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    const v = await visit(disk, T0);
    enter(v);
    const before = quiet(v, '1');
    const head = v.text().split('\n')[0];
    v.later(13 * HOUR); v.run(4);
    assert.notEqual(v.text().split('\n')[0], head, 'the clock on the header moved');
    assert.ok(quiet(v, '1') > before, 'a tide has come in');
});

test('naming a rock, then the tide table and the journal', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    const v = await visit(disk, T0);
    enter(v);
    v.type('N'); v.run(0.3); v.type('Brine\r'); v.run(1);
    assert.match(v.text(), /Brine\s+Anvil/);
    assert.match(v.text(), /Brine {2}-  rock 1 of 10/);
    v.type('T'); v.run(2);
    assert.match(v.text(), /THE TIDE TABLE[\s\S]*high water\s+\d\d:\d\d\s+today/);
    v.type(' '); v.run(1);
    v.type('J'); v.run(2);
    assert.match(v.text(), /THE JOURNAL/);
    v.type(' '); v.run(1);
    assert.match(v.text(), /Cairn stones/);
});

test('without a clock each visit is one tide; a VT52 draws the same pool in plain characters', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    let v = await visit(disk, T0);
    v.m.clock.latch = () => {};
    v.term.mode = 'vt52';
    enter(v, '/52');
    assert.match(v.text(), /\(no clock\)/);
    assert.match(v.text(), /\+-- Mossy/);
    v.type('Q'); v.run(2);
    v = await visit(disk, T0);
    v.m.clock.latch = () => {};
    v.term.mode = 'vt52';
    v.start(); v.run(6);
    assert.match(v.text(), /1 tide came and went/);
});

test('a very long absence counts at most CAP tides, in a few seconds of machine time', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    let v = await visit(disk, T0);
    enter(v); v.type('Q'); v.run(2);
    v = await visit(disk, T0 + 5 * 365 * DAY);
    v.start('/100'); v.run(8);
    assert.match(v.text(), /You were away for 1825 days\.\s+2000 tides came and went/);
    v.type(' '); v.run(2);
    assert.match(v.text(), /Cairn stones/);
});

test('the seasons: the header names the season of the date', { skip: !haveRoot }, async () => {
    for (const [when, season] of [[Date.UTC(2026, 10, 10, 8), 'autumn'], [Date.UTC(2027, 0, 15, 8), 'winter'], [Date.UTC(2027, 3, 10, 8), 'spring'], [Date.UTC(2027, 6, 10, 8), 'summer']]) {
        const { disk, visit } = await fresh();
        const v = await visit(disk, when);
        enter(v);
        assert.match(v.text(), new RegExp(`day 1, ${season}`), season);
    }
});

test('the bell rings when a tide turns, and B turns it off', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    const v = await visit(disk, T0);
    let bells = 0;
    v.term.bell = () => { bells++; };
    enter(v);
    bells = 0;
    v.later(13 * HOUR); v.run(4);
    assert.ok(bells >= 1, 'rang for the tide');
    v.type('B'); v.run(0.5);
    assert.match(v.text(), /The bell is off\./);
    bells = 0;
    v.later(13 * HOUR); v.run(4);
    assert.equal(bells, 0, 'silent');
});

test('leaving without Q still walks the open rocks, and says so next time', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    let v = await visit(disk, T0);
    enter(v);                                  // the tab is closed here: no Q
    v = await visit(disk, T0 + DAY);
    v.start('/100'); v.run(6);
    assert.match(v.text(), /Last time you left without a word/);
    v.type(' '); v.run(1);
    v.type('Q'); v.run(2);
    v = await visit(disk, T0 + 2 * DAY);
    v.start('/100'); v.run(6);
    assert.doesNotMatch(v.text(), /left without a word/);
});

test('a rename does not rewrite the journal; R starts a new pool after a Y', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    let v = await visit(disk, T0);
    enter(v); v.type('Q'); v.run(2);
    v = await visit(disk, T0 + 7 * DAY);
    v.start('/100'); v.run(8);
    const name = /settled on ([A-Za-z ]+)\./.exec(v.text())[1];
    const idx = ['Mossy', 'Anvil', 'Old Tom', 'Saddle', 'Gull', 'Lantern', 'Hearth', 'Knuckle', 'Pilot', 'Drift'].indexOf(name);
    assert.ok(idx >= 0, name);
    v.type(' '); v.run(2);
    v.type(String((idx + 1) % 10)); v.run(0.3);
    v.type('N'); v.run(0.3); v.type('Zed\r'); v.run(1);
    assert.match(v.text(), /Zed/);
    v.type('J'); v.run(2);
    assert.match(v.text(), new RegExp(`settled on ${name}\\.`));
    assert.doesNotMatch(v.text(), /settled on Zed/);
    v.type(' '); v.run(1);
    v.type('R'); v.run(0.5);
    assert.match(v.text(), /Start a new pool\?/);
    v.type('n'); v.run(0.5);
    assert.match(v.text(), /Zed/, 'any other key keeps the pool');
    v.type('R'); v.run(0.5); v.type('Y'); v.run(1);
    assert.match(v.text(), /A very slow garden/);
    v.type(' '); v.run(1);
    assert.match(v.text(), /day 1, /);
    assert.doesNotMatch(v.text(), /Zed/);
    assert.match(v.text(), /Mossy\s+Anvil/);
});
