; TIDEPOOL: a very slow garden you can't control
;
;   A>TIDEPOOL          asks for the terminal the first time
;   A>TIDEPOOL /100     VT100      /52  VT52      /ADM  ADM-3A
;
; Ten rocks and a tide table. Things grow when the tide is in; you decide only what not to
; disturb. The pool keeps the real time of the machine's clock: come back after a week and
; fourteen tides have happened. Z80, CP/M 2.2, 80x24. Assemble with pasmo:
;     pasmo tidepool.asm TIDEPOOL.COM          (art.inc: node mkart.js; build.sh does both)
;
; Copyright (c) 2026 Costin Stroie, MIT licence.

BDOS    equ     0005h
TAIL    equ     0080h
ESC     equ     27
CR      equ     13
LF      equ     10

T_VT100 equ     0
T_VT52  equ     1
T_ADM   equ     2

NROCK   equ     10
RSZ     equ     4               ; species, growth, calm, mark
R_SP    equ     0
R_G     equ     1
R_CALM  equ     2
R_MARK  equ     3
NAMELEN equ     7
NSTONES equ     5               ; cairn stones
CAP     equ     2000            ; tides a long absence is worth at most (almost three years)

SP_BARE equ     0
SP_FILM equ     1
SP_BARN equ     2
SP_KELP equ     3
SP_MUSS equ     4
SP_ANEM equ     5
SP_STAR equ     6
SP_CRAB equ     7
SP_URCH equ     8

EV_STORM equ    1
EV_SETTLE equ   2
EV_TORN equ     3
EV_ATE  equ     4
EV_GRAZE equ    5
EV_VISIT equ    6
EV_LEFT equ     7
EV_DIED equ     8
EV_BLOOM equ    9
EV_STEP equ     10

        org     100h

start:  ld      (oldsp),sp
        ld      sp,stack
        call    load
        ld      (loaded),a
        or      a
        jr      nz,s0
        call    blank
s0:     ld      a,(term)
        cp      3
        jr      c,s1
        cp      0ffh
        jr      z,s1
        ld      a,0ffh
        ld      (term),a
s1:     call    parse
        ld      a,(term)
        cp      0ffh
        call    z,askterm
        call    seed
        call    curoff
        call    cls
        call    gettime
        ld      a,(loaded)
        or      a
        jr      z,fresh
        call    awaycalc
        ld      hl,(st_last)
        ld      (oldlast),hl
        ld      a,1
        ld      (verbose),a
        call    catchup
        ld      hl,(ndone)
        ld      a,h
        or      l
        jr      z,go
        call    welcome
        jr      go
fresh:  call    initpool
        call    intro
go:     call    stampsave
        xor     a
        ld      (sel),a
        ld      (wavef),a
        ld      (wtick),a
        ld      hl,(mdnow)
        ld      (lastmd),hl
        call    drawall

; ---------------------------------------------------------------- the main loop
main:   call    poll
        call    key
        or      a
        jr      nz,mk
        call    delay
        jp      main
mk:     call    upcase
        cp      'Q'
        jp      z,quit
        cp      19              ; left
        jr      z,m_left
        cp      ','
        jr      z,m_left
        cp      '<'
        jr      z,m_left
        cp      4               ; right
        jr      z,m_right
        cp      '.'
        jr      z,m_right
        cp      '>'
        jr      z,m_right
        cp      ' '
        jr      z,m_mark
        cp      CR
        jr      z,m_mark
        cp      'N'
        jr      z,m_name
        cp      'T'
        jr      z,m_tide
        cp      'J'
        jr      z,m_jrnl
        cp      '?'
        jr      z,m_help
        cp      '0'
        jr      z,m_zero
        cp      '1'
        jp      c,main
        cp      '9'+1
        jp      nc,main
        sub     '1'
        jr      m_pick
m_zero: ld      a,9
m_pick: ld      (sel),a
        call    drawlow
        jp      main
m_left: ld      a,(sel)
        or      a
        jp      z,main
        dec     a
        jr      m_pick
m_right: ld     a,(sel)
        cp      NROCK-1
        jp      nc,main
        inc     a
        jr      m_pick
m_mark: call    toggle
        jp      main
m_name: call    namerock
        jp      main
m_tide: call    tidescr
        jr      m_back
m_jrnl: call    jrnlscr
        jr      m_back
m_help: call    intro
m_back: call    drawall
        jp      main

; ---------------------------------------------------------------- the clock, live
poll:   ld      a,(hasclk)
        or      a
        ret     z
        call    gettime
        ld      hl,(cnow)
        ld      de,(st_last)
        or      a
        sbc     hl,de
        jr      c,po2
        jr      z,po2
        xor     a
        ld      (verbose),a
        call    catchup
        call    stampsave
        ld      a,1
        ld      (dirty),a
po2:    ld      hl,(mdnow)      ; a new minute: the clock and the tide
        ld      de,(lastmd)
        or      a
        sbc     hl,de
        jr      z,po3
        ld      hl,(mdnow)
        ld      (lastmd),hl
        call    drawhead
        ld      hl,(pnow)
        call    level
        ld      b,a
        ld      a,(curlev)
        cp      b
        jr      nz,po_d
        call    calcsun
        ld      a,(sunx)
        ld      b,a
        ld      a,(lsx)
        cp      b
        jr      z,po3
po_d:   ld      a,1
        ld      (dirty),a
po3:    ld      a,(wtick)       ; the waves move every second or two
        inc     a
        ld      (wtick),a
        and     15
        jr      nz,po4
        ld      hl,wavef
        inc     (hl)
        ld      a,(waterl)
        call    drawrow
po4:    ld      a,(dirty)
        or      a
        ret     z
        xor     a
        ld      (dirty),a
        call    drawhead
        call    drawscene
        call    drawstrip
        call    drawpane
        jp      drawlatest

; stampsave: this moment is the last visit
stampsave: ld   hl,(mnow)
        ld      (st_seen),hl
        ld      hl,(mnow+2)
        ld      (st_seen+2),hl
        jp      save

; awaycalc: how long since the last visit
awaycalc: ld    hl,(mnow)
        ld      de,(st_seen)
        or      a
        sbc     hl,de
        ld      (m32),hl
        ld      hl,(mnow+2)
        ld      de,(st_seen+2)
        sbc     hl,de
        ld      (m32+2),hl
        jr      nc,aw1
        ld      hl,0
        ld      (m32),hl
        ld      (m32+2),hl
aw1:    ld      de,1440
        call    div32
        ld      (awayrem),hl
        ld      hl,(m32)
        ld      (awaydays),hl
        ret

; catchup: the tides since st_last, one by one. ndone = how many.
catchup: ld     hl,0
        ld      (ndone),hl
        ld      hl,(cnow)
        ld      de,(st_last)
        or      a
        sbc     hl,de
        ret     c
        ret     z
        ld      de,CAP
        push    hl
        or      a
        sbc     hl,de
        pop     hl
        jr      c,cu1
        ld      hl,(cnow)       ; longer than we count: only the last CAP tides happen
        or      a
        sbc     hl,de
        ld      (st_last),hl
        ld      hl,CAP
cu1:    ld      (ndone),hl
        ld      (ntides),hl
        ld      a,(verbose)
        or      a
        jr      z,cu2
        ld      b,12
        ld      c,3
        call    gotoxy
        ld      hl,t_comes
        call    puts
cu2:    ld      hl,(st_last)
        inc     hl
        ld      (st_last),hl
        call    simtide
        ld      a,(verbose)
        or      a
        jr      z,cu3
        ld      a,(ntides)
        and     15
        jr      nz,cu3
        ld      a,'.'
        call    putc
cu3:    ld      hl,(ntides)
        dec     hl
        ld      (ntides),hl
        ld      a,h
        or      l
        jr      nz,cu2
        ret

; ---------------------------------------------------------------- a new pool
blank:  ld      hl,state
        ld      de,state+1
        ld      bc,255
        ld      (hl),0
        ldir
        ld      a,'T'
        ld      (state),a
        ld      a,'P'
        ld      (state+1),a
        ld      a,1
        ld      (state+2),a
        ld      a,0ffh
        ld      (term),a
        ret

initpool: ld    hl,defnames
        ld      de,names
        ld      bc,80
        ldir
        ld      hl,(daynow)
        ld      (st_bday),hl
        ld      hl,(cnow)
        ld      (st_last),hl
        ld      ix,rocks        ; three rocks start with a film
        ld      (ix+RSZ*1+R_SP),SP_FILM
        ld      (ix+RSZ*1+R_G),40
        ld      (ix+RSZ*4+R_SP),SP_FILM
        ld      (ix+RSZ*4+R_G),20
        ld      (ix+RSZ*7+R_SP),SP_FILM
        ld      (ix+RSZ*7+R_G),60
        ld      b,NROCK
        ld      de,RSZ
cl1:    ld      (ix+R_CALM),1
        add     ix,de
        djnz    cl1
        ret

; ---------------------------------------------------------------- leaving
quit:   ld      a,(hasclk)
        or      a
        call    nz,gettime
        ld      hl,(cnow)
        ld      (curc),hl
        call    banner
        ld      b,5
        ld      hl,t_out
        call    block
        ; the rocks you walk over
        ld      ix,rocks
        xor     a
        ld      (ri),a
        ld      (tmp1),a
q1:     ld      a,(ix+R_MARK)
        or      a
        jr      nz,q3
        ld      a,(ix+R_SP)
        or      a
        jr      z,q3
        ld      a,(tmp1)
        or      a
        jr      z,q2
        ld      hl,t_comma
        call    puts
q2:     ld      a,(tmp1)
        inc     a
        ld      (tmp1),a
        ld      a,(ri)
        call    rname
        call    puts
q3:     ld      de,RSZ
        add     ix,de
        ld      a,(ri)
        inc     a
        ld      (ri),a
        cp      NROCK
        jr      c,q1
        ld      a,(tmp1)
        or      a
        ld      hl,t_nostep
        jr      z,q4
        ld      hl,t_stepped
q4:     call    puts
        call    trample
        call    stampsave
        ld      b,12
        ld      hl,t_bye
        call    block
        ld      a,(hasclk)
        or      a
        jr      z,q5
        call    evnext
        ld      hl,t_nextw
        call    puts
        ld      a,(ev_ty)
        or      a
        ld      hl,t_high
        jr      z,q6
        ld      hl,t_low
q6:     call    puts
        call    nextclock
        call    ptime
        ld      a,'.'
        call    putc
q5:     ld      b,16
        ld      c,1
        call    gotoxy
        call    curon
        ld      sp,(oldsp)
        ret

        include "sim.asm"
        include "clock.asm"
        include "ui.asm"
        include "save.asm"
        include "term.asm"
        include "text.asm"
        include "art.inc"

progend:
; ---------------------------------------------------------------- memory, after the program
state   equ     progend         ; what TIDEPOOL.SAV holds: 256 bytes
term    equ     state+3
st_bday equ     state+4
st_last equ     state+6
rseed   equ     state+8
st_seen equ     state+10
st_jhead equ    state+14
st_jcnt equ     state+15
rocks   equ     state+16
names   equ     state+64
jrnl    equ     state+144

v0      equ     state+256
oldsp   equ     v0+0
loaded  equ     v0+2
hasclk  equ     v0+3
clkbuf  equ     v0+4
mnow    equ     v0+20
cnow    equ     v0+24
pnow    equ     v0+26
daynow  equ     v0+28
mdnow   equ     v0+30
m32     equ     v0+32
mA      equ     v0+36
ev_t    equ     v0+40
ev_ty   equ     v0+42
curc    equ     v0+43
storm   equ     v0+45
ri      equ     v0+46
f_sp    equ     v0+47
f_rock  equ     v0+48
sel     equ     v0+49
curlev  equ     v0+50
waterl  equ     v0+51
wavef   equ     v0+52
wtick   equ     v0+53
cury    equ     v0+54
cura    equ     v0+55
x0      equ     v0+56
sunx    equ     v0+57
lsx     equ     v0+58
isnight equ     v0+59
dirty   equ     v0+60
lastmd  equ     v0+61
oldlast equ     v0+63
ndone   equ     v0+65
ntides  equ     v0+67
verbose equ     v0+69
awaydays equ    v0+70
awayrem equ     v0+72
rowi    equ     v0+74
pidx    equ     v0+75
plotp   equ     v0+76
tmp1    equ     v0+78
tmp2    equ     v0+80
namebuf equ     v0+82
scn     equ     v0+96           ; the pool, 12 rows of 80
stackb  equ     scn+960
stack   equ     stackb+256
