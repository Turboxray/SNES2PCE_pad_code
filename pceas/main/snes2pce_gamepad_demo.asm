;     SNES Pad reading routine demo
;
;    {Assemble with PCEAS: ver 3.23 or higher}
;
;   Turboxray '21
;



;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;..............................................................................................................

    list
    mlist

;..................................................
;                                                 .
;  Logical Memory Map:                            .
;                                                 .
;            $0000 = Hardware bank                .
;            $2000 = Sys Ram                      .
;            $4000 = Subcode                      .
;            $6000 = Data 0 / Cont. of Subcode    .
;            $8000 = Data 1                       .
;            $A000 = Data 2                       .
;            $C000 = Main                         .
;            $E000 = Fixed Libray                 .
;                                                 .
;..................................................


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;//  Vars

    .include "../base_func/vars.inc"
    .include "../base_func/video/vdc/vars.inc"
    .include "../lib/SnesPad/vars.inc"
    .include "../base_func/IO/irq_controller/vars.inc"
    .include "../base_func/IO/mapper/mapper.inc"

;....................................
    .code

    .bank $00, "Fixed Lib/Start up"
    .org $e000
;....................................

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Support files: equates and macros
    .include "../base_func/base.inc"
    .include "../base_func/video/video.inc"
    .include "../base_func/video/vdc/vdc.inc"
    .include "../base_func/video/vce/vce.inc"
    .include "../lib/SnesPad/snespad.inc"
    .include "../base_func/timer/timer.inc"
    .include "../base_func/IO/irq_controller/irq.inc"


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Startup and fix lib @$E000

startup:
        ;................................
        ;Main initialization routine.
        InitialStartup
        CallFarWide init_audio
        CallFarWide init_video

        stz $2000
        stz $2001
        stz $2002
        tii $2000,$2001,$2000

        ;................................
        ;Set video parameters
        VCE.reg MID_RES|H_FILTER_ON
        VDC.reg HSR  , #$0404
        VDC.reg HDR  , #$0629
        VDC.reg VSR  , #$0F02
        VDC.reg VDR  , #$00ef
        VDC.reg VDE  , #$0003
        VDC.reg DCR  , #AUTO_SATB_ON
        VDC.reg CR   , #$0000
        VDC.reg SATB , #$7F00
        VDC.reg MWR  , #SCR64_64

        IRQ.control IRQ2_ON|VIRQ_ON|TIRQ_OFF

        TIMER.port  _7.00khz
        TIMER.cmd   TMR_OFF

        MAP_BANK #MAIN, MPR6
        jmp MAIN

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Data / fixed bank


;Stuff for printing on screen
    .include "../base_func/video/print/lib.asm"

;other basic functions
    .include "../base_func/video/vdc/lib.asm"
    .include "../lib/SnesPad/lib.asm"

;end DATA
;//...................................................................

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Interrupt routines

;//........
TIRQ.custom
    jmp [timer_vect]

TIRQ:   ;// Not used
        BBS2 <vector_mask, TIRQ.custom
        stz $1403
        rti

;//........
BRK.custom
    jmp [brk_vect]
BRK:
        BBS1 <vector_mask, BRK.custom
        rti

VDC:
          pha
        lda IRQ.ackVDC
        sta <vdc_status
        bit #$20
        bne VDC.vsync
VDC.hsync


VDC.vsync
        lda <vdc_reg
        sta $0000
        pla
      stz __vblank
  rti

;//........
NMI:
        rti

;end INT

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// INT VECTORS

  .org $fff6

    .dw BRK
    .dw VDC
    .dw TIRQ
    .dw NMI
    .dw startup

;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;Bank 0 end





;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Main code bank @ $C000

;....................................
    .bank $01, "MAIN"
    .org $c000
;....................................


MAIN:

        ;................................
        ;Turn display on
        VDC.reg CR , #(BG_ON|SPR_ON|VINT_ON|HINT_ON)

        ;................................
        ;Load font
        loadCellToVram Font, $1000
        loadCellToCram.BG Font, 0


        ;................................
        ;Clear map
        jsr ClearScreen.64x32


        ;...............................
        ; TIRQ is already enabled, but TIMER needs to be as well
        TIMER.port  _7.00khz
        TIMER.cmd   TMR_OFF
        IRQ.control IRQ2_ON|VIRQ_ON|TIRQ_OFF

        ;................................
        ;start the party
        Interrupts.enable


        WAITVBLANK 10


main_loop:
        WAITVBLANK
      
        call SnesPad.READ_IO

        PRINT_STR_i "SNES PAD Demo",14,2

        PRINT_STR_i "[PAD 0] ",1,5
        PRINT_STR_i "Left, Down, Right, Up        : ",3,7
        PrintHiNybbleBits_a_q snes_pad_0_pack.lsb
        PRINT_STR_i "Start, Select, Y, B          : ",3,8
        PrintLoNybbleBits_a_q snes_pad_0_pack.lsb
        PRINT_STR_i "R-Shoulder, L-Shoulder, X, A : ",3,9
        PrintLoNybbleBits_a_q snes_pad_0_pack.msb
        PRINT_STR_i "ID                           : ",3,10
        PrintHiNybbleBits_a_q snes_pad_0_pack.msb

        PRINT_STR_i "[PAD 0] ",1,12
        PRINT_STR_i "Left, Down, Right, Up        : ",3,14
        PrintHiNybbleBits_a_q snes_pad_1_pack.lsb
        PRINT_STR_i "Start, Select, Y, B          : ",3,15
        PrintLoNybbleBits_a_q snes_pad_1_pack.lsb
        PRINT_STR_i "R-Shoulder, L-Shoulder, X, A : ",3,16
        PrintLoNybbleBits_a_q snes_pad_1_pack.msb
        PRINT_STR_i "ID                           : ",3,17
        PrintHiNybbleBits_a_q snes_pad_1_pack.msb


        PRINT_STR_i "Press I/II or any SNES btn for detection ",1,21

        jsr PadDetect        


      jmp main_loop



;Main end
;//...................................................................
;//...................................................................
;//...................................................................
;//...................................................................
;//...................................................................
;//...................................................................
;//...................................................................
;//...................................................................
;//...................................................................
;//...................................................................

PadDetect:

        PRINT_STR_i "                        ",2,23

.firstCheck
        lda snes_pad_0_pack.msb
        and #$F0
        cmp #$F0
    bne .foundPCEpad
        lda snes_pad_1_pack.msb
        and #$F0
        cmp #$F0
    bne .foundPCEpad


.checkPad_1
        lda snes_pad_0_pack.msb
        cmp snes_pad_0_pack.lsb
    beq .checkPad_2

        PRINT_STR_i " SNES pad detected",2,23
  rts

.foundPCEpad
        PRINT_STR_i " PC-Engine pad detected",2,23
  rts



.checkPad_2
        lda snes_pad_1_pack.msb
        cmp snes_pad_1_pack.lsb
    beq .out
        PRINT_STR_i " SNES pad detected",2,23
.out
  rts

Nybble.LUT
    .db $00, $01, $10, $11

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;

;....................................
    .code
    .bank $02, "Subcode 1"
    .org $8000
;....................................

  IncludeBinary Font.cell, "../base_func/video/print/font.dat"

Font.pal: .db $00,$00,$33,$01,$ff,$01,$ff,$01,$ff,$01,$ff,$01,$ff,$01,$f6,$01
Font.pal.size = sizeof(Font.pal)

    ;// Support files for MAIN

;...................................
init_audio
                ldx #$05
.loop
                stx $800
                stz $801
                stz $802
                stz $803
                stz $804
                stz $805
                stz $806
                stz $807
                stz $808
                stz $809
                dex
            bpl .loop
    rts

;...................................
init_video

                clx
                ldy #$80
                st0 #$00
                st1 #$00
                st2 #$00
                st0 #$02

.loop
                st1 #$00
                st2 #$00
                dex
            bne .loop
                dey
            bne .loop

                clx
                stz $402
                stz $403
.loop1
                stz $404
                stz $405
                inx
            bne .loop1

    rts





;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;



