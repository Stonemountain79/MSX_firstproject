; =============================================================================
; lib/sound.asm
; -----------------------------------------------------------------------------
; Standalone-friendly PSG sound library for MSX1 / AY-3-8910.
;
; This file can be used by soundtester.asm without the rest of the
; ECS framework. The required RAM labels are defined in soundtester.asm.
;
; Channel strategy:
;   - PSG channel A: music melody
;   - PSG channel B: music bass/accompaniment
;   - PSG channel C: sound effect with noise
;
; Important:
;   - The noise generator is not a fourth channel.
;   - Noise is made audible through channel C.
;   - During SFX, channel C is used by SFX.
;   - This test does not use music on channel C yet.
;
; Public routines:
;   Sound_Init
;   Sound_Update
;   Sound_ToggleMusic
;   Sound_PlayNoiseSfx
;   Sound_PlayBlip          compatibility alias to Sound_PlayNoiseSfx
;   Sound_ToggleMuteA
;   Sound_ToggleMuteB
;   Sound_ToggleMuteC
;
; Expected RAM labels:
;   sound_music_enabled
;   sound_music_tick
;   sound_music_a_ptr       2 bytes
;   sound_music_a_wait
;   sound_music_b_ptr       2 bytes
;   sound_music_b_wait
;   sound_duration
;   sound_sfx_volume
;   sound_sfx_noise
;   sound_mute_a
;   sound_mute_b
;   sound_mute_c
; =============================================================================

; =============================================================================
; PSG register numbers
; =============================================================================
PSG_TONE_A_FINE         EQU 0
PSG_TONE_A_COARSE       EQU 1
PSG_TONE_B_FINE         EQU 2
PSG_TONE_B_COARSE       EQU 3
PSG_TONE_C_FINE         EQU 4
PSG_TONE_C_COARSE       EQU 5
PSG_NOISE_PERIOD        EQU 6
PSG_MIXER               EQU 7
PSG_AMP_A               EQU 8
PSG_AMP_B               EQU 9
PSG_AMP_C               EQU 10

; Mixer bits:
;   bit 0 tone A disable
;   bit 1 tone B disable
;   bit 2 tone C disable
;   bit 3 noise A disable
;   bit 4 noise B disable
;   bit 5 noise C disable
; Bit = 0 is on, bit = 1 is off.
;
; $3C = 00111100b:
;   tone A on, tone B on, tone C off, all noise off.
PSG_MIXER_MUSIC_AB      EQU $3C

; $1C = 00011100b:
;   tone A on, tone B on, tone C off, noise C on.
PSG_MIXER_SFX_NOISE_C   EQU $1C

; Music command bytes.
MUSIC_CMD_REST          EQU $00
MUSIC_CMD_LOOP          EQU $FE
MUSIC_CMD_END           EQU $FF

; Duration values in frames. On PAL MSX, 50 frames is about 1 second.
DUR_1                   EQU 6
DUR_2                   EQU 12
DUR_4                   EQU 24
DUR_8                   EQU 48

; =============================================================================
; Sound_Init
; =============================================================================
Sound_Init:
        ; Music is on by default.
        LD      A,1
        LD      (sound_music_enabled),A

        XOR     A
        LD      (sound_music_tick),A
        LD      (sound_music_a_wait),A
        LD      (sound_music_b_wait),A
        LD      (sound_duration),A
        LD      (sound_sfx_volume),A
        LD      (sound_sfx_noise),A
        LD      (sound_mute_a),A
        LD      (sound_mute_b),A
        LD      (sound_mute_c),A

        ; Set channel pointers to the start of the test melody.
        LD      HL,Music_ChannelA
        LD      (sound_music_a_ptr),HL
        LD      HL,Music_ChannelB
        LD      (sound_music_b_ptr),HL

        ; All volumes off first.
        CALL    Sound_MuteAll

        ; Mixer to music mode: A/B tone on, C/noise off.
        LD      A,PSG_MIXER
        LD      E,PSG_MIXER_MUSIC_AB
        CALL    PSG_Write
        RET

; =============================================================================
; Sound_ToggleMusic
; -----------------------------------------------------------------------------
; Turns music on/off. SFX keeps working normally.
; =============================================================================
Sound_ToggleMusic:
        LD      A,(sound_music_enabled)
        XOR     1
        LD      (sound_music_enabled),A
        OR      A
        JR      NZ,.turned_on

.turned_off:
        ; Mute music channels only. Channel C/SFX is not forcibly stopped.
        XOR     A
        LD      E,A
        LD      A,PSG_AMP_A
        CALL    PSG_Write
        LD      A,PSG_AMP_B
        CALL    PSG_Write
        RET

.turned_on:
        ; Force both music channels to read a new note immediately.
        XOR     A
        LD      (sound_music_a_wait),A
        LD      (sound_music_b_wait),A
        RET


; =============================================================================
; Sound_ToggleMuteA / B / C
; -----------------------------------------------------------------------------
; Separate channel mutes for the soundtester.
; The music player keeps running internally. Only the volume of the
; selected channel is set to 0. When you unmute, the next
; note/update writes volume again.
; =============================================================================
Sound_ToggleMuteA:
        LD      HL,sound_mute_a
        CALL    Sound_ToggleMuteFlag
        LD      A,(sound_mute_a)
        OR      A
        RET     Z
        XOR     A
        LD      E,A
        LD      A,PSG_AMP_A
        CALL    PSG_Write
        RET

Sound_ToggleMuteB:
        LD      HL,sound_mute_b
        CALL    Sound_ToggleMuteFlag
        LD      A,(sound_mute_b)
        OR      A
        RET     Z
        XOR     A
        LD      E,A
        LD      A,PSG_AMP_B
        CALL    PSG_Write
        RET

Sound_ToggleMuteC:
        LD      HL,sound_mute_c
        CALL    Sound_ToggleMuteFlag
        LD      A,(sound_mute_c)
        OR      A
        RET     Z
        XOR     A
        LD      E,A
        LD      A,PSG_AMP_C
        CALL    PSG_Write
        RET

Sound_ToggleMuteFlag:
        LD      A,(HL)
        XOR     1
        LD      (HL),A
        RET

; =============================================================================
; Sound_PlayBlip
; -----------------------------------------------------------------------------
; Compatibility name for the existing framework.
; =============================================================================
Sound_PlayBlip:
        JP      Sound_PlayNoiseSfx

; =============================================================================
; Sound_PlayNoiseSfx
; -----------------------------------------------------------------------------
; Start a short decaying noise on channel C.
; =============================================================================
Sound_PlayNoiseSfx:
        LD      A,10
        LD      (sound_duration),A

        LD      A,15
        LD      (sound_sfx_volume),A

        LD      A,4
        LD      (sound_sfx_noise),A

        ; Set mixer so noise is audible through channel C.
        LD      A,PSG_MIXER
        LD      E,PSG_MIXER_SFX_NOISE_C
        CALL    PSG_Write
        RET

; =============================================================================
; Sound_Update
; -----------------------------------------------------------------------------
; Must be called once per frame.
; =============================================================================
Sound_Update:
        ; Only update music A/B when music is on.
        LD      A,(sound_music_enabled)
        OR      A
        JR      Z,.skip_music

        CALL    Music_UpdateChannelA
        CALL    Music_UpdateChannelB

.skip_music:
        ; Update SFX on channel C. If no SFX is active, channel C remains silent
        ; and the mixer is in music mode for channel A/B.
        CALL    Sfx_UpdateChannelC
        RET

; =============================================================================
; Music_UpdateChannelA / B
; -----------------------------------------------------------------------------
; Simple player for data format:
;   DB note_index, duration
;   DB MUSIC_CMD_REST, duration
;   DB MUSIC_CMD_LOOP
;   DW address
;
; The note_index refers to NotePeriodTable.
; =============================================================================
Music_UpdateChannelA:
        LD      A,(sound_music_a_wait)
        OR      A
        JR      Z,.read_next
        DEC     A
        LD      (sound_music_a_wait),A
        RET

.read_next:
        LD      HL,(sound_music_a_ptr)
        CALL    Music_ReadCommandA
        RET

Music_UpdateChannelB:
        LD      A,(sound_music_b_wait)
        OR      A
        JR      Z,.read_next
        DEC     A
        LD      (sound_music_b_wait),A
        RET

.read_next:
        LD      HL,(sound_music_b_ptr)
        CALL    Music_ReadCommandB
        RET

; =============================================================================
; Music_ReadCommandA
; -----------------------------------------------------------------------------
; HL = pointer into channel A music data.
; =============================================================================
Music_ReadCommandA:
        LD      A,(HL)
        CP      MUSIC_CMD_LOOP
        JR      Z,.loop
        CP      MUSIC_CMD_END
        JR      Z,.end

        ; Normal note or rest.
        INC     HL
        LD      B,(HL)               ; B = duration
        INC     HL
        LD      (sound_music_a_ptr),HL
        LD      A,B
        LD      (sound_music_a_wait),A

        ; Fetch note again. HL already points further, so restoring the pointer via stack is
        ; cumbersome. Therefore do not use the note from data through DE; simpler:
        ; the pointer is two bytes after the command, so read the command byte again.
        LD      HL,(sound_music_a_ptr)
        DEC     HL
        DEC     HL
        LD      A,(HL)
        CALL    Music_SetChannelA
        RET

.loop:
        INC     HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      (sound_music_a_ptr),HL
        JR      Music_ReadCommandA

.end:
        ; Handle END as mute.
        XOR     A
        LD      E,A
        LD      A,PSG_AMP_A
        CALL    PSG_Write
        RET

; =============================================================================
; Music_ReadCommandB
; -----------------------------------------------------------------------------
; HL = pointer into channel B music data.
; =============================================================================
Music_ReadCommandB:
        LD      A,(HL)
        CP      MUSIC_CMD_LOOP
        JR      Z,.loop
        CP      MUSIC_CMD_END
        JR      Z,.end

        INC     HL
        LD      B,(HL)
        INC     HL
        LD      (sound_music_b_ptr),HL
        LD      A,B
        LD      (sound_music_b_wait),A

        LD      HL,(sound_music_b_ptr)
        DEC     HL
        DEC     HL
        LD      A,(HL)
        CALL    Music_SetChannelB
        RET

.loop:
        INC     HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      (sound_music_b_ptr),HL
        JR      Music_ReadCommandB

.end:
        XOR     A
        LD      E,A
        LD      A,PSG_AMP_B
        CALL    PSG_Write
        RET

; =============================================================================
; Music_SetChannelA
; -----------------------------------------------------------------------------
; A = note_index of MUSIC_CMD_REST.
; =============================================================================
Music_SetChannelA:
        OR      A
        JR      Z,.rest

        CALL    Music_GetPeriodHL     ; HL = period word

        LD      A,PSG_TONE_A_FINE
        LD      E,L
        CALL    PSG_Write

        LD      A,PSG_TONE_A_COARSE
        LD      E,H
        CALL    PSG_Write

        ; Only write volume if channel A is not muted.
        LD      A,(sound_mute_a)
        OR      A
        JR      NZ,.muted
        LD      A,PSG_AMP_A
        LD      E,11
        CALL    PSG_Write
        RET

.muted:
        XOR     A
        LD      E,A
        LD      A,PSG_AMP_A
        CALL    PSG_Write
        RET

.rest:
        XOR     A
        LD      E,A
        LD      A,PSG_AMP_A
        CALL    PSG_Write
        RET

; =============================================================================
; Music_SetChannelB
; -----------------------------------------------------------------------------
; A = note_index of MUSIC_CMD_REST.
; =============================================================================
Music_SetChannelB:
        OR      A
        JR      Z,.rest

        CALL    Music_GetPeriodHL

        LD      A,PSG_TONE_B_FINE
        LD      E,L
        CALL    PSG_Write

        LD      A,PSG_TONE_B_COARSE
        LD      E,H
        CALL    PSG_Write

        ; Only write volume if channel B is not muted.
        LD      A,(sound_mute_b)
        OR      A
        JR      NZ,.muted
        LD      A,PSG_AMP_B
        LD      E,9
        CALL    PSG_Write
        RET

.muted:
        XOR     A
        LD      E,A
        LD      A,PSG_AMP_B
        CALL    PSG_Write
        RET

.rest:
        XOR     A
        LD      E,A
        LD      A,PSG_AMP_B
        CALL    PSG_Write
        RET

; =============================================================================
; Music_GetPeriodHL
; -----------------------------------------------------------------------------
; A = note_index, 1..n
; Output:
;   HL = 12-bit PSG period value.
; =============================================================================
Music_GetPeriodHL:
        ; table offset = note_index * 2
        LD      L,A
        LD      H,0
        ADD     HL,HL
        LD      DE,NotePeriodTable
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        RET

; =============================================================================
; Sfx_UpdateChannelC
; -----------------------------------------------------------------------------
; Plays decaying noise on channel C while sound_duration > 0.
; =============================================================================
Sfx_UpdateChannelC:
        LD      A,(sound_duration)
        OR      A
        JR      Z,.inactive

        ; Slowly make the noise period coarser.
        LD      A,(sound_sfx_noise)
        LD      E,A
        LD      A,PSG_NOISE_PERIOD
        CALL    PSG_Write

        LD      A,(sound_sfx_noise)
        INC     A
        LD      (sound_sfx_noise),A

        ; Write and decay the volume.
        ; If channel C is muted, the SFX timer still runs, but you hear nothing.
        LD      A,(sound_mute_c)
        OR      A
        JR      NZ,.write_silent_c

        LD      A,(sound_sfx_volume)
        LD      E,A
        LD      A,PSG_AMP_C
        CALL    PSG_Write
        JR      .after_volume_write

.write_silent_c:
        XOR     A
        LD      E,A
        LD      A,PSG_AMP_C
        CALL    PSG_Write

.after_volume_write:

        LD      A,(sound_sfx_volume)
        OR      A
        JR      Z,.skip_volume_dec
        DEC     A
        LD      (sound_sfx_volume),A

.skip_volume_dec:
        LD      A,(sound_duration)
        DEC     A
        LD      (sound_duration),A
        RET

.inactive:
        ; Silence channel C.
        XOR     A
        LD      E,A
        LD      A,PSG_AMP_C
        CALL    PSG_Write

        ; Mixer back to music mode A/B, noise off.
        LD      A,PSG_MIXER
        LD      E,PSG_MIXER_MUSIC_AB
        CALL    PSG_Write
        RET

; =============================================================================
; Sound_MuteAll
; =============================================================================
Sound_MuteAll:
        XOR     A
        LD      E,A
        LD      A,PSG_AMP_A
        CALL    PSG_Write
        LD      A,PSG_AMP_B
        CALL    PSG_Write
        LD      A,PSG_AMP_C
        CALL    PSG_Write
        RET

; =============================================================================
; PSG_Write
; -----------------------------------------------------------------------------
; Write to PSG.
;
; Input:
;   A = PSG register number
;   E = value
;
; We use BIOS_WRTPSG ($0093) here instead of direct OUT, because this
; standalone tester is mainly intended for practice and compatibility.
; If you later want maximum speed, you can replace this routine with:
;
;   OUT (PSG_REG_PORT),A
;   LD  A,E
;   OUT (PSG_DATA_PORT),A
;   RET
; =============================================================================
PSG_Write:
        JP      BIOS_WRTPSG

; =============================================================================
; Note numbers
; -----------------------------------------------------------------------------
; 0 is rest. The other values are indices in NotePeriodTable.
; This table is intentionally kept small for the test melody.
; =============================================================================
NOTE_REST               EQU 0
NOTE_C3                 EQU 1
NOTE_D3                 EQU 2
NOTE_E3                 EQU 3
NOTE_F3                 EQU 4
NOTE_G3                 EQU 5
NOTE_A3                 EQU 6
NOTE_B3                 EQU 7
NOTE_C4                 EQU 8
NOTE_D4                 EQU 9
NOTE_E4                 EQU 10
NOTE_F4                 EQU 11
NOTE_G4                 EQU 12
NOTE_A4                 EQU 13
NOTE_B4                 EQU 14
NOTE_C5                 EQU 15

; =============================================================================
; NotePeriodTable
; -----------------------------------------------------------------------------
; PSG period values for approximately A4=440 Hz on the MSX PSG clock.
; Values are good enough for a first tester.
; Index 0 = rest, uses no period.
; =============================================================================
NotePeriodTable:
        DW      0       ; 0 REST
        DW      852     ; 1 C3
        DW      759     ; 2 D3
        DW      676     ; 3 E3
        DW      638     ; 4 F3
        DW      568     ; 5 G3
        DW      506     ; 6 A3
        DW      451     ; 7 B3
        DW      426     ; 8 C4
        DW      379     ; 9 D4
        DW      338     ; 10 E4
        DW      319     ; 11 F4
        DW      284     ; 12 G4
        DW      253     ; 13 A4
        DW      225     ; 14 B4
        DW      213     ; 15 C5

; =============================================================================
; Test melody
; -----------------------------------------------------------------------------
; Channel A plays melody.
; Channel B plays simple bass notes.
;
; Data format:
;   DB note, duration
;   DB MUSIC_CMD_LOOP
;   DW address
; =============================================================================
Music_ChannelA:
        DB      NOTE_C4,DUR_2
        DB      NOTE_D4,DUR_2
        DB      NOTE_E4,DUR_2
        DB      NOTE_G4,DUR_2
        DB      NOTE_E4,DUR_2
        DB      NOTE_D4,DUR_2
        DB      NOTE_C4,DUR_4
        DB      NOTE_REST,DUR_2

        DB      NOTE_C4,DUR_2
        DB      NOTE_D4,DUR_2
        DB      NOTE_E4,DUR_2
        DB      NOTE_G4,DUR_2
        DB      NOTE_A4,DUR_2
        DB      NOTE_G4,DUR_2
        DB      NOTE_E4,DUR_4
        DB      NOTE_REST,DUR_2

        DB      MUSIC_CMD_LOOP
        DW      Music_ChannelA

Music_ChannelB:
        DB      NOTE_C3,DUR_4
        DB      NOTE_REST,DUR_2
        DB      NOTE_C3,DUR_4
        DB      NOTE_REST,DUR_2
        DB      NOTE_G3,DUR_4
        DB      NOTE_REST,DUR_2
        DB      NOTE_G3,DUR_4
        DB      NOTE_REST,DUR_2

        DB      NOTE_F3,DUR_4
        DB      NOTE_REST,DUR_2
        DB      NOTE_G3,DUR_4
        DB      NOTE_REST,DUR_2
        DB      NOTE_C3,DUR_8
        DB      NOTE_REST,DUR_2

        DB      MUSIC_CMD_LOOP
        DW      Music_ChannelB
