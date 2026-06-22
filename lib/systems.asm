; =============================================================================
; lib/systems.asm
; -----------------------------------------------------------------------------
; ECS systems.
;
; A system is a routine that iterates over entities/components and applies behavior
; This file contains four small systems:
;   - System_PlayerControl: input -> player velocity.
;   - System_Move:          position += velocity.
;   - System_ClampPlayer:   keep player within screen.
;   - System_RenderSprites: ECS sprite components -> MSX sprite buffer.
;
; Extension ideas:
;   - System_AI
;   - System_Collision
;   - System_Animation
;   - System_Lifetime
; =============================================================================

; -----------------------------------------------------------------------------
; System_PlayerControl
; -----------------------------------------------------------------------------
; Set the velocity of the player entity based on input_dx/input_dy. Plays a
; short blip when fire has just been pressed.
; -----------------------------------------------------------------------------
System_PlayerControl:
        LD      A,(player_entity_id)
        CP      $FF
        RET     Z                   ; No player created yet.

        PUSH    AF                  ; Save entity id.
        LD      A,(input_dx)
        LD      B,A
        LD      A,(input_dy)
        LD      C,A
        POP     AF
        CALL    ECS_SetVelocity

        LD      A,(input_fire_pressed)
        OR      A
        RET     Z

        CALL    Sound_PlayBlip
        RET

; -----------------------------------------------------------------------------
; System_Move
; -----------------------------------------------------------------------------
; For all entities with ALIVE + POSITION + VELOCITY:
;   pos_x += vel_x
;   pos_y += vel_y
;
; Velocity is a signed byte, so $FF works as -1 through 8-bit overflow.
; -----------------------------------------------------------------------------
System_Move:
        LD      B,MAX_ENTITIES
        LD      C,0                 ; C = entity id.

System_Move_Loop:
        LD      A,C
        LD      HL,ecs_flags
        CALL    ECS_GetByteAt
        AND     MASK_MOVABLE
        CP      MASK_MOVABLE
        JR      NZ,System_Move_Next

        ; Update X position.
        LD      A,C
        LD      HL,ecs_vel_x
        CALL    ECS_GetByteAt
        LD      E,A                 ; E = dx.
        PUSH    DE                  ; Save dx, because ECS_IndexHL uses DE.

        LD      A,C
        LD      HL,ecs_pos_x
        CALL    ECS_IndexHL
        POP     DE
        LD      A,(HL)
        ADD     A,E
        LD      (HL),A

        ; Update Y position.
        LD      A,C
        LD      HL,ecs_vel_y
        CALL    ECS_GetByteAt
        LD      E,A                 ; E = dy.
        PUSH    DE

        LD      A,C
        LD      HL,ecs_pos_y
        CALL    ECS_IndexHL
        POP     DE
        LD      A,(HL)
        ADD     A,E
        LD      (HL),A

System_Move_Next:
        INC     C
        DJNZ    System_Move_Loop
        RET

; -----------------------------------------------------------------------------
; System_ClampPlayer
; -----------------------------------------------------------------------------
; Keep the demo player within the visible screen 2 bounds.
; -----------------------------------------------------------------------------
System_ClampPlayer:
        LD      A,(player_entity_id)
        CP      $FF
        RET     Z

        LD      C,A                 ; C = player entity id.

        ; X clamp.
        LD      A,C
        LD      HL,ecs_pos_x
        CALL    ECS_IndexHL
        LD      A,(HL)
        CP      PLAYER_MIN_X
        JR      NC,System_ClampPlayer_CheckMaxX
        LD      A,PLAYER_MIN_X
        LD      (HL),A
        JR      System_ClampPlayer_ClampY

System_ClampPlayer_CheckMaxX:
        CP      PLAYER_MAX_X+1
        JR      C,System_ClampPlayer_ClampY
        LD      A,PLAYER_MAX_X
        LD      (HL),A

System_ClampPlayer_ClampY:
        LD      A,C
        LD      HL,ecs_pos_y
        CALL    ECS_IndexHL
        LD      A,(HL)
        CP      PLAYER_MIN_Y
        JR      NC,System_ClampPlayer_CheckMaxY
        LD      A,PLAYER_MIN_Y
        LD      (HL),A
        RET

System_ClampPlayer_CheckMaxY:
        CP      PLAYER_MAX_Y+1
        RET     C
        LD      A,PLAYER_MAX_Y
        LD      (HL),A
        RET

; -----------------------------------------------------------------------------
; System_RenderSprites
; -----------------------------------------------------------------------------
; Builds the MSX sprite attribute buffer from ECS component arrays and uploads it
; to VRAM.
;
; Renderable entity mask:
;   COMP_ALIVE + COMP_POSITION + COMP_SPRITE
; -----------------------------------------------------------------------------
System_RenderSprites:
        CALL    Drawing_ClearSpriteBuffer

        LD      HL,sprite_attr_buffer
        LD      (render_dst),HL
        XOR     A
        LD      (render_sprite_count),A

        LD      B,MAX_ENTITIES
        LD      C,0                 ; C = entity id.

System_RenderSprites_Loop:
        ; Does this entity have the required components?
        LD      A,C
        LD      HL,ecs_flags
        CALL    ECS_GetByteAt
        AND     MASK_RENDERABLE
        CP      MASK_RENDERABLE
        JR      NZ,System_RenderSprites_Next

        ; Hardware has at most 32 sprite entries.
        LD      A,(render_sprite_count)
        CP      MAX_HW_SPRITES
        JR      NC,System_RenderSprites_Upload

        ; Destination pointer for this sprite entry.
        LD      HL,(render_dst)

        ; Byte 0: Y - 1. MSX sprites use Y-1 encoding.
        PUSH    HL
        LD      A,C
        LD      HL,ecs_pos_y
        CALL    ECS_GetByteAt
        DEC     A
        POP     HL
        LD      (HL),A
        INC     HL

        ; Byte 1: X.
        PUSH    HL
        LD      A,C
        LD      HL,ecs_pos_x
        CALL    ECS_GetByteAt
        POP     HL
        LD      (HL),A
        INC     HL

        ; Byte 2: sprite pattern index.
        PUSH    HL
        LD      A,C
        LD      HL,ecs_sprite_pattern
        CALL    ECS_GetByteAt
        POP     HL
        LD      (HL),A
        INC     HL

        ; Byte 3: sprite color.
        PUSH    HL
        LD      A,C
        LD      HL,ecs_sprite_color
        CALL    ECS_GetByteAt
        POP     HL
        LD      (HL),A
        INC     HL

        ; Next sprite entry.
        LD      (render_dst),HL
        LD      A,(render_sprite_count)
        INC     A
        LD      (render_sprite_count),A

System_RenderSprites_Next:
        INC     C
        DJNZ    System_RenderSprites_Loop

System_RenderSprites_Upload:
        CALL    Drawing_UploadSpriteBuffer
        RET
