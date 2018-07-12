;;; -*- mode: asm -*-

    .ifndef __PPU_H__
    __PPU_H__ = 1

    .include "defs.s"

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
;;;    LoadSpritePalette
;;;
;;;      X - palette data array
;;;
;;; ===============================================

    .macro ld_SpritePalette palette
    ;; Initialize PPU Write Address to $3f10
    ;; Load $20 bytes of palette data
    init_ppu_addr PPU_ADDR_PAL_SPRITE
    copy_palette palette
    .endmacro

;;; ===============================================
;;;
;;;    LoadBackgroundPalette
;;;
;;;      X - palette data array
;;;
;;; ===============================================

    .macro ld_BackgroundPalette palette
    ;; Initialize PPU Write Address to $3f10
    ;; Load $20 bytes of palette data
    init_ppu_addr PPU_ADDR_PAL_BKG
    copy_palette palette
    .endmacro

    .endif
