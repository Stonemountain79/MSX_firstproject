; =============================================================================
; lib/sound.asm
; -----------------------------------------------------------------------------
; PSG sound system for MSX / AY-3-8910.
;
; Design: option 4, use the noise channel smartly.
;
; Important to understand:
;   - The PSG has 3 audible channels: A, B, and C.
;   - The noise generator is NOT a fourth independent channel.
;   - Noise is made audible through channel A, B, and/or C.
;
; Strategy in this framework:
;   - Channel A is intended for music.
;   - Channel B is intended for music.
;   - Channel C is the shared channel:
;       * without SFX, music may use channel C;
;       * with SFX, the noise effect temporarily gets priority on channel C.
;
; The music engine is not set up yet. Sound_Update contains clear
; comment blocks where the music code should go later.
;
; Current demo:
;   - Sound_PlayBlip starts a short noise effect on channel C.
;   - Sound_Update counts down the SFX timer.
;   - When the SFX is done, channel C is released again.
;
; RAM usage:
;   - sound_duration is used as SFX duration in frames.
;   - This variable must exist in lib/ram.asm, as was already the case in the original
;     framework.
; =============================================================================

; =============================================================================
; PSG register numbers
; =============================================================================

; Tone registers channel A. To be used later by the music engine.
PSG_TONE_A_FINE         EQU 0
PSG_TONE_A_COARSE       EQU 1

; Tone registers channel B. To be used later by the music engine.
PSG_TONE_B_FINE         EQU 2
PSG_TONE_B_COARSE       EQU 3

; Tone registers channel C. Only use for music when no SFX is active.
PSG_TONE_C_FINE         EQU 4
PSG_TONE_C_COARSE       EQU 5

; Noise period register. One global noise generator for the whole PSG.
PSG_NOISE_PERIOD        EQU 6

; Mixer register.
; Bit = 0 means on.
; Bit = 1 means off.
;
; Bit 0: tone A disable
; Bit 1: tone B disable
; Bit 2: tone C disable
; Bit 3: noise A disable
; Bit 4: noise B disable
; Bit 5: noise C disable
PSG_MIXER               EQU 7

; Volume/amplitude registers.
PSG_AMP_A               EQU 8
PSG_AMP_B               EQU 9
PSG_AMP_C               EQU 10

; =============================================================================
; Mixer presets
; =============================================================================

; No SFX active:
;   - tone A on, intended for music
;   - tone B on, intended for music
;   - tone C off in this basic version
;   - noise A/B/C off
;
; Binary bits 5..0 = 111100 = $3C
;
; If you later want to use music on channel C when no SFX is playing,
; change this value to $38:
;   - $38 = tone A/B/C on, noise A/B/C off.
PSG_MIXER_MUSIC_AB      EQU $3C

; SFX active on channel C:
;   - tone A on, music remains possible
;   - tone B on, music remains possible
;   - tone C off, because channel C is used for noise
;   - noise A off
;   - noise B off
;   - noise C on
;
; Binary bits 5..0 = 011100 = $1C
PSG_MIXER_SFX_NOISE_C   EQU $1C

; =============================================================================
; Sound_Init
; -----------------------------------------------------------------------------
; Initializes the PSG part used by this framework.
;
; Later, when you add a real music engine, you can also initialize the
; music state here. For example:
;   - current pattern number
;   - current row/step
;   - tempo counter
;   - instrument table pointer
; =============================================================================
Sound_Init:
        ; Stop any old SFX.
        XOR     A
        LD      (sound_duration),A

        ; Silence channel C. We intentionally leave channel A/B alone, because they
        ; can later be used by the music engine.
        CALL    Sound_MuteSfxChannel

        ; Set the mixer to the base state for music on channel A/B.
        LD      A,PSG_MIXER
        LD      E,PSG_MIXER_MUSIC_AB
        CALL    PSG_Write
        RET

; =============================================================================
; Sound_PlayBlip
; -----------------------------------------------------------------------------
; Compatibility entry point for the existing demo/game loop.
;
; The name remains Sound_PlayBlip, so existing code does not need to change.
; Internally, this routine no longer starts a tone on channel A, but a short
; noise effect on channel C.
; =============================================================================
Sound_PlayBlip:
        JP      Sound_PlayNoiseSfx

; =============================================================================
; Sound_PlayNoiseSfx
; -----------------------------------------------------------------------------
; Start a short noise effect on channel C.
;
; This is suitable for simple effects such as:
;   - shot
;   - tick
;   - menu click
;   - short impact
;
; For explosions, you can later use the same structure, but with a
; longer duration and changing noise period/volume in Sound_Update.
; =============================================================================
Sound_PlayNoiseSfx:
        ; Noise period.
        ; Lower = sharper/higher noise.
        ; Higher = coarser/lower noise.
        LD      A,PSG_NOISE_PERIOD
        LD      E,$08
        CALL    PSG_Write

        ; Channel C volume to 15.
        ; Bit 4 must remain 0, because bit 4 activates envelope volume.
        LD      A,PSG_AMP_C
        LD      E,15
        CALL    PSG_Write

        ; Set mixer so noise is audible through channel C.
        ; Channel A and B remain available for music.
        LD      A,PSG_MIXER
        LD      E,PSG_MIXER_SFX_NOISE_C
        CALL    PSG_Write

        ; Number of frames the effect remains audible.
        LD      A,6
        LD      (sound_duration),A
        RET

; =============================================================================
; Sound_Update
; -----------------------------------------------------------------------------
; Called once per frame from the game loop.
;
; This is where the music engine should be updated later.
;
; Recommended future structure:
;
;   1. Update music timing/tempo.
;   2. Write music to channel A.
;   3. Write music to channel B.
;   4. Check whether an SFX is active.
;      - Yes: channel C is used by SFX.
;      - No: music may use channel C, if you want that.
;   5. Update SFX timer and end SFX when needed.
;
; Note:
;   If you later make 3-channel music, the music engine must NOT
;   overwrite channel C while sound_duration is greater than 0.
; =============================================================================
Sound_Update:

        ; ---------------------------------------------------------------------
        ; TODO MUSIC: channel A update
        ; ---------------------------------------------------------------------
        ; Music code for channel A will go here later.
        ; Example of what a music engine would do here:
        ;   - calculate tone period A or fetch it from pattern data
        ;   - PSG_TONE_A_FINE write
        ;   - PSG_TONE_A_COARSE write
        ;   - PSG_AMP_A write
        ;
        ; For now, nothing happens here yet.

        ; ---------------------------------------------------------------------
        ; TODO MUSIC: channel B update
        ; ---------------------------------------------------------------------
        ; Music code for channel B will go here later.
        ; Channel B is useful for bass, accompaniment, or arpeggio.
        ;
        ; For now, nothing happens here yet.

        ; ---------------------------------------------------------------------
        ; SFX active?
        ; ---------------------------------------------------------------------
        LD      A,(sound_duration)
        OR      A
        JR      Z,.no_sfx_active

.sfx_active:
        ; ---------------------------------------------------------------------
        ; TODO SFX: more advanced noise envelopes
        ; ---------------------------------------------------------------------
        ; Here you can later adjust the noise period or volume per frame.
        ; For example, for an explosion:
        ;   - duration high: volume 15, noise period large
        ;   - duration low : volume down, noise period smaller/larger
        ;
        ; The simple demo only counts the duration down.
        DEC     A
        LD      (sound_duration),A
        RET     NZ

        ; SFX has just finished. Release channel C.
        CALL    Sound_MuteSfxChannel

        ; Mixer back to base state.
        ; Channel A/B remain intended for music.
        LD      A,PSG_MIXER
        LD      E,PSG_MIXER_MUSIC_AB
        CALL    PSG_Write
        RET

.no_sfx_active:
        ; ---------------------------------------------------------------------
        ; TODO MUSIC: channel C update when NO SFX is active
        ; ---------------------------------------------------------------------
        ; If you later want 3-channel music, you may update channel C here.
        ; Only do that in this block, so SFX can take over channel C.
        ;
        ; For 3-channel music without SFX:
        ;   - set PSG_MIXER_MUSIC_AB to $38
        ;   - schrijf PSG_TONE_C_FINE
        ;   - schrijf PSG_TONE_C_COARSE
        ;   - schrijf PSG_AMP_C
        ;
        ; For now, nothing happens here yet.
        RET

; =============================================================================
; Sound_MuteSfxChannel
; -----------------------------------------------------------------------------
; Only set channel C volume to 0.
;
; We intentionally do not silence channel A and B here, because they can later
; can be used by the music engine.
; =============================================================================
Sound_MuteSfxChannel:
        LD      A,PSG_AMP_C
        LD      E,0
        CALL    PSG_Write
        RET

; =============================================================================
; Sound_Mute
; -----------------------------------------------------------------------------
; General mute routine for this sound file.
;
; This routine only mutes SFX channel C and sets the mixer back to the
; base state. Channel A/B volume is intentionally not adjusted, so future
; music code is not unexpectedly turned off.
;
; If you later have a complete music engine, you can also create a separate
; Music_Stop or Sound_StopAll routine that fully mutes A/B/C.
; =============================================================================
Sound_Mute:
        XOR     A
        LD      (sound_duration),A

        CALL    Sound_MuteSfxChannel

        LD      A,PSG_MIXER
        LD      E,PSG_MIXER_MUSIC_AB
        CALL    PSG_Write
        RET

; =============================================================================
; PSG_Write
; -----------------------------------------------------------------------------
; Write one PSG register.
;
; Input:
;   A = PSG register number
;   E = value
;
; Modifies:
;   AF
;
; PSG_REG_PORT and PSG_DATA_PORT come from lib/hardware.asm.
; For MSX this is normal:
;   PSG_REG_PORT  = $A0
;   PSG_DATA_PORT = $A1
; =============================================================================
PSG_Write:
        OUT     (PSG_REG_PORT),A
        LD      A,E
        OUT     (PSG_DATA_PORT),A
        RET
