;;; -*- mode: asm -*-

    .include "defs.s"
    .include "init.h"
    .include "ppu.h"
    .include "nmi.h"

;;; ==========================
;;;
;;;   Global Variables
;;;
;;; ==========================

    OAM_BUF         = $0200

    .define OAMB_X(index) OAM_X OAM_BUF, index
    .define OAMB_Y(index) OAM_Y OAM_BUF, index

    ETP             = $00f0

    FRAME_READY     = $0300
    GAMEPAD1        = $0301
    GAMEPAD2        = $0302

    MARIO_Y         = $0303
    MARIO_Y_LO      = $0303
    MARIO_Y_HI      = $0304
    MARIO_X         = $0305
    MARIO_X_LO      = $0305
    MARIO_X_HI      = $0306
    MARIO_VEL_X     = $0307
    MARIO_VEL_X_LO  = $0307
    MARIO_VEL_X_HI  = $0308
    MARIO_VEL_Y     = $0309
    MARIO_VEL_Y_LO  = $0309
    MARIO_VEL_Y_HI  = $0310
    MARIO_ENTITY    = $0311
    MARIO_DIR       = $0312
    MARIO_DIR_LEFT  = $00
    MARIO_DIR_RIGHT = $01

    MARIO_RUN_TIM  = $0313     ; PPU frames per animation frame
    MARIO_RUN_TIC  = $f0
    MARIO_RUN_FRM  = $0314     ; Current animation frame
    MARIO_RUN_FRC  = $04

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
MarioSpriteStandRight:
    .byte $3a, $00, $37, $00, $3b, $00, $3c, $00
MarioSpriteRunRight:
    .byte $32, $00, $33, $00, $34, $00, $35, $00
MarioSpriteLeft:
MarioSpriteStandLeft:
    .byte $37, $40, $3a, $40, $3c, $40, $3b, $40
MarioSpriteRunLeft:
    .byte $33, $40, $32, $40, $35, $40, $34, $40

MarioAnimRight:
    .byte MarioSpriteStandRight - MarioSprite
    .byte MarioSpriteStandRight - MarioSprite
    .byte MarioSpriteRunRight   - MarioSprite
    .byte MarioSpriteStandRight - MarioSprite
    .byte MarioSpriteRunRight   - MarioSprite
MarioAnimLeft:
    .byte MarioSpriteStandLeft  - MarioSprite
    .byte MarioSpriteStandLeft  - MarioSprite
    .byte MarioSpriteRunLeft    - MarioSprite
    .byte MarioSpriteStandLeft  - MarioSprite
    .byte MarioSpriteRunLeft    - MarioSprite

;;; ldx MARIO_RUN_FRM
;;; ldy MarioAnimRunRight, X ; Y now contains offset relative MarioSprite

MARIO_OFF_STAND_RIGHT = MarioSpriteStandRight - MarioSprite
MARIO_OFF_STAND_LEFT  = MarioSpriteStandLeft - MarioSprite
MARIO_OFF_RUN_RIGHT   = MarioSpriteRunRight - MarioSprite
MARIO_OFF_RUN_LEFT    = MarioSpriteRunLeft - MarioSprite


;;; ====================================================
;;;
;;;    load_entity
;;;
;;; Load an entity (table of sprite indices
;;; /attributes) from pointer ETP.
;;;
;;; [ETP]   ZP Pointer to base of entity-table,
;;;         followed by length of arrary in bytes.
;;; Y       Offset in entity-table to correct
;;;         sprite set
;;;
;;; ====================================================

    .proc load_entity
    tya               ; Setup cancel in ETP + 2 (offset + length)
    clc
    adc ETP + $2
    sta ETP + $2
    ldx #$01          ; Iteration starts at 1 (skip position)
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
    cpy ETP + $2
    bne :-
    rts
    .endproc

    .macro tick_anim timer_ptr, timer_cnt, frame_ptr, frame_cnt
    dec timer_ptr
    bne :+
    lda #timer_cnt
    sta timer_ptr
    dec frame_ptr
    bne :+
    lda #frame_cnt
    sta frame_ptr
:   .endmacro

    .macro reset_anim timer_ptr, frame_ptr
    lda #$00
    sta timer_ptr
    lda #$00
    sta frame_ptr
    .endmacro

    .macro load_anim frame_ptr, etp_base, etp_offset_table
    ;; Write ETP
    lda #<etp_base
    sta ETP
    lda #>etp_base
    sta ETP + 1
    lda #$08
    sta ETP + 2
    ;; Load ETP Offset from animation frame ptr
    ldx frame_ptr
    ldy etp_offset_table, X
    jsr load_entity
    .endmacro

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
    stx MARIO_DIR
    ldx #$80
    stx MARIO_Y
    stx MARIO_X
    ldx #$00
    stx MARIO_VEL_X
    stx MARIO_VEL_Y
    reset_anim MARIO_RUN_TIM, MARIO_RUN_FRM

    ;; Initialize PPU
    lda #%10000000              ; Enable nmi, sprites from table 0
    sta PPU_CTRL
    lda #%00010000              ; Enable sprites
    sta PPU_MASK

GameLoop:
    jsr update_mario_oamb
    jsr read_gamepads
    jsr update_mario_physics
    wait_for_nmi FRAME_READY
    jmp GameLoop

    .endproc

;;; ==========================================================
;;;
;;;    update_mario_physics
;;;
;;;  Use gamepad data to update marios position, velocity,
;;;  direction and entity data
;;;
;;; ===========================================================

    .proc update_mario_physics
    lda GAMEPAD1
    and #GAMEPAD_LEFT
    beq GamepadRight
    ;; Left pushed -> set direction, decrease velocity if > -3
    tick_anim MARIO_RUN_TIM, MARIO_RUN_TIC, MARIO_RUN_FRM, MARIO_RUN_FRC
    lda MARIO_VEL_X_HI
    cmp #$fd
    beq GamepadEnd              ; Left and Max Speed (-3) -> End
    sec                         ; Else decrease by one
    sbc #$01
    sta MARIO_VEL_X_HI
    jmp GamepadEnd              ; Done -> End
GamepadRight:
    tick_anim MARIO_RUN_TIM, MARIO_RUN_TIC, MARIO_RUN_FRM, MARIO_RUN_FRC
    lda GAMEPAD1
    and #GAMEPAD_RIGHT
    beq GamepadNone
    ;; Right pushed -> set direction, increase velocity
    lda MARIO_VEL_X_HI
    cmp #$03
    beq GamepadEnd              ; Right and Max Speed (+3) -> End
    add16_i MARIO_VEL_X, $40    ; Else increase by one .25
    jmp GamepadEnd
GamepadNone:
    reset_anim MARIO_RUN_TIM, MARIO_RUN_FRM
    lda MARIO_VEL_X_LO
    bne :+
    lda MARIO_VEL_X_HI
    beq GamepadEnd              ; Zero do nothing
:   lda MARIO_VEL_X_HI
    cmp #$04                    ; Between 0 and 4?
    bcc :+                      ; Negative (> 4), slow down
    add16_i MARIO_VEL_X, $40
    jmp GamepadEnd
:   sub16_i MARIO_VEL_X, $40    ; Positive (< 4), slow down

GamepadEnd:
    ;; Set Mario's direction and his sprite
    lda MARIO_VEL_X_HI
    beq MarioStands             ; 0 == Mario Stands
    cmp #$04
    bcc :+
    lda #MARIO_DIR_LEFT         ; Mario goes left
    sta MARIO_DIR
    lda #MARIO_OFF_RUN_LEFT
    jmp MarioMove
:   lda #MARIO_DIR_RIGHT        ; Mario goes right
    sta MARIO_DIR
    lda #MARIO_OFF_RUN_RIGHT
    jmp MarioMove
MarioStands:
    lda MARIO_DIR               ; Set entity based on direction
    beq :+
    lda #MARIO_OFF_STAND_RIGHT  ; != 0 -> MARIO_DIR_RIGHT
    jmp MarioMove
:   lda #MARIO_OFF_STAND_LEFT   ; == 0 -> MARIO_DIR_LEFT
MarioMove:
    sta MARIO_ENTITY

    ;; Add Velocity to Position
    lda MARIO_X
    clc
    adc MARIO_VEL_X_HI
    sta MARIO_X
    rts
    .endproc

;;; =====================================================
;;;
;;;    update_mario_oamb
;;;
;;; =====================================================

    .proc update_mario_oamb
    ;; Update Marios sprite data from entity table
    ;; lda #<MarioSprite
    ;; sta ETP
    ;; lda #>MarioSprite
    ;; sta ETP + 1
    ;; lda #$08
    ;; sta ETP + 2
    ;; ldy MARIO_ENTITY
    ;; jsr load_entity
    lda MARIO_DIR
    beq :+
    load_anim MARIO_RUN_FRM, MarioSprite, MarioAnimRight
    jmp :++
:   load_anim MARIO_RUN_FRM, MarioSprite, MarioAnimLeft

    ;; Update vertical position
:   lda MARIO_Y
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
    start_nmi
    ;; Do non-ppu-related tasks here
    check_for_frame_nmi FRAME_READY

    lda #<OAM_BUF
    sta OAM_ADDR
    lda #>OAM_BUF
    sta OAM_DMA

    return_from_nmi FRAME_READY
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
