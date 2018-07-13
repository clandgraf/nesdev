;;; -*- mode: asm -*-

    .ifndef __DEFS_H__
    __DEFS_H__ = 1

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

    .endif
