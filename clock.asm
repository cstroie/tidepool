; clock.asm: the date and time, the arithmetic it needs, and the tide.
;
; DigitalRerun has a clock device on port 20: OUT latches a record, 15 INs read it. Bytes 1-2
; are the days since 31 Dec 1977, 3-5 hour, minute, second in BCD. The pool lives on one number,
; M, the minutes since that day: days*1440 + minute of the day. A tide takes 745 minutes (12 h
; 25 min), so the tide count is M/745 and where we are in the tide is M mod 745: 0 is high
; water, 372 is low. Without the device (a real Z80, another emulator) the pool counts one tide
; for every visit and does not move while you watch.

CLKPORT equ     20
TIDE    equ     745
LOWMIN     equ     372             ; the minute of low water in a tide

; gettime: reads the clock. Sets mnow (32 bits), cnow (the tide count), pnow (minute within
; the tide), daynow (days since 1978) and mdnow (minute of the day); hasclk.
gettime: out    (CLKPORT),a
        ld      hl,clkbuf
        ld      b,15
gt1:    in      a,(CLKPORT)
        ld      (hl),a
        inc     hl
        djnz    gt1
        ld      a,(clkbuf)
        cp      1
        jr      nz,gt_no
        ld      a,1
        ld      (hasclk),a
        ld      hl,(clkbuf+1)
        ld      de,1440
        call    mul32
        ld      a,(clkbuf+3)
        call    bcd2bin
        ld      b,a
        ld      hl,0
        ld      de,60
        inc     b
        jr      gt3
gt2:    add     hl,de
gt3:    djnz    gt2
        ld      a,(clkbuf+4)
        call    bcd2bin
        ld      e,a
        ld      d,0
        add     hl,de
        ld      de,(m32)
        add     hl,de
        ld      (m32),hl
        jr      nc,gt4
        ld      hl,(m32+2)
        inc     hl
        ld      (m32+2),hl
        jr      gt4
gt_no:  xor     a               ; no clock: one tide after the last visit
        ld      (hasclk),a
        ld      hl,(st_seen)
        ld      de,TIDE
        add     hl,de
        ld      (m32),hl
        ld      hl,(st_seen+2)
        jr      nc,gt5
        inc     hl
gt5:    ld      (m32+2),hl
gt4:    ld      hl,(m32)
        ld      (mnow),hl
        ld      hl,(m32+2)
        ld      (mnow+2),hl
        ld      de,TIDE
        call    div32
        ld      (pnow),hl
        ld      hl,(m32)
        ld      (cnow),hl
        ld      hl,(mnow)
        ld      (m32),hl
        ld      hl,(mnow+2)
        ld      (m32+2),hl
        ld      de,1440
        call    div32
        ld      (mdnow),hl
        ld      hl,(m32)
        ld      (daynow),hl
        ret

bcd2bin: ld     c,a
        and     0f0h
        rrca
        rrca
        rrca
        rrca
        ld      b,a
        add     a,a
        add     a,a
        add     a,b
        add     a,a
        ld      b,a
        ld      a,c
        and     0fh
        add     a,b
        ret

; mul32: HL x DE -> m32 (32 bits, little endian)
mul32:  ld      (mA),hl
        ld      hl,0
        ld      (mA+2),hl
        ld      (m32),hl
        ld      (m32+2),hl
        ex      de,hl
        ld      b,16
mm1:    srl     h
        rr      l
        jr      nc,mm2
        push    hl
        ld      hl,(m32)
        ld      de,(mA)
        add     hl,de
        ld      (m32),hl
        ld      hl,(m32+2)
        ld      de,(mA+2)
        adc     hl,de
        ld      (m32+2),hl
        pop     hl
mm2:    push    hl
        ld      hl,(mA)
        add     hl,hl
        ld      (mA),hl
        ld      hl,(mA+2)
        adc     hl,hl
        ld      (mA+2),hl
        pop     hl
        djnz    mm1
        ret

; div32: m32 / DE -> m32 (the quotient), HL = the remainder. DE up to 2000 or so.
div32:  ld      hl,0
        ld      b,32
dv1:    push    hl
        ld      hl,(m32)
        add     hl,hl
        ld      (m32),hl
        ld      hl,(m32+2)
        adc     hl,hl
        ld      (m32+2),hl
        pop     hl
        adc     hl,hl
        or      a
        sbc     hl,de
        jr      nc,dv2
        add     hl,de
        jr      dv3
dv2:    push    hl
        ld      hl,m32
        inc     (hl)            ; bit 0 is clear after the shift
        pop     hl
dv3:    djnz    dv1
        ret

; cyc2days: HL tides -> HL days (tides x 745 / 1440)
cyc2days: ld    de,TIDE
        call    mul32
        ld      de,1440
        call    div32
        ld      hl,(m32)
        ret

; level: HL = minute within the tide -> A = the water, 0 (low) to 15 (high)
level:  ld      de,LOWMIN+1
        or      a
        sbc     hl,de           ; p - 373
        jr      c,lv1
        ex      de,hl           ; DE = p - 373: past low water, d = 372 - (p - 373)
        ld      hl,LOWMIN
        or      a
        sbc     hl,de
        jr      lv2
lv1:    add     hl,de           ; HL = p, d = p
lv2:    ld      de,24           ; one step of the gauge is 24 minutes
        ld      b,15
lv3:    or      a
        sbc     hl,de
        jr      c,lv4
        dec     b
        jr      z,lv4
        jr      lv3
lv4:    ld      a,b
        ret

; evnext: the next high or low water. ev_t = minutes from now, ev_ty = 0 high, 1 low
evnext: ld      hl,(pnow)
        ld      a,h
        or      l
        jr      nz,en1
        ld      (ev_t),hl
        xor     a
        ld      (ev_ty),a
        ret
en1:    ld      de,LOWMIN
        or      a
        sbc     hl,de           ; p - 372
        jr      c,en2
        jr      nz,en3
        ld      (ev_t),hl       ; low water now
        ld      a,1
        ld      (ev_ty),a
        ret
en3:    ex      de,hl           ; past low: high water in 373 - (p - 372)
        ld      hl,LOWMIN+1
        or      a
        sbc     hl,de
        ld      (ev_t),hl
        xor     a
        ld      (ev_ty),a
        ret
en2:    ex      de,hl           ; before low: low water in 372 - p
        ld      hl,0
        or      a
        sbc     hl,de
        ld      (ev_t),hl
        ld      a,1
        ld      (ev_ty),a
        ret

; delay: a pause of about 100 ms at 4 MHz
DLY_OUT equ     110
delay:  ld      c,DLY_OUT
dly1:   ld      b,0
dly2:   djnz    dly2
        dec     c
        jr      nz,dly1
        ret
