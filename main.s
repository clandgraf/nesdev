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

    FRAME_READY   = $0300
    MARIO_Y       = $0301
    MARIO_X       = $0302
    MARIO_VEL_X   = $0303
    MARIO_VEL_Y   = $0304
    GAMEPAD1      = $0305
    GAMEPAD2      = $0306

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

GameLoop:
    jsr read_gamepads

;;; Update Marios position

    lda GAMEPAD1
    and #GAMEPAD_LEFT
    beq :+
    ;; Left pushed
    ldx MARIO_X
    dex
    stx MARIO_X
    jmp :++                     ; Skip Right Button
:
    lda GAMEPAD1
    and #GAMEPAD_RIGHT
    beq :+
    ;; Right pushed
    ldx MARIO_X
    inx
    stx MARIO_X
:

;;; Update Marios Sprite

GameLoop_Sprites:

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

;;; Signal we may update frame and wait for NMI

    lda #$01
    sta FRAME_READY

:   lda FRAME_READY
    beq GameLoop
    jmp :-

    .endproc

    .proc read_gamepads
    read_gamepad GAMEPAD1_REG, GAMEPAD1
    read_gamepad GAMEPAD2_REG, GAMEPAD2
    rts
    .endproc

;;; ============================
;;;
;;;   NMI
;;;
;;; ============================

    .proc nmi

    push_regs

;;; Skip PPU Code if frame not ready

    lda FRAME_READY
    beq ReturnNMI

;;; Transfer Sprite Table

    lda #<OAM_BUF
    sta OAM_ADDR
    lda #>OAM_BUF
    sta OAM_DMA

ReturnNMI:
    lda #$00
    sta FRAME_READY

    pull_regs

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
