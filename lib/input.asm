; =============================================================================
; lib/input.asm
; -----------------------------------------------------------------------------
; Input subsystem.
;
; This version reads:
;   - Cursor keys through BIOS_GTSTCK with A=0.
;   - Joystick 1 through BIOS_GTSTCK with A=1 when the cursor is neutral.
;   - Space through BIOS_GTTRIG with A=0.
;   - Joystick 1 button A through BIOS_GTTRIG with A=1.
;
; Output for systems:
;   input_dx            signed byte: $FF, $00, $01
;   input_dy            signed byte: $FF, $00, $01
;   input_fire          $00 of $FF
;   input_fire_pressed  one frame $FF on new press
; =============================================================================

; -----------------------------------------------------------------------------
; Input_Update
; -----------------------------------------------------------------------------
; Read input and convert direction 0..8 to dx/dy.
; -----------------------------------------------------------------------------
Input_Update:
        ; Save previous fire state so we can create an edge.
        LD      A,(input_fire)
        LD      (input_fire_prev),A

        ; Try cursor keys first.
        LD      A,0
        CALL    BIOS_GTSTCK
        OR      A
        JR      NZ,Input_Update_GotDirection

        ; If cursors are neutral, use joystick 1.
        LD      A,1
        CALL    BIOS_GTSTCK

Input_Update_GotDirection:
        LD      (input_dir),A

        ; Direction -> dx.
        LD      E,A
        LD      D,0
        LD      HL,Input_DxTable
        ADD     HL,DE
        LD      A,(HL)
        LD      (input_dx),A

        ; Direction -> dy.
        LD      A,(input_dir)
        LD      E,A
        LD      D,0
        LD      HL,Input_DyTable
        ADD     HL,DE
        LD      A,(HL)
        LD      (input_dy),A

        ; Read fire: space OR joystick 1 button A.
        LD      A,0
        CALL    BIOS_GTTRIG
        LD      E,A

        LD      A,1
        CALL    BIOS_GTTRIG
        OR      E
        LD      (input_fire),A

        ; Create a one-frame pressed event.
        OR      A
        JR      Z,Input_Update_NoNewPress

        LD      A,(input_fire_prev)
        OR      A
        JR      NZ,Input_Update_NoNewPress

        LD      A,$FF
        LD      (input_fire_pressed),A
        RET

Input_Update_NoNewPress:
        XOR     A
        LD      (input_fire_pressed),A
        RET

; -----------------------------------------------------------------------------
; Direction tables for BIOS_GTSTCK.
;
; MSX direction encoding:
;   0 neutral
;   1 up
;   2 up-right
;   3 right
;   4 down-right
;   5 down
;   6 down-left
;   7 left
;   8 up-left
; -----------------------------------------------------------------------------
Input_DxTable:
        DB      0,  0,  1,  1,  1,  0, $FF, $FF, $FF

Input_DyTable:
        DB      0, $FF, $FF, 0,  1,  1,  1,   0, $FF
