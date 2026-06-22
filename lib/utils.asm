; =============================================================================
; lib/utils.asm
; -----------------------------------------------------------------------------
; Small general routines used by multiple subsystems.
; =============================================================================

; -----------------------------------------------------------------------------
; Runtime_Clear
; -----------------------------------------------------------------------------
; Clears all runtime variables and component arrays in RAM.
;
; Input : none
; Output: RAM_START..RAM_END-1 filled with zero, player_entity_id = $FF
; Modifies: AF, BC, HL, E
; -----------------------------------------------------------------------------
Runtime_Clear:
        LD      HL,RAM_START
        LD      BC,RAM_END-RAM_START
        XOR     A
        CALL    MemFill

        ; $FF means: no player entity has been created yet.
        LD      A,$FF
        LD      (player_entity_id),A
        RET

; -----------------------------------------------------------------------------
; MemClear
; -----------------------------------------------------------------------------
; Fill BC bytes from HL with zero.
;
; Input : HL=start address, BC=number of bytes
; Output: HL points after the filled block
; Modifies: AF, BC, HL, E
; -----------------------------------------------------------------------------
MemClear:
        XOR     A
        ; Intentionally falls through to MemFill.

; -----------------------------------------------------------------------------
; MemFill
; -----------------------------------------------------------------------------
; Fill BC bytes from HL with value A.
;
; Input : HL=start address, BC=number of bytes, A=fill value
; Output: HL points after the filled block
; Modifies: AF, BC, HL, E
; -----------------------------------------------------------------------------
MemFill:
        LD      E,A                 ; Save fill value.
        LD      A,B
        OR      C
        RET     Z                   ; Length 0: do nothing.

MemFill_Loop:
        LD      A,E
        LD      (HL),A
        INC     HL
        DEC     BC
        LD      A,B
        OR      C
        JR      NZ,MemFill_Loop
        RET
