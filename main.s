;;; -*- mode: asm -*-

    OAM_BUF = $0200

    .include "defs.s"
    .include "init.h"
    .include "ppu.h"

;;; ==========================
;;;
;;;   Global Variables
;;;
;;; ==========================

    MARIO_Y = $0300
    MARIO_X = $0301

    .code

;;; ==========================
;;;
;;;   Constants
;;;
;;; ==========================

SpritePalette:
    .incbin "res/test.pal"

MarioSprite:
    .byte $00, $32, $00, $00,   $00, $33, $00, $08
    .byte $08, $34, $00, $00,   $08, $35, $00, $08

;;; =========================
;;;
;;;   RESET
;;;
;;; =========================

    .proc reset
    init_nes

    ld_Palette SpritePalette

    ;; Setup Sprite Table
    ldx #$00
:   lda MarioSprite, x
    sta OAM_BUF, x
    inx
    cpx #$10
    bne :-

    ;; Mario's Initial Position
    ldx #$80
    stx MARIO_Y
    stx MARIO_X

    ;; Initialize PPU
    lda #%10000000              ; Enable nmi, sprites from table 0
    sta PPU_CTRL
    lda #%00010000              ; Enable sprites
    sta PPU_MASK

forever:
    jmp forever

    .endproc

;;; ============================
;;;
;;;   NMI
;;;
;;; ============================

    .proc nmi

;;; Update Mario

    ;; Update vertical position
    lda MARIO_Y
    sta OAM_BUF
    sta OAM_BUF + $04
    adc #$08
    sta OAM_BUF + $08
    sta OAM_BUF + $0c
    ;; Update horizontal position
    lda MARIO_X
    sta OAM_BUF + $03
    sta OAM_BUF + $0b
    adc #$08
    sta OAM_BUF + $07
    sta OAM_BUF + $0f

;;; Transfer Sprite Table

    lda #<OAM_BUF
    sta OAM_ADDR
    lda #>OAM_BUF
    sta OAM_DMA

    rti
    .endproc

    .proc irq
    rti
    .endproc

;;; ========================
;;;
;;;    Vectors & ROM
;;;
;;; =========================

    .segment "VECTOR"
    .addr nmi
    .addr reset
    .addr irq

    .segment "CHR0"
    .incbin "res/mario.chr"
