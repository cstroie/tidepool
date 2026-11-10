; ui.asm: everything on the screen. 80x24:
;
;    1-3   the title, the day and hour, the tide and its gauge, a wave rule
;    4-15  the pool: twelve rows, the sky above, the water as high as the tide, the rocks below
;   16-18  the sand (a cairn where you left a rock alone), the names, the cairn stones
;   19-22  the rock you are looking at, in a VT100 line-drawing frame
;   23-24  the latest happening; the keys

; ---------------------------------------------------------------- helpers
; getp: HL = a table of words, A = the index -> HL = the word
getp:   ld      e,a
        ld      d,0
        add     hl,de
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ret

; spnm: A = species -> HL = its name
spnm:   ld      hl,spnames
        jp      getp

; rname: A = rock -> HL = its name (8 bytes, 7 letters)
rname:  ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      de,names
        add     hl,de
        ret

; selix: IX = the chosen rock
selix:  ld      a,(sel)
        add     a,a
        add     a,a
        ld      e,a
        ld      d,0
        ld      ix,rocks
        add     ix,de
        ret

; countmarks: A = how many cairns stand
countmarks: ld  ix,rocks
        ld      de,RSZ
        ld      b,NROCK
        ld      c,0
cm1:    ld      a,(ix+R_MARK)
        or      a
        jr      z,cm2
        inc     c
cm2:    add     ix,de
        djnz    cm1
        ld      a,c
        ret

; fmt: HL = text with %s (the species, lower case) %S (capitalised) %r (the rock's name)
fmt:    ld      a,(hl)
        inc     hl
        or      a
        ret     z
        cp      '%'
        jr      z,fm1
        call    putc
        jr      fmt
fm1:    ld      a,(hl)
        inc     hl
        cp      's'
        jr      z,fms
        cp      'S'
        jr      z,fmS
        cp      'r'
        jr      z,fmr
        call    putc
        jr      fmt
fms:    push    hl
        ld      a,(f_sp)
        call    spnm
        call    puts
        pop     hl
        jr      fmt
fmS:    push    hl
        ld      a,(f_sp)
        call    spnm
        ld      a,(hl)
        call    upcase
        call    putc
        inc     hl
        call    puts
        pop     hl
        jr      fmt
fmr:    push    hl
        ld      hl,(f_name)
        call    puts
        pop     hl
        jr      fmt

; pnoun: HL = a number, DE = its noun: "3 days", "1 day"
pnoun:  push    hl
        push    de
        call    pdec
        pop     de
        ld      a,' '
        call    putc
        ex      de,hl
        call    puts
        pop     hl
        dec     hl
        ld      a,h
        or      l
        ret     z
        ld      a,'s'
        jp      putc

; ptime: HL = minutes of the day -> HH:MM
ptime:  ld      de,60
        ld      c,0
pt1:    or      a
        sbc     hl,de
        jr      c,pt2
        inc     c
        jr      pt1
pt2:    add     hl,de
        ld      a,c
        push    hl
        call    dec2
        ld      a,':'
        call    putc
        pop     hl
        ld      a,l
        jp      dec2

; nextclock: HL = the time of day, ev_t minutes from now
nextclock: ld   hl,(mdnow)
        ld      de,(ev_t)
        add     hl,de
        ld      de,1440
        or      a
        sbc     hl,de
        jr      nc,nc1
        add     hl,de
nc1:    ret

; msg: HL = a line for row 23
msg:    push    hl
        ld      b,23
        ld      c,2
        call    gotoxy
        call    eol
        pop     hl
        jp      puts

; ---------------------------------------------------------------- the whole screen
drawall: call   cls
        call    drawhead
        call    drawscene
        call    drawstrip
        call    drawpane
        call    drawlatest
        jp      drawkeys

; ---------------------------------------------------------------- rows 1-3
drawhead: ld    b,1
        ld      c,2
        call    gotoxy
        ld      a,A_BOLD
        call    setattr
        ld      hl,t_title
        call    puts
        xor     a
        call    setattr
        ld      b,1
        ld      c,46
        call    gotoxy
        ld      hl,t_day
        call    puts
        ld      hl,(daynow)
        ld      de,(st_bday)
        or      a
        sbc     hl,de
        jr      nc,dh0
        ld      hl,0
dh0:    inc     hl
        call    pdec
        ld      hl,t_comma
        call    puts
        ld      hl,(cnow)
        call    calcseason
        ld      a,(season)
        ld      hl,seasons
        call    getp
        call    puts
        ld      a,(hasclk)
        or      a
        jr      z,dh_nc
        ld      b,2
        call    spaces
        ld      hl,(mdnow)
        call    ptime
        jr      dh1
dh_nc:  ld      hl,t_noclk
        call    puts
dh1:    call    eol
        ; row 2: the tide
        ld      b,2
        ld      c,2
        call    gotoxy
        call    evnext
        ld      hl,(ev_t)
        ld      a,h
        or      l
        jr      nz,dh2
        ld      hl,t_hw
        ld      a,(ev_ty)
        or      a
        jr      z,dh4
        ld      hl,t_lw
        jr      dh4
dh2:    ld      hl,t_flood
        ld      a,(ev_ty)
        or      a
        jr      z,dh4
        ld      hl,t_ebb
dh4:    call    puts
        ld      hl,(pnow)
        call    level
        ld      (curlev),a
        ld      a,'['
        call    putc
        ld      a,(curlev)
        or      a
        jr      z,dh7
        ld      b,a
        ld      a,(term)
        cp      T_VT100
        jr      nz,dh6
        call    gfxon
dh5:    ld      a,'a'
        call    putc
        djnz    dh5
        call    gfxoff
        jr      dh7
dh6:    ld      a,'='
        call    putc
        djnz    dh6
dh7:    ld      a,(curlev)
        ld      c,a
        ld      a,15
        sub     c
        jr      z,dh9
        ld      b,a
dh8:    ld      a,'.'
        call    putc
        djnz    dh8
dh9:    ld      a,']'
        call    putc
        ld      a,(hasclk)
        or      a
        jr      z,dh10
        ld      hl,t_next
        call    puts
        ld      a,(ev_ty)
        or      a
        ld      hl,t_high
        jr      z,dh11
        ld      hl,t_low
dh11:   call    puts
        call    nextclock
        call    ptime
dh10:   call    eol
        ; row 3: a rule of waves
        ld      b,3
        ld      c,1
        call    gotoxy
        ld      a,A_DIM
        call    setattr
        ld      b,39
dh12:   ld      a,'~'
        call    putc
        ld      a,'-'
        call    putc
        djnz    dh12
        xor     a
        jp      setattr

; ---------------------------------------------------------------- rows 4-15, the pool
wl_tab: db      11,10,10,9,8,8,7,6,5,5,4,3,3,2,2,1

; calcsun: the sun by day, the moon by night, from the minute of the day: sunx, isnight
calcsun: ld     hl,(mdnow)
        ld      de,360
        or      a
        sbc     hl,de
        jr      nc,cs1
        ld      de,720          ; before six: night, t = minute + 360
        add     hl,de
        jr      cs_n
cs1:    ld      de,720
        or      a
        sbc     hl,de
        jr      nc,cs_n         ; after six in the evening: night, t = minute - 1080
        add     hl,de
        xor     a               ; by day, t = minute - 360
        jr      cs2
cs_n:   ld      a,1
cs2:    ld      (isnight),a
        ld      c,4
cs3:    ld      de,10
        or      a
        sbc     hl,de
        jr      c,cs4
        inc     c
        jr      cs3
cs4:    ld      a,c
        cp      77
        jr      c,cs5
        ld      a,76
cs5:    ld      (sunx),a
        ret

; compose: the pool as 12 rows of 80 characters in scn
compose: ld     hl,scn
        ld      de,scn+1
        ld      bc,959
        ld      (hl),' '
        ldir
        call    calcsun
        ld      a,(isnight)
        or      a
        jr      z,cp_sun
        ld      hl,stars        ; stars
cpst:   ld      a,(hl)
        inc     hl
        cp      255
        jr      z,cpmoon
        ld      e,a
        ld      d,0
        push    hl
        ld      hl,scn
        add     hl,de
        ld      (hl),'.'
        ld      de,80+3
        add     hl,de
        ld      (hl),'+'
        pop     hl
        jr      cpst
cpmoon: ld      a,(sunx)
        ld      e,a
        ld      d,0
        ld      hl,scn
        add     hl,de
        ld      (hl),'('
        inc     hl
        ld      (hl),')'
        jr      cp0
cp_sun: ld      a,(sunx)
        ld      e,a
        ld      d,0
        ld      hl,scn
        add     hl,de
        ld      (hl),'('
        inc     hl
        ld      (hl),'O'
        inc     hl
        ld      (hl),')'
cp0:    ld      ix,rocks
        xor     a
        ld      (ri),a
cp1:    ld      a,(ri)
        add     a,a
        add     a,a
        add     a,a
        ld      (x0),a
        ld      e,a
        ld      d,0
        ld      hl,scn+720
        add     hl,de
        ex      de,hl
        ld      hl,rockart
        ld      b,3
        call    blit
        ld      a,(ix+R_SP)
        or      a
        jr      z,cp2
        dec     a
        add     a,a
        add     a,a
        ld      b,a
        ld      a,(ix+R_G)
        rlca
        rlca
        and     3
        add     a,b
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      d,h
        ld      e,l
        add     hl,hl
        add     hl,hl
        add     hl,de
        ld      de,art
        add     hl,de
        push    hl
        ld      a,(x0)
        ld      e,a
        ld      d,0
        ld      hl,scn+320
        add     hl,de
        ex      de,hl
        pop     hl
        ld      b,5
        call    blit
cp2:    ld      de,RSZ
        add     ix,de
        ld      a,(ri)
        inc     a
        ld      (ri),a
        cp      NROCK
        jr      c,cp1
        ret
stars:  db      6,17,29,41,52,63,74,255

; blit: HL = rows of 8 characters, DE = where in scn, B = rows. A space is transparent.
blit:   push    bc
        push    de
        ld      b,8
bl1:    ld      a,(hl)
        inc     hl
        cp      ' '
        jr      z,bl2
        ld      (de),a
bl2:    inc     de
        djnz    bl1
        pop     de
        push    hl
        ld      hl,80
        add     hl,de
        ex      de,hl
        pop     hl
        pop     bc
        djnz    blit
        ret

drawscene: ld   hl,(pnow)
        call    level
        ld      (curlev),a
        ld      e,a
        ld      d,0
        ld      hl,wl_tab
        add     hl,de
        ld      a,(hl)
        ld      (waterl),a
        call    compose
        ld      a,(sunx)
        ld      (lsx),a
        xor     a
        ld      (rowi),a
ds1:    ld      a,(rowi)
        call    drawrow
        ld      a,(rowi)
        inc     a
        ld      (rowi),a
        cp      12
        jr      c,ds1
        ret

; drawrow: A = 0-11, a row of the pool. Above the water: bright. The surface: waves. Under
; it: what lives there, plain, and the water itself, dim.
drawrow: ld     (cury),a
        ld      hl,scn
        or      a
        jr      z,dr0
        ld      b,a
        ld      de,80
dra:    add     hl,de
        djnz    dra
dr0:    ld      a,(cury)
        add     a,4
        ld      b,a
        ld      c,1
        call    gotoxy
        ld      a,0ffh
        ld      (cura),a
        ld      c,0
dr1:    ld      a,(hl)
        inc     hl
        ld      e,a
        ld      a,(cury)
        ld      d,a
        ld      a,(waterl)
        cp      d
        jr      z,drs
        jr      c,drw
        ld      a,A_BOLD
        jr      dr_out
drs:    ld      a,e
        cp      ' '
        ld      a,A_BOLD
        jr      nz,dr_out
        ld      a,(wavef)
        add     a,c
        and     3
        ld      e,'~'
        cp      2
        jr      c,drs1
        ld      e,'-'
        cp      3
        jr      nz,drs1
        ld      e,' '
drs1:   xor     a
        jr      dr_out
drw:    ld      a,e
        cp      ' '
        ld      a,0
        jr      nz,dr_out
        ld      a,c
        add     a,d
        add     a,d
        add     a,d
        and     7
        ld      e,' '
        ld      a,A_DIM
        jr      nz,dr_out
        ld      e,'~'
dr_out: ld      b,a
        ld      a,(cura)
        cp      b
        jr      z,dr2
        ld      a,b
        ld      (cura),a
        call    attrset
dr2:    ld      a,e
        call    putc
        inc     c
        ld      a,c
        cp      80
        jr      c,dr1
        xor     a
        jp      attrset

; ---------------------------------------------------------------- rows 16-18
drawstrip: ld   b,16
        ld      c,1
        call    gotoxy
        ld      ix,rocks
        xor     a
        ld      (ri),a
dst1:   ld      a,(ix+R_MARK)
        or      a
        jr      z,dst2
        ld      a,A_BOLD
        call    attrset
        ld      hl,t_cairn
        call    puts
        jr      dst4
dst2:   ld      a,A_DIM
        call    attrset
        call    gfxon
        ld      b,8
dst3:   ld      a,'a'
        call    gc
        djnz    dst3
        call    gfxoff
dst4:   xor     a
        call    attrset
        ld      de,RSZ
        add     ix,de
        ld      a,(ri)
        inc     a
        ld      (ri),a
        cp      NROCK
        jr      c,dst1
        ; row 17: the names
        ld      b,17
        ld      c,1
        call    gotoxy
        ld      ix,rocks
        xor     a
        ld      (ri),a
nr1:    ld      a,(sel)
        ld      b,a
        ld      a,(ri)
        cp      b
        ld      a,A_REV
        jr      z,nr2
        ld      a,(ix+R_MARK)
        or      a
        ld      a,A_BOLD
        jr      nz,nr2
        xor     a
nr2:    call    attrset
        ld      a,(ri)
        call    rname
        ld      b,NAMELEN
nr3:    ld      a,(hl)
        inc     hl
        or      a
        jr      nz,nr4
        ld      a,' '
nr4:    call    putc
        djnz    nr3
        xor     a
        call    attrset
        ld      a,' '
        call    putc
        ld      de,RSZ
        add     ix,de
        ld      a,(ri)
        inc     a
        ld      (ri),a
        cp      NROCK
        jr      c,nr1
        ; row 18: the cairn stones
        ld      b,18
        ld      c,2
        call    gotoxy
        ld      hl,t_stones
        call    puts
        call    countmarks
        ld      (tmp1),a
        ld      b,NSTONES
        ld      c,0
dst5:   ld      a,(tmp1)
        cp      c
        ld      a,'o'
        jr      z,dst7
        jr      c,dst7
        ld      a,'^'
dst7:   call    putc
        ld      a,' '
        call    putc
        inc     c
        djnz    dst5
        ld      a,(tmp1)
        ld      c,a
        ld      a,NSTONES
        sub     c
        jr      nz,dst8
        ld      hl,t_none
        call    puts
        jp      eol
dst8:   ld      l,a
        ld      h,0
        call    pnoun_left
        jp      eol

; pnoun_left: HL = stones left -> "(3 left)"
pnoun_left: ld  a,'('
        call    putc
        call    pdec
        ld      hl,t_leftw
        call    puts
        ld      a,')'
        jp      putc

; ---------------------------------------------------------------- rows 19-22
drawpane: ld    b,19
        ld      c,1
        call    gotoxy
        call    gfxon
        ld      a,'l'
        call    gc
        ld      b,78
dp1:    ld      a,'q'
        call    gc
        djnz    dp1
        ld      a,'k'
        call    gc
        call    gfxoff
        ld      b,19
        ld      c,4
        call    gotoxy
        ld      a,A_BOLD
        call    setattr
        ld      a,' '
        call    putc
        ld      a,(sel)
        call    rname
        call    puts
        ld      hl,t_rock
        call    puts
        ld      a,(sel)
        inc     a
        ld      l,a
        ld      h,0
        call    pdec
        ld      hl,t_of10
        call    puts
        xor     a
        call    setattr
        call    selix
        ; row 20: what lives here
        ld      b,20
        ld      c,3
        call    gotoxy
        ld      a,(ix+R_SP)
        ld      hl,descs
        call    getp
        call    puts
        call    eol
        ld      b,20
        call    sidebars
        ; row 21: how it is
        ld      b,21
        ld      c,3
        call    gotoxy
        ld      a,(ix+R_SP)
        or      a
        jr      z,dp3
        cp      SP_STAR
        jr      nc,dp3
        ld      a,(ix+R_G)
        rlca
        rlca
        and     3
        ld      hl,stages
        call    getp
        call    puts
        ld      a,' '
        call    putc
dp3:    ld      hl,t_quiet
        call    puts
        ld      l,(ix+R_CALM)
        ld      h,0
        ld      de,t_tide
        call    pnoun
        ld      l,(ix+R_CALM)
        ld      h,0
        call    cyc2days
        ld      a,h
        or      l
        jr      z,dp4
        push    hl
        ld      hl,t_about
        call    puts
        pop     hl
        ld      de,t_dayw
        call    pnoun
        ld      a,')'
        call    putc
dp4:    ld      a,'.'
        call    putc
        ld      a,' '
        call    putc
        call    selix
        ld      hl,t_walk
        ld      a,(ix+R_MARK)
        or      a
        jr      z,dp5
        ld      hl,t_guard
dp5:    call    puts
        call    eol
        ld      b,21
        call    sidebars
        ; row 22
        ld      b,22
        ld      c,1
        call    gotoxy
        call    gfxon
        ld      a,'m'
        call    gc
        ld      b,78
dp6:    ld      a,'q'
        call    gc
        djnz    dp6
        ld      a,'j'
        call    gc
        jp      gfxoff

; sidebars: B = the row
sidebars: ld    c,1
        call    gotoxy
        call    gfxon
        ld      a,'x'
        call    gc
        call    gfxoff
        ld      c,80
        call    gotoxy
        call    gfxon
        ld      a,'x'
        call    gc
        jp      gfxoff

; ---------------------------------------------------------------- rows 23-24
drawlatest: ld  b,23
        ld      c,2
        call    gotoxy
        call    eol
        xor     a
        call    jent
        jr      c,dl1
        push    hl
        ld      hl,t_latest
        call    puts
        pop     hl
        push    hl
        call    jwhen
        ld      hl,t_colon
        call    puts
        pop     hl
        jp      jprint
dl1:    ld      hl,t_nothing
        jp      puts

drawkeys: ld    b,24
        ld      c,1
        call    gotoxy
        ld      a,A_REV
        call    setattr
        ld      hl,t_keys
        call    puts
        call    eol
        xor     a
        jp      setattr

; ---------------------------------------------------------------- screens
; text: HL = a block of lines; prints it from row B, column 3
block:  ld      c,3
        call    gotoxy
bk1:    ld      a,(hl)
        inc     hl
        or      a
        ret     z
        cp      LF
        jr      nz,bk2
        inc     b
        push    hl
        ld      c,3
        call    gotoxy
        pop     hl
        jr      bk1
bk2:    call    putc
        jr      bk1

banner: call    cls
        ld      b,2
        ld      c,3
        call    gotoxy
        ld      a,A_BOLD
        call    setattr
        ld      hl,t_title
        call    puts
        xor     a
        call    setattr
        ret

pressakey: ld   b,23
        ld      c,3
        call    gotoxy
        ld      a,A_BLINK
        call    setattr
        ld      hl,t_press
        call    puts
        xor     a
        call    setattr
        call    getkey
        ret

intro:  call    banner
        ld      b,4
        ld      hl,t_intro
        call    block
        jp      pressakey

welcome: call   banner
        ld      b,4
        ld      c,3
        call    gotoxy
        ld      hl,t_away
        call    puts
        ld      hl,(awayrem)
        call    divmod60
        ld      a,c
        ld      (tmp1),a
        ld      (tmp2),hl
        ld      hl,(awaydays)
        ld      a,h
        or      l
        jr      z,wl_nd
        ld      de,t_dayw
        call    pnoun
        ld      a,(tmp1)
        or      a
        jr      z,wl2
        ld      hl,t_and
        call    puts
        ld      a,(tmp1)
        ld      l,a
        ld      h,0
        ld      de,t_hourw
        call    pnoun
        jr      wl2
wl_nd:  ld      a,(tmp1)
        or      a
        jr      z,wl_m
        ld      l,a
        ld      h,0
        ld      de,t_hourw
        call    pnoun
        jr      wl2
wl_m:   ld      hl,(tmp2)
        ld      de,t_minw
        call    pnoun
wl2:    ld      a,'.'
        call    putc
        ld      a,' '
        call    putc
        ld      hl,(ndone)
        ld      de,t_tidew
        call    pnoun
        ld      hl,t_came
        call    puts
        call    chglist
        ld      a,(unclean)
        or      a
        jr      z,wc0
        ld      b,6
        ld      c,3
        call    gotoxy
        ld      hl,t_unclean
        call    puts
wc0:    ; what happened: the entries newer than the last visit
        ld      c,0
wc1:    ld      a,c
        push    bc
        call    jent
        pop     bc
        jr      c,wc2
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      hl,(oldlast)
        or      a
        sbc     hl,de
        jr      nc,wc2
        inc     c
        ld      a,c
        cp      11
        jr      c,wc1
wc2:    ld      a,c
        ld      (tmp1),a
        or      a
        jr      nz,wc3
        ld      b,7
        ld      c,3
        call    gotoxy
        ld      hl,t_quiet2
        call    puts
        jp      pressakey
wc3:    ld      b,7
        ld      c,3
        call    gotoxy
        ld      hl,t_while
        call    puts
        ld      a,9
        ld      (rowi),a
wc4:    ld      a,(tmp1)
        dec     a
        ld      (tmp1),a
        call    jent
        push    hl
        ld      a,(rowi)
        ld      b,a
        ld      c,5
        call    gotoxy
        ld      a,'-'
        call    putc
        ld      a,' '
        call    putc
        pop     hl
        call    jprint
        ld      a,(rowi)
        inc     a
        ld      (rowi),a
        ld      a,(tmp1)
        or      a
        jr      nz,wc4
        jp      pressakey

; chglist: which rocks have a different thing on them than when you left
chglist: ld     b,5
        ld      c,3
        call    gotoxy
        ld      hl,t_changed
        call    puts
        xor     a
        ld      (tmp1),a
        ld      (ri),a
        ld      ix,rocks
        ld      iy,rocks0
cg1:    ld      a,(ix+R_SP)
        cp      (iy+R_SP)
        jr      z,cg4
        ld      a,(tmp1)
        cp      7
        jr      nc,cg4
        or      a
        jr      z,cg2
        ld      hl,t_comma
        call    puts
cg2:    ld      a,(tmp1)
        inc     a
        ld      (tmp1),a
        ld      a,(ri)
        call    rname
        call    puts
cg4:    ld      de,RSZ
        add     ix,de
        add     iy,de
        ld      a,(ri)
        inc     a
        ld      (ri),a
        cp      NROCK
        jr      c,cg1
        ld      a,(tmp1)
        or      a
        ret     nz
        ld      hl,t_nochg
        jp      puts

; divmod60: HL minutes -> C hours, HL minutes
divmod60: ld    de,60
        ld      c,0
dm1:    or      a
        sbc     hl,de
        jr      c,dm2
        inc     c
        jr      dm1
dm2:    add     hl,de
        ret

; the tide table: a day of the tide drawn out, and the next high and low waters
tidescr: call   banner
        ld      b,4
        ld      hl,t_tt1
        call    block
        ld      a,(hasclk)
        or      a
        jr      nz,tt0
        ld      b,8
        ld      hl,t_noclk2
        call    block
        jp      pressakey
tt0:    ld      hl,(pnow)
        ld      (plotp),hl
        xor     a
        ld      (pidx),a
tt1:    ld      hl,(plotp)
        call    level
        ld      b,a
        ld      a,15
        sub     b
        srl     a
        add     a,8
        ld      b,a             ; row 8-15
        ld      a,(pidx)
        add     a,14
        ld      c,a
        call    gotoxy
        ld      a,(pidx)
        or      a
        ld      a,A_BLINK+A_BOLD
        jr      z,tt2
        xor     a
tt2:    call    setattr
        ld      a,'*'
        call    putc
        xor     a
        call    setattr
        ld      hl,(plotp)
        ld      de,24
        add     hl,de
        ld      de,TIDE
        or      a
        sbc     hl,de
        jr      nc,tt3
        add     hl,de
tt3:    ld      (plotp),hl
        ld      a,(pidx)
        inc     a
        ld      (pidx),a
        cp      60
        jr      c,tt1
        ld      b,8
        ld      c,3
        call    gotoxy
        ld      hl,t_high
        call    puts
        ld      b,15
        ld      c,3
        call    gotoxy
        ld      hl,t_low
        call    puts
        ld      b,16
        ld      c,14
        call    gotoxy
        ld      a,A_DIM
        call    setattr
        call    gfxon
        ld      b,60
tt4:    ld      a,'q'
        call    gc
        djnz    tt4
        call    gfxoff
        xor     a
        call    setattr
        ; the hours under it, every two
        ld      hl,(mdnow)
        ld      de,60
        ld      c,0
tt5:    or      a
        sbc     hl,de
        jr      c,tt6
        inc     c
        jr      tt5
tt6:    ld      a,c
        ld      (tmp1),a
        xor     a
        ld      (pidx),a
tt7:    ld      a,(pidx)
        ld      c,a
        add     a,a
        add     a,a
        add     a,c
        add     a,14
        ld      c,a
        ld      b,17
        call    gotoxy
        ld      a,(tmp1)
        call    dec2
        ld      a,(tmp1)
        add     a,2
        cp      24
        jr      c,tt8
        sub     24
tt8:    ld      (tmp1),a
        ld      a,(pidx)
        inc     a
        ld      (pidx),a
        cp      12
        jr      c,tt7
        ; the next waters
        call    evnext
        ld      b,18
        ld      c,3
        call    gotoxy
        ld      hl,t_nxt
        call    puts
        ld      a,19
        ld      (rowi),a
tt9:    ld      a,(rowi)
        ld      b,a
        ld      c,5
        call    gotoxy
        ld      a,(ev_ty)
        or      a
        ld      hl,t_hwl
        jr      z,tt10
        ld      hl,t_lwl
tt10:   call    puts
        ld      hl,(mdnow)
        ld      de,(ev_t)
        add     hl,de
        ld      de,1440
        ld      c,0
tt11:   or      a
        sbc     hl,de
        jr      c,tt12
        inc     c
        jr      tt11
tt12:   add     hl,de
        push    bc
        call    ptime
        ld      b,2
        call    spaces
        pop     bc
        ld      a,c
        or      a
        ld      hl,t_today
        jr      z,tt13
        dec     a
        ld      hl,t_tomorrow
        jr      z,tt13
        ld      hl,t_later
tt13:   call    puts
        ld      a,(ev_ty)       ; the next one is 372 (after high) or 373 minutes on
        or      a
        ld      de,LOWMIN
        jr      z,tt15
        inc     de
tt15:   ld      hl,(ev_t)
        add     hl,de
        ld      (ev_t),hl
        ld      a,(ev_ty)
        xor     1
        ld      (ev_ty),a
        ld      a,(rowi)
        inc     a
        ld      (rowi),a
        cp      23
        jr      c,tt9
        jp      pressakey

; the journal
jrnlscr: call   banner
        ld      b,4
        ld      hl,t_jt
        call    block
        xor     a
        ld      (pidx),a
jr1:    ld      a,(pidx)
        call    jent
        jr      c,jr2
        push    hl
        ld      a,(pidx)
        add     a,7
        ld      b,a
        ld      c,3
        call    gotoxy
        pop     hl
        push    hl
        call    jwhen
        pop     hl
        push    hl
        ld      a,(pidx)
        add     a,7
        ld      b,a
        ld      c,18
        call    gotoxy
        pop     hl
        call    jprint
        ld      a,(pidx)
        inc     a
        ld      (pidx),a
        cp      16
        jr      c,jr1
        jp      pressakey
jr2:    ld      a,(pidx)
        or      a
        jp      nz,pressakey
        ld      b,7
        ld      hl,t_nothing
        call    block
        jp      pressakey

; ---------------------------------------------------------------- input
; toggle: the cairn on the chosen rock
toggle: call    selix
        ld      a,(ix+R_MARK)
        or      a
        jr      nz,tg_off
        call    countmarks
        cp      NSTONES
        jr      nc,tg_full
        call    selix
        ld      (ix+R_MARK),1
        jr      tg_done
tg_off: ld      (ix+R_MARK),0
tg_done: call   save
        jp      drawlow
tg_full: ld     hl,t_full
        jp      msg

; drawlow: the parts of the screen a choice changes
drawlow: call   drawstrip
        call    drawpane
        jp      drawlatest

; namerock: type a new name
namerock: ld    b,23
        ld      c,2
        call    gotoxy
        call    eol
        ld      hl,t_nameq
        call    puts
        call    curon
        ld      hl,namebuf
        ld      de,namebuf+1
        ld      bc,7
        ld      (hl),0
        ldir
        ld      hl,namebuf
        ld      c,0
nm1:    call    getkey
        cp      13
        jr      z,nm_done
        cp      27
        jr      z,nm_abort
        cp      8
        jr      z,nm_bs
        cp      127
        jr      z,nm_bs
        cp      32
        jr      c,nm1
        cp      127
        jr      nc,nm1
        ld      b,a
        ld      a,c
        cp      NAMELEN
        jr      nc,nm1
        ld      a,b
        ld      (hl),a
        inc     hl
        inc     c
        call    putc
        jr      nm1
nm_bs:  ld      a,c
        or      a
        jr      z,nm1
        dec     c
        dec     hl
        ld      (hl),0
        ld      a,8
        call    putc
        ld      a,' '
        call    putc
        ld      a,8
        call    putc
        jr      nm1
nm_done: ld     a,c
        or      a
        jr      z,nm_abort
        ld      a,(sel)
        call    rname
        ex      de,hl
        ld      hl,namebuf
        ld      bc,8
        ldir
        call    save
nm_abort: call  curoff
        jp      drawlow
