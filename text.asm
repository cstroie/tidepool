; text.asm: the words.

t_title: db     '~ T I D E P O O L ~',0
t_day:  db      'day ',0
t_noclk: db     '  (no clock)',0
t_hw:   db      'High water  ',0
t_lw:   db      'Low water   ',0
t_flood: db     'Flood tide  ',0
t_ebb:  db      'Ebb tide    ',0
t_next: db      '  next ',0
t_high: db      'high ',0
t_low:  db      'low  ',0
t_cairn: db     ' _/^^',92,'_ ',0
t_stones: db    'Cairn stones: ',0
t_none: db      ' none left',0
t_leftw: db     ' left',0
t_rock: db      '  -  rock ',0
t_of10: db      ' of 10 ',0
t_quiet: db     'Quiet for ',0
t_tide: db      'tide',0
t_dayw: db      'day',0
t_hourw: db     'hour',0
t_minw: db      'minute',0
t_tidew: db     'tide',0
t_about: db     ' (about ',0
t_walk: db      'You will cross it when you go.',0
t_guard: db     'A cairn guards it.',0
t_latest: db    'Latest: ',0
t_colon: db     ': ',0
t_nothing: db   'Nothing has happened yet. Be patient: that is the whole game.',0
t_full:  db     'All five stones are placed. Lift a cairn first (SPACE on a rock that has one).',0
t_nameq: db     'Name this rock (7 letters, Enter): ',0
t_keys: db      ' arrows/1-0 choose  SPACE cairn  N name  T tides  J journal  ? help  Q leave',0
t_press: db     'press a key',0
t_away: db      'You were away for ',0
t_and:  db      ' and ',0
t_came: db      ' came and went.',0
t_while: db     'While you were gone:',0
t_quiet2: db    'The pool kept to itself.',0
t_comes: db     'The tide comes in ',0
t_nxt:  db      'The next waters:',0
t_hwl:  db      'high water  ',0
t_lwl:  db      'low water   ',0
t_today: db     'today',0
t_tomorrow: db  'tomorrow',0
t_later: db     'in a day or two',0
t_comma: db     ', ',0
t_out:  db      'You wade back out across the rocks nobody fenced.',CR,LF,0
t_stepped: db   ' are set back a little.',0
t_nostep: db    'Every rock with life on it has a cairn. You leave no mark.',0
t_nextw: db     'Next ',0

t_noclk2: db    'This machine has no clock, so the pool counts one tide for each visit.',LF
        db      'On DigitalRerun the tide table is drawn from the real time.',0

t_tt1:  db      'THE TIDE TABLE',LF
        db      'A tide takes 12 hours 25 minutes. This is the next day of it, from now.',0

t_jt:   db      'THE JOURNAL',LF,'What the pool did, newest first.',0

t_intro: db     'a very slow garden you can',39,'t control',LF,LF
        db      'Ten rocks and a tide table. Things grow when the tide is in.',LF
        db      'You decide only what not to disturb.',LF,LF
        db      'The pool keeps the real time of the clock. Come back tomorrow, or in a',LF
        db      'week: the tides will have kept on without you, fourteen of them, and',LF
        db      'something will have settled, grown, been eaten or torn away.',LF,LF
        db      'You have five cairn stones. SPACE puts one on a rock (or lifts it).',LF
        db      'A rock with a cairn is left alone. When you go, you wade out across the',LF
        db      'rocks that have none, and what lives there is stepped on and starts a',LF
        db      'little smaller. The rare things (anemones, sea stars) only come to',LF
        db      'rocks that stay quiet for days. Visit often and the common things win.',LF,LF
        db      'There is nothing to win. Choose, then go away for a while.',0

t_bye:  db      'The pool carries on without you.',LF,0

; the species
spnames: dw     sn0,sn1,sn2,sn3,sn4,sn5,sn6,sn7,sn8
sn0:    db      'bare rock',0
sn1:    db      'algae',0
sn2:    db      'barnacles',0
sn3:    db      'kelp',0
sn4:    db      'mussels',0
sn5:    db      'anemone',0
sn6:    db      'sea star',0
sn7:    db      'hermit crab',0
sn8:    db      'urchin',0

descs:  dw      d0,d1,d2,d3,d4,d5,d6,d7,d8
d0:     db      'Bare rock, wet and grey. Something will settle here, given time.',0
d1:     db      'A green-brown film of algae: slick, small, the start of everything.',0
d2:     db      'Barnacles. They shut tight at low water and feed with the flood.',0
d3:     db      'Kelp. A holdfast grips the stone and the blades ride the swell.',0
d4:     db      'Mussels, beard-tied to the rock in a dark, patient crowd.',0
d5:     db      'A sea anemone, open in the water. It only comes to quiet rocks.',0
d6:     db      'A sea star, slow as a thought, working through the mussels.',0
d7:     db      'A hermit crab in a borrowed shell. It will not stay.',0
d8:     db      'A sea urchin, grazing. Kelp does not last long beside it.',0

stages: dw      g0,g1,g2,g3
g0:     db      'Tiny.',0
g1:     db      'Young.',0
g2:     db      'Grown.',0
g3:     db      'Full grown.',0

; the journal's sentences, by event
evtab:  dw      0,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10
e1:     db      'A storm tide scoured the pool.',0
e2:     db      '%S settled on %r.',0
e3:     db      'The storm tore the %s off %r.',0
e4:     db      'A sea star found the mussels on %r.',0
e5:     db      'An urchin found the kelp on %r.',0
e6:     db      'A hermit crab wandered onto %r.',0
e7:     db      'The %s on %r moved on.',0
e8:     db      'The old %s on %r let go.',0
e9:     db      'An anemone opened on %r.',0
e10:    db      'You stepped on %r. The %s did not last.',0

w_today: db     'today',0
w_yest: db      'yesterday',0
w_ago:  db      ' days ago',0

m_ask:  db      CR,LF,'TIDEPOOL',CR,LF,CR,LF
        db      'Your terminal?  1 VT100   2 VT52   3 ADM-3A  ',0

defnames: db    'Mossy',0,0,0
        db      'Anvil',0,0,0
        db      'Old Tom',0
        db      'Saddle',0,0
        db      'Gull',0,0,0,0
        db      'Lantern',0
        db      'Hearth',0,0
        db      'Knuckle',0
        db      'Pilot',0,0,0
        db      'Drift',0,0,0
