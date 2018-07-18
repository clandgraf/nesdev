;;; -*- mode: asm -*-

    .ifndef __NMI_H__
    __NMI_H__ = 1

    .include "defs.s"

;;; ===========================================
;;;
;;;    macro: wait_for_nmi
;;;
;;; ===========================================

    .macro wait_for_nmi frame_flag
    lda #$01
    sta frame_flag
    ;; Wait for NMI to run
:   lda frame_flag
    bne :-
    .endmacro

;;; ===========================================
;;;
;;;    macro: start_nmi
;;;
;;; ===========================================

    .macro start_nmi
    push_regs
    .endmacro

;;; ===========================================
;;;
;;;    macro: check_for_frame_nmi
;;;
;;; ===========================================

    .macro check_for_frame_nmi frame_flag
    lda FRAME_READY
    beq ReturnNMI
    .endmacro

;;; ===========================================
;;;
;;;    macro: return_from_nmi
;;;
;;; ===========================================

    .macro return_from_nmi frame_flag
ReturnNMI:
    lda #$00
    sta frame_flag
    pull_regs
    rti
    .endmacro

    .endif
