;;; -*- mode: asm -*-

    .include "defs.s"
    .include "init.h"
    .include "ppu.h"

SpritePalette:
    .incbin "res/test.pal"

    .code

;;; =========================
;;;
;;;   RESET
;;;
;;; =========================

    .proc reset
    init_nes

    ld_SpritePalette SpritePalette

    ;; Setup Sprite Table
    lda #$20
    sta $0200                   ; Set vertical position for sprite 0
    sta $0203                   ; Set horizontal position for sprite 0
    lda #$00
    sta $0201                   ; Tile = 0
    lda #$02
    sta $0202                   ; Color = 0, no flipping

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
    lda #$00
    sta OAMADDR
    lda #$02
    sta $4014
    rti
    .endproc

    .proc irq
    rti
    .endproc

    .segment "VECTOR"
    .addr nmi
    .addr reset
    .addr irq

    .segment "CHR0"
    .incbin "res/mario.chr"
