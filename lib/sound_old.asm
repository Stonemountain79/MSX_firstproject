; =============================================================================
; lib/sound.asm
; -----------------------------------------------------------------------------
; Very small PSG sound system.
;
; This is intentionally kept simple:
;   - One blip/SFX on channel A.
;   - Sound_Update counts down a duration.
;   - Sound_PlayBlip starts or restarts the effect.
;
; Later, you can replace this file with a real music/SFX player without changing your
; ECS/game loop structure.
; =============================================================================

; PSG register numbers for channel A.
PSG_TONE_A_FINE         EQU 0
PSG_TONE_A_COARSE       EQU 1
PSG_MIXER               EQU 7
PSG_AMP_A               EQU 8

; -----------------------------------------------------------------------------
; Sound_Init
; -----------------------------------------------------------------------------
; Silence PSG channel A.
; -----------------------------------------------------------------------------
Sound_Init:
        CALL    Sound_Mute
        XOR     A
        LD      (sound_duration),A
        RET

; -----------------------------------------------------------------------------
; Sound_PlayBlip
; -----------------------------------------------------------------------------
; Start a short tone. Called in the demo when fire has just been pressed.
; -----------------------------------------------------------------------------
Sound_PlayBlip:
        ; Tone period channel A. Smaller period = higher pitch.
        LD      A,PSG_TONE_A_FINE
        LD      E,$AA
        CALL    PSG_Write

        LD      A,PSG_TONE_A_COARSE
        LD      E,$00
        CALL    PSG_Write

        ; Mixer: channel A tone on, channel A noise off, other channels untouched
        ; kept simple as a fixed value.
        LD      A,PSG_MIXER
        LD      E,$3E
        CALL    PSG_Write

        ; Fixed volume 15 on channel A.
        LD      A,PSG_AMP_A
        LD      E,15
        CALL    PSG_Write

        ; Number of frames the blip remains audible.
        LD      A,6
        LD      (sound_duration),A
        RET

; -----------------------------------------------------------------------------
; Sound_Update
; -----------------------------------------------------------------------------
; Counts down the active sound. When the timer becomes 0, mute channel A.
; -----------------------------------------------------------------------------
Sound_Update:
        LD      A,(sound_duration)
        OR      A
        RET     Z

        DEC     A
        LD      (sound_duration),A
        RET     NZ

        CALL    Sound_Mute
        RET

; -----------------------------------------------------------------------------
; Sound_Mute
; -----------------------------------------------------------------------------
; Set channel A amplitude to 0 and disable tone/noise.
; -----------------------------------------------------------------------------
Sound_Mute:
        LD      A,PSG_AMP_A
        LD      E,0
        CALL    PSG_Write

        LD      A,PSG_MIXER
        LD      E,$3F                ; All tone/noise off.
        CALL    PSG_Write
        RET

; -----------------------------------------------------------------------------
; PSG_Write
; -----------------------------------------------------------------------------
; Write one PSG register.
;
; Input : A=PSG register number, E=value
; Modifies: AF
; -----------------------------------------------------------------------------
PSG_Write:
        OUT     (PSG_REG_PORT),A
        LD      A,E
        OUT     (PSG_DATA_PORT),A
        RET
