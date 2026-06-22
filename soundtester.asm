; =============================================================================
; soundtester.asm
; -----------------------------------------------------------------------------
; Standalone MSX1 ROM for testing lib/sound.asm separately.
;
; Goal:
;   - The rest of the ECS/game framework is NOT used.
;   - Only the sound library is included.
;   - The M key toggles music on/off.
;   - The spacebar plays a noise sound effect on PSG channel C.
;
; Build with SjASMPlus v20190306.1:
;   sjasmplus soundtester.asm --raw=soundtester.rom
;
; Note:
;   - Directives are intentionally indented. Older SjASMPlus versions treat
;     directives in column 1 differently, as labels.
;   - No OUTPUT, SAVEBIN, or OUTEND. The output is created by --raw.
; =============================================================================

; =============================================================================
; Basic memory layout
; =============================================================================
ROM_START               EQU $4000
ROM_LIMIT               EQU $8000
ROM_SIZE                EQU ROM_LIMIT-ROM_START

; For this standalone tester we use page 3 RAM.
; This keeps the ROM test simple and independent from your ECS RAM layout.
RAM_BASE                EQU $C000
STACK_TOP               EQU $F380

; =============================================================================
; MSX BIOS entrypoints
; =============================================================================
BIOS_CHGMOD             EQU $005F     ; A = screen mode
BIOS_CHPUT              EQU $00A2     ; A = character to screen
BIOS_CHSNS              EQU $009C     ; Z = no key in keyboard buffer
BIOS_CHGET              EQU $009F     ; A = character from keyboard buffer
BIOS_WRTPSG             EQU $0093     ; A = PSG register, E = value

SCREEN_MODE_TEXT        EQU 0

; =============================================================================
; RAM variables for sound.asm
; -----------------------------------------------------------------------------
; Normally, these variables are in the framework's lib/ram.asm.
; For this standalone tester we define them here with EQU.
; This claims no ROM space; it only gives fixed RAM addresses.
; =============================================================================
sound_music_enabled     EQU RAM_BASE+0
sound_music_tick        EQU RAM_BASE+1
sound_music_a_ptr       EQU RAM_BASE+2     ; 2 bytes
sound_music_a_wait      EQU RAM_BASE+4
sound_music_b_ptr       EQU RAM_BASE+5     ; 2 bytes
sound_music_b_wait      EQU RAM_BASE+7
sound_duration          EQU RAM_BASE+8     ; SFX duration in frames
sound_sfx_volume        EQU RAM_BASE+9
sound_sfx_noise         EQU RAM_BASE+10

; Mute flags for the separate channel test.
; 0 = audible, 1 = muted.
sound_mute_a            EQU RAM_BASE+11
sound_mute_b            EQU RAM_BASE+12
sound_mute_c            EQU RAM_BASE+13

sound_ram_start         EQU sound_music_enabled
sound_ram_end           EQU sound_mute_c+1

        ASSERT sound_ram_end < STACK_TOP

; =============================================================================
; Cartridge header
; -----------------------------------------------------------------------------
; The MSX BIOS looks for "AB" at $4000. The init address is at $4002.
; =============================================================================
        ORG ROM_START

ROM_Header:
        DB      "AB"
        DW      ROM_Init
        DW      0
        DW      0
        DW      0
        DW      0
        DW      0
        DW      0

; =============================================================================
; ROM_Init
; =============================================================================
ROM_Init:
        DI
        LD      SP,STACK_TOP

        ; Set the screen to text mode so CHPUT output is visible.
        LD      A,SCREEN_MODE_TEXT
        CALL    BIOS_CHGMOD

        ; Initialize the sound library.
        CALL    Sound_Init

        ; Show short instruction text.
        LD      HL,Text_Title
        CALL    PrintString
        LD      HL,Text_Help
        CALL    PrintString

        EI

MainLoop:
        ; Wait for the next interrupt/frame. This keeps the BIOS keyboard scan
        ; working properly and runs Sound_Update about 50/60 times per second.
        HALT

        CALL    PollKeyboard
        CALL    Sound_Update
        JP      MainLoop

; =============================================================================
; PollKeyboard
; -----------------------------------------------------------------------------
; Reads the BIOS keyboard buffer. This is easier than reading the keyboard matrix
; directly and is therefore ideal for a standalone tester.
;
; M or m  = music on/off
; A or a  = toggle channel A mute
; B or b  = toggle channel B mute
; C or c  = toggle channel C mute
; Space  = sound effect
; =============================================================================
PollKeyboard:
        CALL    BIOS_CHSNS
        RET     Z                   ; no key available

        CALL    BIOS_CHGET          ; A = ASCII character

        CP      'm'
        JR      Z,.toggle_music
        CP      'M'
        JR      Z,.toggle_music

        CP      'a'
        JR      Z,.toggle_a
        CP      'A'
        JR      Z,.toggle_a

        CP      'b'
        JR      Z,.toggle_b
        CP      'B'
        JR      Z,.toggle_b

        CP      'c'
        JR      Z,.toggle_c
        CP      'C'
        JR      Z,.toggle_c

        CP      ' '
        JR      Z,.play_sfx

        RET

.toggle_music:
        CALL    Sound_ToggleMusic
        RET

.toggle_a:
        CALL    Sound_ToggleMuteA
        RET

.toggle_b:
        CALL    Sound_ToggleMuteB
        RET

.toggle_c:
        CALL    Sound_ToggleMuteC
        RET

.play_sfx:
        CALL    Sound_PlayNoiseSfx
        RET

; =============================================================================
; PrintString
; -----------------------------------------------------------------------------
; HL = pointer to zero-terminated text.
; =============================================================================
PrintString:
        LD      A,(HL)
        OR      A
        RET     Z
        CALL    BIOS_CHPUT
        INC     HL
        JR      PrintString

Text_Title:
        DB      13,10
        DB      "MSX PSG SOUND TESTER",13,10
        DB      "--------------------",13,10,0

Text_Help:
        DB      "M     : music on/off",13,10
        DB      "A/B/C : toggle channel A/B/C mute",13,10
        DB      "SPACE : noise soundeffect",13,10
        DB      13,10
        DB      "Channel A = melody",13,10
        DB      "Channel B = bass",13,10
        DB      "Channel C = SFX noise",13,10,0

; =============================================================================
; Include the sound library that you will later also use in your framework.
; =============================================================================
        INCLUDE "lib/sound.asm"

; =============================================================================
; Pad ROM to exactly 16 KB
; =============================================================================
ROM_End:
        ASSERT $ <= ROM_LIMIT
        BLOCK ROM_LIMIT-$,$FF
