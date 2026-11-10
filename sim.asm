; sim.asm: the pool. One call of simtide is one tide: every rock grows, settles, is grazed, is
; torn by a storm, or is visited. A week away is a loop of fourteen of them. Everything that
; happens to a rock and is worth a sentence goes in the journal (a ring of 16).
;
; A rock is four bytes: species, growth (0-255, a picture every 64), calm (tides since it was
; last stepped on), mark (1 = a cairn guards it).

; ---------------------------------------------------------------- one tide
; simtide: HL = the number of this tide
simtide: ld     (curc),hl
        ld      a,l
        and     15
        call    z,seasonnow     ; the season is looked up every 16 tides (about 8 days)
        xor     a
        ld      (storm),a
        ld      hl,tb_storm
        call    sget
        ld      b,a
        call    rnd
        cp      b
        jr      nc,stm0
        ld      a,1
        ld      (storm),a
        ld      a,EV_STORM
        ld      b,0
        call    evlogg
stm0:   ld      ix,rocks
        xor     a
        ld      (ri),a
st1:    call    rock
        ld      de,RSZ
        add     ix,de
        ld      a,(ri)
        inc     a
        ld      (ri),a
        cp      NROCK
        jr      c,st1
        ret

rock:   ld      a,(ix+R_CALM)
        cp      255
        jr      z,rk0
        inc     a
        ld      (ix+R_CALM),a
rk0:    ld      a,(storm)
        or      a
        jr      z,rk_go
        ld      a,(ix+R_SP)     ; a storm tears barnacles, kelp and mussels
        cp      SP_BARN
        jr      c,rk_go
        cp      SP_MUSS+1
        jr      nc,rk_go
        call    rnd
        and     63
        add     a,50
        ld      c,a
        ld      a,(ix+R_G)
        sub     c
        jr      c,rk_torn
        cp      24
        jr      nc,rk_hurt
rk_torn: ld     c,(ix+R_SP)
        xor     a
        ld      b,a
        call    becomes
        ld      b,c
        ld      a,EV_TORN
        jp      evlog
rk_hurt: ld     (ix+R_G),a
rk_go:  ld      a,(ix+R_SP)
        ld      hl,sptab
        add     a,a
        ld      e,a
        ld      d,0
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        jp      (hl)

sptab:  dw      h_bare,h_film,h_barn,h_kelp,h_muss,h_anem,h_star,h_crab,h_urch

; becomes: A = the new species, B = its growth. Returns B = the species, for evlog.
becomes: ld     (ix+R_SP),a
        ld      (ix+R_G),b
        ld      b,a
        ret

; grow: B = how much. Returns A = the growth.
grow:   ld      a,(season)      ; winter halves it, summer adds a quarter
        or      a
        jr      nz,gr0
        srl     b
        jr      nz,gr2
        inc     b
        jr      gr2
gr0:    cp      2
        jr      nz,gr2
        ld      a,b
        srl     a
        srl     a
        add     a,b
        ld      b,a
gr2:    ld      a,(ix+R_G)
        add     a,b
        jr      nc,gr1
        ld      a,255
gr1:    ld      (ix+R_G),a
        ret

seasonnow: ld   hl,(curc)
        jp      calcseason

; sget: HL = four bytes (winter, spring, summer, autumn) -> A = this season's
sget:   ld      a,(season)
        ld      e,a
        ld      d,0
        add     hl,de
        ld      a,(hl)
        ret

; calcseason: HL = a tide -> season: 0 winter, 1 spring, 2 summer, 3 autumn (December to
; February, and so on; the calendar is the real one, with a leap year every fourth from 1978)
calcseason: ld  de,TIDE            ; the day of the tide, to the nearest
        call    mul32
        ld      hl,(m32)
        ld      de,720
        add     hl,de
        ld      (m32),hl
        jr      nc,ys0
        ld      hl,(m32+2)
        inc     hl
        ld      (m32+2),hl
ys0:    ld      de,1440
        call    div32
        ld      hl,(m32)
        dec     hl              ; days since 1 Jan 1978, from 0
        ld      de,1461         ; four years
ys1:    or      a
        sbc     hl,de
        jr      nc,ys1
        add     hl,de
        ld      de,365
        or      a
        sbc     hl,de
        jr      c,ys5
        or      a
        sbc     hl,de
        jr      c,ys5
        ld      de,366          ; 1980, a leap year
        or      a
        sbc     hl,de
        jr      nc,ys6
        add     hl,de
        ld      de,59           ; after 29 February the date runs a day behind the count
        push    hl
        or      a
        sbc     hl,de
        pop     hl
        jr      c,ys6
        dec     hl
        jr      ys6
ys5:    add     hl,de
ys6:    ld      b,0             ; the seasons start on 1 March, 1 June, 1 September, 1 December
        ld      de,59
        call    yscmp
        ld      de,151
        call    yscmp
        ld      de,243
        call    yscmp
        ld      de,334
        call    yscmp
        ld      a,b
        and     3
        ld      (season),a
        ret
yscmp:  push    hl
        or      a
        sbc     hl,de
        pop     hl
        ret     c
        inc     b
        ret

tb_storm: db    14,7,4,12
tb_settle: db   30,80,56,56
tb_crab: db     4,6,10,6

; senesce: a full grown thing may let go, and leave a film
senesce: ld     a,(ix+R_G)
        cp      255
        ret     nz
        call    rnd
        cp      4
        ret     nc
        ld      c,(ix+R_SP)
        ld      a,SP_FILM
        ld      b,96
        call    becomes
        ld      b,c
        ld      a,EV_DIED
        jp      evlog

; leave: a visitor moves on
leave:  ld      c,(ix+R_SP)
        xor     a
        ld      b,a
        call    becomes
        ld      b,c
        ld      a,EV_LEFT
        jp      evlog

; crab: a hermit crab may cross a bare rock
crab:   ld      hl,tb_crab
        call    sget
        ld      c,a
        call    rnd
        cp      c
        ret     nc
        ld      a,SP_CRAB
        ld      b,100
        call    becomes
        ld      a,EV_VISIT
        jp      evlog

h_bare: call    rnd
        cp      44
        jr      nc,crab
        ld      a,SP_FILM
        ld      b,8
        jp      becomes

h_film: call    rnd
        and     15
        add     a,18
        ld      b,a
        call    grow
        cp      96
        jr      nc,hf1
        jr      crab
hf1:    ld      hl,tb_settle
        call    sget
        ld      c,a
        call    rnd
        cp      c
        ret     nc
        call    rnd
        ld      b,SP_BARN
        cp      100
        jr      c,hf2
        ld      b,SP_KELP
        cp      180
        jr      c,hf2
        ld      b,SP_MUSS
hf2:    ld      a,b
        ld      b,20
        call    becomes
        ld      a,EV_SETTLE
        jp      evlog

h_barn: ld      b,6
        call    grow
        cp      192
        ret     c
        ld      a,(ix+R_CALM)   ; a quiet rock may open an anemone: 12 days of calm
        cp      24
        jr      c,hbn1
        call    rnd
        cp      7
        jr      nc,hbn1
        ld      a,SP_ANEM
        ld      b,40
        call    becomes
        ld      a,EV_BLOOM
        jp      evlog
hbn1:   jp      senesce

h_kelp: ld      b,14
        call    grow
        cp      128
        jr      c,hk1
        call    rnd             ; an urchin finds the kelp
        cp      5
        jr      nc,hk1
        ld      a,SP_URCH
        ld      b,120
        call    becomes
        ld      a,EV_GRAZE
        jp      evlog
hk1:    jp      senesce

h_muss: ld      b,8
        call    grow
        cp      128
        jr      c,hm1
        ld      a,(ix+R_CALM)   ; a sea star needs 8 days of quiet to find them
        cp      16
        jr      c,hm1
        call    rnd
        cp      9
        jr      nc,hm1
        ld      a,SP_STAR
        ld      b,150
        call    becomes
        ld      a,EV_ATE
        jp      evlog
hm1:    jp      senesce

h_anem: ld      b,5
        call    grow
        cp      255
        ret     nz
        call    rnd
        cp      2
        ret     nc
        ld      c,(ix+R_SP)
        ld      a,SP_FILM
        ld      b,96
        call    becomes
        ld      b,c
        ld      a,EV_DIED
        jp      evlog

h_star: call    rnd
        cp      8
        ret     nc
        jp      leave
h_crab: call    rnd
        cp      60
        ret     nc
        jp      leave
h_urch: call    rnd
        cp      24
        ret     nc
        jp      leave

; ---------------------------------------------------------------- the journal
; evlog: A = the event, B = the species; the rock is (ri), the tide (curc).
evlog:  ld      d,a
        ld      a,(ri)
        ld      c,a
        jr      evlog2
; evlogg: the same for the whole pool (rock 255)
evlogg: ld      d,a
        ld      c,0ffh
; an entry is 12 bytes: the tide (word), the rock, event << 4 | species, and the rock's name as
; it was then (8 bytes), so a rename does not rewrite the past
evlog2: push    bc
        push    de
        ld      a,(st_jhead)
        call    jaddr
        pop     de
        pop     bc
        ld      a,(curc)
        ld      (hl),a
        inc     hl
        ld      a,(curc+1)
        ld      (hl),a
        inc     hl
        ld      (hl),c
        inc     hl
        ld      a,d
        rlca
        rlca
        rlca
        rlca
        or      b
        ld      (hl),a
        inc     hl
        ld      a,c
        cp      0ffh
        jr      z,el_g
        push    hl
        call    rname
        pop     de
        ld      bc,8
        ldir
        jr      el_adv
el_g:   ld      (hl),0
        ld      d,h
        ld      e,l
        inc     de
        ld      bc,7
        ldir
el_adv: ld      a,(st_jhead)
        inc     a
        and     15
        ld      (st_jhead),a
        ld      a,(st_jcnt)
        cp      16
        ret     z
        inc     a
        ld      (st_jcnt),a
        ret

; jaddr: A = an entry number -> HL = its address
jaddr:  ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        ld      d,h
        ld      e,l
        add     hl,hl
        add     hl,de
        ld      de,jrnl
        add     hl,de
        ret

; jent: A = 0 for the newest entry, 1 the one before ... -> HL = the entry, carry if none
jent:   ld      b,a
        ld      a,(st_jcnt)
        cp      b
        jr      z,je_no
        jr      c,je_no
        ld      a,(st_jhead)
        dec     a
        sub     b
        and     15
        call    jaddr
        or      a
        ret
je_no:  scf
        ret

; jprint: HL = an entry; prints its sentence
jprint: push    hl
        inc     hl
        inc     hl
        ld      a,(hl)
        ld      (f_rock),a
        inc     hl
        ld      a,(hl)
        and     15
        ld      (f_sp),a
        ld      a,(hl)
        rrca
        rrca
        rrca
        rrca
        and     15
        ld      c,a
        pop     hl
        ld      de,4
        add     hl,de
        ld      (f_name),hl
        ld      a,c
        ld      hl,evtab
        call    getp
        jp      fmt

; jwhen: HL = an entry; prints how long ago ("today", "yesterday", "3 days ago")
jwhen:  ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      hl,(cnow)
        or      a
        sbc     hl,de
        jr      nc,jw1
        ld      hl,0
jw1:    call    cyc2days
        ld      a,h
        or      l
        jr      nz,jw2
        ld      hl,w_today
        jp      puts
jw2:    dec     hl
        ld      a,h
        or      l
        jr      nz,jw3
        ld      hl,w_yest
        jp      puts
jw3:    inc     hl
        call    pdec
        ld      hl,w_ago
        jp      puts

; ---------------------------------------------------------------- stepping on rocks
; trample: you leave across the rocks nobody fenced: what grows there is set back a quarter
; and a little more, the visitors are scared off, and the quiet starts again.
trample: ld     ix,rocks
        xor     a
        ld      (ri),a
tr1:    ld      a,(ix+R_MARK)
        or      a
        jr      nz,tr_skip
        ld      (ix+R_CALM),a
        ld      a,(ix+R_SP)
        or      a
        jr      z,tr_skip
        cp      SP_STAR
        jr      c,tr2
        ld      c,a             ; a visitor goes
        xor     a
        ld      b,a
        call    becomes
        jr      tr_skip
tr2:    ld      a,(ix+R_G)
        ld      b,a
        srl     a
        srl     a
        add     a,10
        ld      c,a
        ld      a,b
        sub     c
        jr      c,tr3
        cp      12
        jr      nc,tr4
tr3:    ld      c,(ix+R_SP)
        ld      a,c
        cp      SP_FILM
        jr      z,tr5
        xor     a
        ld      b,a
        call    becomes
        ld      b,c
        ld      a,EV_STEP
        call    evlog
        jr      tr_skip
tr5:    xor     a
        ld      (ix+R_G),a
        jr      tr_skip
tr4:    ld      (ix+R_G),a
tr_skip: ld     de,RSZ
        add     ix,de
        ld      a,(ri)
        inc     a
        ld      (ri),a
        cp      NROCK
        jr      c,tr1
        ret
