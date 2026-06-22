; =============================================================================
; lib/constants.asm
; -----------------------------------------------------------------------------
; Central constants for the MSX ECS framework.
;
; This file contains no code and no data. It only defines fixed values
; used by the other include files.
; =============================================================================

; -----------------------------------------------------------------------------
; ROM-layout
; -----------------------------------------------------------------------------
ROM_START               EQU $4000          ; MSX cartridge header starts here.
ROM_LIMIT               EQU $8000          ; End of a 16 KB ROM.
ROM_SIZE                EQU ROM_LIMIT-ROM_START

; -----------------------------------------------------------------------------
; RAM-layout
; -----------------------------------------------------------------------------
; USE_PAGE2_RAM = 1 uses RAM starting at $8000. This gives the most runtime space,
; but expects page 2 to be RAM. This is normal for many 32/64 KB MSX machines.
;
; Set USE_PAGE2_RAM to 0 if you want to be more conservative and only use page 3 RAM
; Then RAM_BASE starts at $C000.
USE_PAGE2_RAM           EQU 1

    IF USE_PAGE2_RAM
RAM_BASE                EQU $8000
    ELSE
RAM_BASE                EQU $C000
    ENDIF

; MSX BIOS/BASIC uses the upper part of page 3 as work area. The stack
; grows downward, so STACK_TOP remains well below the known BIOS work-area labels.
STACK_TOP               EQU $F380

; -----------------------------------------------------------------------------
; Screen mode and VRAM layout for SCREEN 2
; -----------------------------------------------------------------------------
SCREEN_MODE_G2          EQU 2

VRAM_PATTERN_0          EQU $0000          ; Pattern generator bank 0.
VRAM_PATTERN_1          EQU $0800          ; Pattern generator bank 1.
VRAM_PATTERN_2          EQU $1000          ; Pattern generator bank 2.
VRAM_NAME               EQU $1800          ; Name table: 32 x 24 = 768 bytes.
VRAM_SPRATR             EQU $1B00          ; Sprite attribute table.
VRAM_COLOR_0            EQU $2000          ; Color table bank 0.
VRAM_COLOR_1            EQU $2800          ; Color table bank 1.
VRAM_COLOR_2            EQU $3000          ; Color table bank 2.
VRAM_SPRPAT             EQU $3800          ; Sprite pattern table.

SCREEN2_WIDTH_TILES     EQU 32
SCREEN2_HEIGHT_TILES    EQU 24
SCREEN2_NAMETABLE_BYTES EQU SCREEN2_WIDTH_TILES*SCREEN2_HEIGHT_TILES
SCREEN2_VRAM_BYTES      EQU $4000          ; MSX1 VRAM in SCREEN 2.
TILEMAP_BYTES           EQU SCREEN2_NAMETABLE_BYTES

; -----------------------------------------------------------------------------
; Entity/component configuratie
; -----------------------------------------------------------------------------
MAX_ENTITIES            EQU 32             ; Fits nicely with the MSX sprite limit.
MAX_HW_SPRITES          EQU 32             ; TMS9918/MSX1 has 32 sprite entries.
SPRITE_ATTR_SIZE        EQU 4              ; Y, X, pattern, color.
SPRITE_ATTR_BYTES       EQU MAX_HW_SPRITES*SPRITE_ATTR_SIZE

; Component bitmasks. An entity has a component when the bit in ecs_flags
; is set. These values are powers of two, so combined masks may
; be created with +.
COMP_ALIVE              EQU $01
COMP_POSITION           EQU $02
COMP_VELOCITY           EQU $04
COMP_SPRITE             EQU $08
COMP_PLAYER             EQU $10
COMP_AI                 EQU $20
COMP_COLLIDER           EQU $40
COMP_USER               EQU $80

MASK_MOVABLE            EQU COMP_ALIVE+COMP_POSITION+COMP_VELOCITY
MASK_RENDERABLE         EQU COMP_ALIVE+COMP_POSITION+COMP_SPRITE
MASK_PLAYER_CONTROL     EQU COMP_ALIVE+COMP_PLAYER+COMP_VELOCITY
MASK_PLAYER_ENTITY      EQU COMP_ALIVE+COMP_POSITION+COMP_VELOCITY+COMP_SPRITE+COMP_PLAYER

; -----------------------------------------------------------------------------
; Tiles and sprites
; -----------------------------------------------------------------------------
TILE_EMPTY              EQU 0
TILE_WALL               EQU 1
TILE_FLOOR              EQU 2
TILE_MARKER             EQU 3
TILE_COUNT              EQU 4
TILE_BYTES              EQU 8
TILESET_BYTES           EQU TILE_COUNT*TILE_BYTES

SPRITE_PATTERN_COUNT    EQU 2
SPRITE_PATTERN_BYTES    EQU 8              ; One 8x8 sprite pattern is 8 bytes.
SPRITE_PATTERNS_BYTES   EQU SPRITE_PATTERN_COUNT*SPRITE_PATTERN_BYTES
SPRITE_Y_HIDE           EQU 209            ; Move sprite off-screen.

; Playfield bounds for the demo player.
PLAYER_MIN_X            EQU 8
PLAYER_MAX_X            EQU 240
PLAYER_MIN_Y            EQU 8
PLAYER_MAX_Y            EQU 184

; -----------------------------------------------------------------------------
; MSX color values
; -----------------------------------------------------------------------------
COLOR_TRANSPARENT       EQU 0
COLOR_BLACK             EQU 1
COLOR_MEDIUM_GREEN      EQU 2
COLOR_LIGHT_GREEN       EQU 3
COLOR_DARK_BLUE         EQU 4
COLOR_LIGHT_BLUE        EQU 5
COLOR_DARK_RED          EQU 6
COLOR_CYAN              EQU 7
COLOR_MEDIUM_RED        EQU 8
COLOR_LIGHT_RED         EQU 9
COLOR_DARK_YELLOW       EQU 10
COLOR_LIGHT_YELLOW      EQU 11
COLOR_DARK_GREEN        EQU 12
COLOR_MAGENTA           EQU 13
COLOR_GRAY              EQU 14
COLOR_WHITE             EQU 15

; Color table bytes: high nibble = foreground, low nibble = background.
COLORPAIR_WHITE_BLACK   EQU $F1
COLORPAIR_BLUE_BLACK    EQU $41
COLORPAIR_GREEN_BLACK   EQU $31
COLORPAIR_YELLOW_BLACK  EQU $B1
