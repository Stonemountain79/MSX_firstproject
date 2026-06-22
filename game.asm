; =============================================================================
; game.asm
; -----------------------------------------------------------------------------
; Main file of the MSX Z80 assembly ECS framework.
;
; Build for SjASMPlus v20190306.1:
;   sjasmplus game.asm --raw=game.rom
;
; Or use on Windows:
;   build
;
; This source intentionally does not use OUTPUT, SAVEBIN, or OUTEND. The ROM is written
; by the command-line option --raw=game.rom. All bytes emitted by this source
; starting at ORG ROM_START together form the ROM file.
;
; Memory choice:
;   - 16 KB cartridge ROM at $4000-$7FFF.
;   - Code, tiles, tilemap, and sprite patterns are stored in ROM.
;   - Runtime data is stored in RAM starting at $8000 by default.
;   - This leaves as much RAM as possible for ECS component arrays.
;
; Naming convention:
;   - Code/data labels: Subsystem_Name, for example Drawing_InitScreen2.
;   - Constants: UPPERCASE_WITH_UNDERSCORES.
;   - RAM variables: lowercase_with_underscores.
;
; SjASMPlus style rule:
;   Labels are placed on the left. Instructions and directives are indented. This prevents
;   SjASMPlus from accidentally treating INCLUDE/ORG/ASSERT/DS as labels.
; =============================================================================

; -----------------------------------------------------------------------------
; Project-wide constants and RAM addresses.
; These includes generate no ROM bytes.
; -----------------------------------------------------------------------------
        INCLUDE "lib/constants.asm"
        INCLUDE "lib/bios.asm"
        INCLUDE "lib/hardware.asm"
        INCLUDE "lib/ram.asm"

; -----------------------------------------------------------------------------
; ROM start.
; -----------------------------------------------------------------------------
        ORG ROM_START

; -----------------------------------------------------------------------------
; MSX cartridge header.
;
; $4000: "AB" marks an MSX cartridge ROM.
; $4002: init vector. The BIOS jumps here at cartridge startup.
; The other vectors are unused and set to zero.
; -----------------------------------------------------------------------------
ROM_Header:
        DB      "AB"
        DW      ROM_Init            ; INIT vector.
        DW      0                   ; CALL statement handler, unused.
        DW      0                   ; DEVICE handler, unused.
        DW      0                   ; BASIC text pointer, unused.
        DS      6,0                 ; Reserved bytes up to $4010.

; -----------------------------------------------------------------------------
; ROM_Init
; -----------------------------------------------------------------------------
; Entry point from the BIOS.
; -----------------------------------------------------------------------------
ROM_Init:
        DI
        LD      SP,STACK_TOP        ; Own stack, just below the BIOS work area.

        CALL    Game_Init

        EI                          ; HALT then waits for the VBlank interrupt.

; -----------------------------------------------------------------------------
; Game_MainLoop
; -----------------------------------------------------------------------------
; Simple fixed-frame loop:
;   1. HALT waits for the next interrupt.
;   2. Input/system/render/sound update.
;   3. Return to step 1.
; -----------------------------------------------------------------------------
Game_MainLoop:
        HALT
        CALL    Game_Update
        JP      Game_MainLoop

; -----------------------------------------------------------------------------
; Game_Init
; -----------------------------------------------------------------------------
; Initializes RAM, VDP, ECS, sound, and creates a demo player entity.
; -----------------------------------------------------------------------------
Game_Init:
        CALL    Runtime_Clear
        CALL    Drawing_InitScreen2
        CALL    ECS_Init
        CALL    Sound_Init

        ; Create player entity with position, velocity, sprite, and player component.
        LD      A,MASK_PLAYER_ENTITY
        CALL    ECS_CreateEntity
        JR      C,Game_Init_NoPlayer

        LD      (player_entity_id),A

        ; Start position roughly in the middle of the screen.
        LD      B,120               ; X
        LD      C,96                ; Y
        CALL    ECS_SetPosition

        ; Start without movement.
        LD      A,(player_entity_id)
        LD      B,0                 ; dx
        LD      C,0                 ; dy
        CALL    ECS_SetVelocity

        ; Sprite pattern 0, white color.
        LD      A,(player_entity_id)
        LD      B,0                 ; pattern index
        LD      C,COLOR_WHITE       ; sprite color
        CALL    ECS_SetSprite

Game_Init_NoPlayer:
        RET

; -----------------------------------------------------------------------------
; Game_Update
; -----------------------------------------------------------------------------
; The order is intentionally simple and predictable:
;   - Read input.
;   - Translate player input to velocity.
;   - Apply movement.
;   - Keep the player within screen bounds.
;   - Build and upload the sprite buffer.
;   - Update sound state.
; -----------------------------------------------------------------------------
Game_Update:
        CALL    Input_Update
        CALL    System_PlayerControl
        CALL    System_Move
        CALL    System_ClampPlayer
        CALL    System_RenderSprites
        CALL    Sound_Update
        RET

; -----------------------------------------------------------------------------
; Library code and ROM data.
; These includes generate code and/or fixed data in the ROM.
; -----------------------------------------------------------------------------
        INCLUDE "lib/utils.asm"
        INCLUDE "lib/input.asm"
        INCLUDE "lib/sound.asm"
        INCLUDE "lib/drawing.asm"
        INCLUDE "lib/ecs.asm"
        INCLUDE "lib/systems.asm"
        INCLUDE "lib/tiles.asm"

; -----------------------------------------------------------------------------
; Check ROM size and pad to exactly 16 KB.
; -----------------------------------------------------------------------------
ROM_End:
        ASSERT  $ <= ROM_LIMIT
        DS      ROM_LIMIT-$,$FF
