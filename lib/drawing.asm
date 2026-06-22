; =============================================================================
; lib/drawing.asm
; -----------------------------------------------------------------------------
; Drawing and VRAM upload routines.
;
; This file does three things:
;   1. Initialize SCREEN 2.
;   2. Copy tiles, tilemap, and sprite patterns from ROM to VRAM.
;   3. Upload the sprite attribute buffer from RAM to VRAM.
;
; For clarity, we use BIOS routines FILVRM/LDIRVM/WRTVRM. This is
; not the fastest method, but it is safe and easy to understand.
; =============================================================================

; -----------------------------------------------------------------------------
; Drawing_InitScreen2
; -----------------------------------------------------------------------------
; Enables SCREEN 2 and uploads all demo graphics.
;
; Input : none
; Output: VRAM filled with tile patterns, tile colors, tilemap, and sprites
; Modifies: all registers through BIOS calls
; -----------------------------------------------------------------------------
Drawing_InitScreen2:
        CALL    BIOS_DISSCR

        ; Basic colors: white on black, black border.
        LD      A,COLOR_WHITE
        LD      (BIOS_FORCLR),A
        LD      A,COLOR_BLACK
        LD      (BIOS_BAKCLR),A
        LD      (BIOS_BDRCLR),A

        ; Set MSX to SCREEN 2 and apply colors.
        LD      A,SCREEN_MODE_G2
        CALL    BIOS_CHGMOD
        CALL    BIOS_CHGCLR
        CALL    BIOS_CLRSPR

        ; Clear VRAM. SCREEN 2 uses 16 KB VRAM on MSX1.
        LD      HL,$0000
        LD      BC,SCREEN2_VRAM_BYTES
        XOR     A
        CALL    BIOS_FILVRM

        CALL    Drawing_LoadTiles
        CALL    Drawing_LoadTileMap
        CALL    Drawing_LoadSpritePatterns
        CALL    Drawing_ClearSpriteBuffer
        CALL    Drawing_UploadSpriteBuffer

        CALL    BIOS_ENASCR
        RET

; -----------------------------------------------------------------------------
; Drawing_LoadTiles
; -----------------------------------------------------------------------------
; Copies tile patterns and tile colors to all three SCREEN 2 thirds.
;
; In SCREEN 2, each vertical third has its own pattern/color bank. If you
; want tile index 1 to be the same everywhere, you must copy the tile data three times
; copy.
;
; Input : TilePatterns en TileColors in ROM
; Output: VRAM pattern/color tables filled
; Modifies: all registers through BIOS_LDIRVM
; -----------------------------------------------------------------------------
Drawing_LoadTiles:
        ; Pattern bank 0: screen rows 0..7 tiles.
        LD      HL,TilePatterns
        LD      DE,VRAM_PATTERN_0
        LD      BC,TilePatterns_End-TilePatterns
        CALL    BIOS_LDIRVM

        ; Pattern bank 1: screen rows 8..15 tiles.
        LD      HL,TilePatterns
        LD      DE,VRAM_PATTERN_1
        LD      BC,TilePatterns_End-TilePatterns
        CALL    BIOS_LDIRVM

        ; Pattern bank 2: screen rows 16..23 tiles.
        LD      HL,TilePatterns
        LD      DE,VRAM_PATTERN_2
        LD      BC,TilePatterns_End-TilePatterns
        CALL    BIOS_LDIRVM

        ; Color bank 0.
        LD      HL,TileColors
        LD      DE,VRAM_COLOR_0
        LD      BC,TileColors_End-TileColors
        CALL    BIOS_LDIRVM

        ; Color bank 1.
        LD      HL,TileColors
        LD      DE,VRAM_COLOR_1
        LD      BC,TileColors_End-TileColors
        CALL    BIOS_LDIRVM

        ; Color bank 2.
        LD      HL,TileColors
        LD      DE,VRAM_COLOR_2
        LD      BC,TileColors_End-TileColors
        CALL    BIOS_LDIRVM
        RET

; -----------------------------------------------------------------------------
; Drawing_LoadTileMap
; -----------------------------------------------------------------------------
; Copies the 32x24 tilemap to the SCREEN 2 name table.
;
; Input : DemoTileMap in ROM
; Output: VRAM name table filled
; Modifies: all registers through BIOS_LDIRVM
; -----------------------------------------------------------------------------
Drawing_LoadTileMap:
        LD      HL,DemoTileMap
        LD      DE,VRAM_NAME
        LD      BC,DemoTileMap_End-DemoTileMap
        CALL    BIOS_LDIRVM
        RET

; -----------------------------------------------------------------------------
; Drawing_LoadSpritePatterns
; -----------------------------------------------------------------------------
; Copies sprite patterns to VRAM.
;
; In this demo we use 8x8 sprites. Pattern index 0 is the player ship.
; Later, you can add more sprite patterns in lib/tiles.asm.
; -----------------------------------------------------------------------------
Drawing_LoadSpritePatterns:
        LD      HL,SpritePatterns
        LD      DE,VRAM_SPRPAT
        LD      BC,SpritePatterns_End-SpritePatterns
        CALL    BIOS_LDIRVM
        RET

; -----------------------------------------------------------------------------
; Drawing_ClearSpriteBuffer
; -----------------------------------------------------------------------------
; Hides all sprites in the RAM buffer.
;
; MSX/TMS9918 sprites are hidden when Y is off-screen. The buffer is
; then copied to VRAM with Drawing_UploadSpriteBuffer.
;
; Input : none
; Output: sprite_attr_buffer filled
; Modifies: AF, B, HL
; -----------------------------------------------------------------------------
Drawing_ClearSpriteBuffer:
        LD      HL,sprite_attr_buffer
        LD      B,MAX_HW_SPRITES

Drawing_ClearSpriteBuffer_Loop:
        LD      (HL),SPRITE_Y_HIDE  ; Y off-screen.
        INC     HL
        LD      (HL),0              ; X.
        INC     HL
        LD      (HL),0              ; Pattern.
        INC     HL
        LD      (HL),0              ; Color.
        INC     HL
        DJNZ    Drawing_ClearSpriteBuffer_Loop
        RET

; -----------------------------------------------------------------------------
; Drawing_UploadSpriteBuffer
; -----------------------------------------------------------------------------
; Uploads the complete sprite attribute buffer to VRAM.
;
; Input : sprite_attr_buffer in RAM
; Output: VRAM sprite attribute table updated
; Modifies: all registers through BIOS_LDIRVM
; -----------------------------------------------------------------------------
Drawing_UploadSpriteBuffer:
        LD      HL,sprite_attr_buffer
        LD      DE,VRAM_SPRATR
        LD      BC,SPRITE_ATTR_BYTES
        CALL    BIOS_LDIRVM
        RET

; -----------------------------------------------------------------------------
; Drawing_SetTile
; -----------------------------------------------------------------------------
; Sets one tile directly in the VRAM name table.
;
; Input : A = tile index
;         B = x tile coordinate 0..31
;         C = y tile coordinate 0..23
; Output: 1 byte written to VRAM
; Modifies: AF, DE, HL
;
; This routine is useful for later gameplay, for example destructible tiles.
; For large tilemap updates, a RAM tilemap + BIOS_LDIRVM is faster.
; -----------------------------------------------------------------------------
Drawing_SetTile:
        PUSH    AF                  ; Save tile index.

        ; HL = y * 32. Because 32 = 2^5, we can double 5 times.
        LD      A,C
        LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL

        ; HL = y * 32 + x.
        LD      E,B
        LD      D,0
        ADD     HL,DE

        ; HL = VRAM_NAME + offset.
        LD      DE,VRAM_NAME
        ADD     HL,DE

        POP     AF
        CALL    BIOS_WRTVRM
        RET
