;;; -*- mode: asm -*-

    .include "defs.s"

    .ifndef __INIT_H__
    __INIT_H__ = 1

    .macro init_nes
    sei                         ; Disable interrupts
    cld                         ; Clear decimal mode

    ldx #$ff                    ; Initialize Stack
    txs

    inx
    stx PPU_CTRL                ; Disable NMI
    stx PPU_MASK                ; Disable Rendering
    stx DMC_IRQ                 ; Disable DMC IRQs

    ;; Need to wait three VBLANKs til PPU is ready
    ;; see http://forums.nesdev.com/viewtopic.php?f=2&t=3958
:   bit PPU_STAT               ; Wait for VBLANK
    bpl :-
:   bit PPU_STAT
    bpl :-

    ;; Clear Memory
:   lda #$00
    sta $0000, x
    sta $0100, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    lda #$fe                    ; Move sprites off screen
    sta $0200, x
    inx
    bne :-

    ;; Wait for third vblank
:   bit PPU_STAT
    bpl :-
    .endmacro

    .endif
