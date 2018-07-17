;;; -*- mode: asm -*-

    .ifndef __PPU_H__
    __PPU_H__ = 1

    .include "defs.s"

    .define OAM_Y(base, index) base + index * $4
    .define OAM_X(base, index) base + index * $4 + $3

    .macro init_ppu_addr addr
    lda PPU_STAT
    lda #>addr
    sta PPU_ADDR
    lda #<addr
    sta PPU_ADDR
    .endmacro

    ;; Loop over 32 bytes of palette data from X, writing to PPU
    .macro copy_palette palette
    ldx #$00
:   lda palette, x
    sta PPU_DATA
    inx
    cpx #$20
    bne :-
    .endmacro

;;; ===============================================
;;;
;;;    ld_Palette
;;;
;;; ===============================================

    .macro ld_Palette palette
    ;; Initialize PPU Write Address to $3f10
    ;; Load $20 bytes of palette data
    init_ppu_addr PPU_ADDR_PALETTE
    copy_palette palette
    .endmacro

    .endif
