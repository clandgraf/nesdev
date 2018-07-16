;;; -*- mode: asm -*-

    .ifndef __DEFS_H__
    __DEFS_H__ = 1

;;; General Macros

    .macro push_regs
    pha
    txa
    pha
    tya
    pha
    .endmacro

    .macro pull_regs
    pla
    tay
    pla
    tax
    pla
    .endmacro

;;; PPU registers

    PPU_CTRL   = $2000
    PPU_MASK   = $2001
    PPU_STAT   = $2002
    OAM_ADDR    = $2003
    OAM_DATA    = $2004
    OAM_DMA     = $4014
    PPU_SCROLL  = $2005
    PPU_ADDR    = $2006
    PPU_DATA    = $2007

    PPU_ADDR_PALETTE = $3f00

;;; APU Registers

    APU_P1_TIM = $4000
    APU_P1_LEN = $4001
    APU_P1_ENV = $4002
    APU_P1_SWP = $4003

    APU_P2_TIM = $4000
    APU_P2_LEN = $4001
    APU_P2_ENV = $4002
    APU_P2_SWP = $4003

    APU_STAT   = $4015

;;; Others

    DMC_IRQ    = $4010

;;; Gamepads

    GAMEPAD1_REG = $4016
    GAMEPAD2_REG = $4017

    GAMEPAD_A      = %10000000
    GAMEPAD_B      = %01000000
    GAMEPAD_SELECT = %00100000
    GAMEPAD_START  = %00010000
    GAMEPAD_UP     = %00001000
    GAMEPAD_DOWN   = %00000100
    GAMEPAD_LEFT   = %00000010
    GAMEPAD_RIGHT  = %00000001

    .macro read_gamepad gamepad_reg, state_var
    lda #$01
    sta gamepad_reg
    lda #$00
    sta gamepad_reg
    ldx #$08                    ; Read 8 Buttons in loop
:   lda gamepad_reg
    lsr a                       ; button state to carry
    rol state_var               ; carry to button mask
    dex
    bne :-
    .endmacro

    .endif
