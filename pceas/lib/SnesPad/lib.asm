
jport = $1000

S_LATCH_HI = $01                ; SEL (D0)
S_LATCH_LO = $00
CLOCK_HI   = $02                ; CLR (D1)
CLOCK_LO   = $00


SnesPad.READ_IO:

    ;O Port. D0 drive the latch (SEL), D1 drives the clock (CLR).
    ;K Port: D0 = serial bit PAD 0. D1 = serial bit PAD 1. D2 = 1 and D3 = 1.

    ldx #15

    lda #(S_LATCH_LO | CLOCK_HI)                
    sta jport               ; (CLR = 1, SEL = 1) set latch High to get sample inputs. Keep clock high

    lda #(S_LATCH_HI | CLOCK_HI)                
    sta jport               ; (CLR = 1, SEL = 1) set latch High to get sample inputs. Keep clock high

    lda #(S_LATCH_LO | CLOCK_HI)
    stz jport               ; (CLR = 1, SEL = 0) set latch low to lock input states. Keep clock high

.loop

    lda #(S_LATCH_LO | CLOCK_LO)
    sta jport               ; (CLR = 0) clock low.. get data bit               
    lda jport
    lsr a
    ror snes_pad_0_pack.msb
    ror snes_pad_0_pack.lsb
    lsr a
    ror snes_pad_1_pack.msb
    ror snes_pad_1_pack.lsb

    lda #(S_LATCH_LO | CLOCK_HI)
    sta jport               ; (CLR = 1) clock high

    dex
  bpl .loop


    ; Remap the directional stuff so that it aligns with PCE directional layout.
    lda snes_pad_0_pack.lsb
    tax
    and #$1f
    ora #$E0
    sta snes_pad_0_pack.lsb
    txa
    and #$20                ; downm
    bne .skip0
    lda #$40
    trb snes_pad_0_pack.lsb
.skip0
    txa
    and #$40                ;left
    bne .skip1
    lda #$80
    trb snes_pad_0_pack.lsb
.skip1
    txa
    and #$80                ; up
    bne .skip2
    lda #$20
    trb snes_pad_0_pack.lsb
.skip2

 rts
