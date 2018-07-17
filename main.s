;;; -*- mode: asm -*-

    .include "defs.s"
    .include "init.h"
    .include "ppu.h"

;;; ==========================
;;;
;;;   Global Variables
;;;
;;; ==========================

    OAM_BUF       = $0200

    .define OAMB_X(index) OAM_X OAM_BUF, index
    .define OAMB_Y(index) OAM_Y OAM_BUF, index

    ETP           = $00f0

    FRAME_READY   = $0300
    GAMEPAD1      = $0301
    GAMEPAD2      = $0302
    MARIO_Y       = $0303
    MARIO_X       = $0304
    MARIO_ENTITY  = $0305
    MARIO_VEL_X   = $0306
    MARIO_VEL_Y   = $0307

    .code

;;; ==========================
;;;
;;;   Constants
;;;
;;; ==========================

SpritePalette:
    .incbin "res/test.pal"

MarioSprite:
MarioSpriteRight:
    .byte $32, $00, $33, $00, $34, $00, $35, $00
MarioSpriteLeft:
    .byte $33, $40, $32, $40, $35, $40, $34, $40

;;; =========================
;;;
;;;   RESET
;;;
;;; =========================

    .proc reset
    init_nes

    ld_Palette SpritePalette

    ;; Initialize Mario Game Data
    ldx #$00
    stx MARIO_ENTITY
    ldx #$80
    stx MARIO_Y
    stx MARIO_X
    ldx #$00
    stx MARIO_VEL_X
    stx MARIO_VEL_Y

    ;; Initialize PPU
    lda #%10000000              ; Enable nmi, sprites from table 0
    sta PPU_CTRL
    lda #%00010000              ; Enable sprites
    sta PPU_MASK

GameLoop:
    jsr update_mario_oamb
    jsr read_gamepads

;;; Update Marios position

    lda GAMEPAD1
    and #GAMEPAD_LEFT
    beq GamepadRight
    ;; Left pushed -> set direction, decrease velocity if > -3
    lda #$08
    sta MARIO_ENTITY            ; #$08 == MARIO_ENTITY_LEFT
    lda MARIO_VEL_X
    cmp #$fd
    beq GamepadEnd              ; Left and Max Speed (-3) -> End
    sec                         ; Else decrease by one
    sbc #$01
    sta MARIO_VEL_X
    jmp GamepadEnd              ; Done -> End
GamepadRight:
    lda GAMEPAD1
    and #GAMEPAD_RIGHT
    beq GamepadNone
    ;; Right pushed -> set direction, increase velocity
    lda #$00
    sta MARIO_ENTITY            ; #$00 == MARIO_ENTITY_RIGHT
    lda MARIO_VEL_X
    cmp #$03
    beq GamepadEnd              ; Right and Max Speed (+3) -> End
    clc                         ; Else increase by one
    adc #$1
    sta MARIO_VEL_X
    jmp GamepadEnd
GamepadNone:
    lda MARIO_VEL_X
    beq GamepadEnd              ; Zero do nothing
    cmp #$04
    bcc :+
    clc                         ; Negative (< 0)
    adc #$01
    sta MARIO_VEL_X
    jmp GamepadEnd
:   sec                         ; Positive (< 4)
    sbc #$01
    sta MARIO_VEL_X

GamepadEnd:
    ;; Add Velocity to Position
    lda MARIO_X
    clc
    adc MARIO_VEL_X
    sta MARIO_X

;;; Signal we may update frame and wait for NMI

    lda #$01
    sta FRAME_READY

:   lda FRAME_READY
    beq GameLoop
    jmp :-

    .endproc

;;; ====================================================
;;;
;;;    load_entity
;;;
;;; Load an entity (table of sprite indices
;;; /attributes) from pointer ETP.
;;;
;;; [ETP]   ZP Pointer to base of entity-table
;;; Y       Offset in entity-table to correct
;;;         sprite set
;;;
;;; ====================================================

    .proc load_entity
    ldx #$01
:   lda (ETP), y      ; Copy Object Index
    sta OAM_BUF, x
    iny
    inx
    lda (ETP), y      ; Copy Object Attributes
    sta OAM_BUF, x
    iny
    txa
    clc
    adc #$03
    tax
    cpy #$08                    ; TODO doesnt work, how to check for end of iteration?!
    bne :-
    rts
    .endproc

;;; =====================================================
;;;
;;;    update_mario_oamb
;;;
;;; =====================================================

    .proc update_mario_oamb
    ;; Update Marios sprite data from entity table
    lda #<MarioSprite
    sta ETP
    lda #>MarioSprite
    sta ETP + 1
    ldy MARIO_ENTITY
    jsr load_entity

    ;; Update vertical position
    lda MARIO_Y
    sta OAMB_Y $0
    sta OAMB_Y $1
    clc
    adc #$08
    sta OAMB_Y $2
    sta OAMB_Y $3
    ;; Update horizontal position
    lda MARIO_X
    sta OAMB_X $0
    sta OAMB_X $2
    clc
    adc #$08
    sta OAMB_X $1
    sta OAMB_X $3
    rts
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
;;;    Vectors & CHR ROM
;;;
;;; =========================

    .segment "VECTOR"
    .addr nmi
    .addr reset
    .addr irq

    .segment "CHR0"
    .incbin "res/mario.chr"
