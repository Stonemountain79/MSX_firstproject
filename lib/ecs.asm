; =============================================================================
; lib/ecs.asm
; -----------------------------------------------------------------------------
; Entity Component System core.
;
; This ECS uses a data-oriented layout:
;   - No structs per entity.
;   - One array per component: ecs_pos_x[], ecs_pos_y[], ecs_vel_x[], enz.
;   - Entity ID = array-index 0..MAX_ENTITIES-1.
;
; Why this layout on Z80?
;   - Iterating through arrays is simple.
;   - Component data is compact in RAM.
;   - Systems can touch exactly the component arrays they need.
;
; ecs_flags[id] contains the component bitmask for each entity.
; =============================================================================

; -----------------------------------------------------------------------------
; ECS_Init
; -----------------------------------------------------------------------------
; Clears all ECS component arrays.
; -----------------------------------------------------------------------------
ECS_Init:
        LD      HL,ecs_ram_start
        LD      BC,ecs_ram_end-ecs_ram_start
        XOR     A
        CALL    MemFill
        RET

; -----------------------------------------------------------------------------
; ECS_IndexHL
; -----------------------------------------------------------------------------
; Add entity ID A to base address HL.
;
; Input : A=entity id, HL=base address of component array
; Output: HL=base address + entity id
; Modifies: DE, HL
; Preserves: A, BC
; -----------------------------------------------------------------------------
ECS_IndexHL:
        LD      E,A
        LD      D,0
        ADD     HL,DE
        RET

; -----------------------------------------------------------------------------
; ECS_GetByteAt
; -----------------------------------------------------------------------------
; Read one component byte from a component array.
;
; Input : A=entity id, HL=base address of component array
; Output: A=component value, HL=address of component value
; Modifies: AF, DE, HL
; Preserves: BC
; -----------------------------------------------------------------------------
ECS_GetByteAt:
        CALL    ECS_IndexHL
        LD      A,(HL)
        RET

; -----------------------------------------------------------------------------
; ECS_SetByteAt
; -----------------------------------------------------------------------------
; Write one component byte into a component array.
;
; Input : A=entity id, HL=base address of component array, B=value
; Output: HL=address of component value
; Modifies: DE, HL
; Preserves: A, BC
; -----------------------------------------------------------------------------
ECS_SetByteAt:
        CALL    ECS_IndexHL
        LD      (HL),B
        RET

; -----------------------------------------------------------------------------
; ECS_CreateEntity
; -----------------------------------------------------------------------------
; Find a free entity slot and set the requested component mask.
;
; Input : A=component mask, usually including COMP_ALIVE
; Output: Carry clear: success, A=entity id
;         Carry set:   no free entity, A=$FF
; Modifies: AF, BC, DE, HL
; -----------------------------------------------------------------------------
ECS_CreateEntity:
        LD      E,A                 ; E = requested component mask.
        LD      HL,ecs_flags
        LD      B,MAX_ENTITIES
        LD      C,0                 ; C = current entity id.

ECS_CreateEntity_Loop:
        LD      A,(HL)
        OR      A
        JR      Z,ECS_CreateEntity_Found
        INC     HL
        INC     C
        DJNZ    ECS_CreateEntity_Loop

        ; No free slot found.
        LD      A,$FF
        SCF
        RET

ECS_CreateEntity_Found:
        LD      (HL),E              ; Activate entity with requested components.
        LD      A,C                 ; A = entity id.

        ; Clear old component data in the same slot. This prevents a
        ; reused entity from inheriting old position/sprite/velocity values.
        PUSH    AF
        CALL    ECS_ClearEntityData
        POP     AF

        OR      A                   ; Clear carry for success.
        RET

; -----------------------------------------------------------------------------
; ECS_DestroyEntity
; -----------------------------------------------------------------------------
; Set the flags of an entity to 0. Data may remain; without COMP_ALIVE
; systems no longer include the entity.
;
; Input : A=entity id
; Modifies: AF, B, DE, HL
; -----------------------------------------------------------------------------
ECS_DestroyEntity:
        LD      B,0
        LD      HL,ecs_flags
        CALL    ECS_SetByteAt
        RET

; -----------------------------------------------------------------------------
; ECS_ClearEntityData
; -----------------------------------------------------------------------------
; Clears the component values of one entity, except ecs_flags.
;
; Input : A=entity id
; Modifies: AF, B, DE, HL
; -----------------------------------------------------------------------------
ECS_ClearEntityData:
        PUSH    AF
        LD      B,0
        LD      HL,ecs_pos_x
        CALL    ECS_SetByteAt
        POP     AF

        PUSH    AF
        LD      B,0
        LD      HL,ecs_pos_y
        CALL    ECS_SetByteAt
        POP     AF

        PUSH    AF
        LD      B,0
        LD      HL,ecs_vel_x
        CALL    ECS_SetByteAt
        POP     AF

        PUSH    AF
        LD      B,0
        LD      HL,ecs_vel_y
        CALL    ECS_SetByteAt
        POP     AF

        PUSH    AF
        LD      B,0
        LD      HL,ecs_sprite_pattern
        CALL    ECS_SetByteAt
        POP     AF

        PUSH    AF
        LD      B,0
        LD      HL,ecs_sprite_color
        CALL    ECS_SetByteAt
        POP     AF
        RET

; -----------------------------------------------------------------------------
; ECS_SetPosition
; -----------------------------------------------------------------------------
; Input : A=entity id, B=X position, C=Y position
; Modifies: AF, B, DE, HL
; -----------------------------------------------------------------------------
ECS_SetPosition:
        PUSH    AF
        PUSH    BC
        LD      HL,ecs_pos_x
        CALL    ECS_SetByteAt       ; B contains X.
        POP     BC
        POP     AF

        LD      B,C                 ; B = Y for ECS_SetByteAt.
        LD      HL,ecs_pos_y
        CALL    ECS_SetByteAt
        RET

; -----------------------------------------------------------------------------
; ECS_SetVelocity
; -----------------------------------------------------------------------------
; Input : A=entity id, B=dx signed byte, C=dy signed byte
; Modifies: AF, B, DE, HL
; -----------------------------------------------------------------------------
ECS_SetVelocity:
        PUSH    AF
        PUSH    BC
        LD      HL,ecs_vel_x
        CALL    ECS_SetByteAt       ; B contains dx.
        POP     BC
        POP     AF

        LD      B,C                 ; B = dy.
        LD      HL,ecs_vel_y
        CALL    ECS_SetByteAt
        RET

; -----------------------------------------------------------------------------
; ECS_SetSprite
; -----------------------------------------------------------------------------
; Input : A=entity id, B=sprite pattern index, C=sprite color
; Modifies: AF, B, DE, HL
; -----------------------------------------------------------------------------
ECS_SetSprite:
        PUSH    AF
        PUSH    BC
        LD      HL,ecs_sprite_pattern
        CALL    ECS_SetByteAt       ; B contains pattern index.
        POP     BC
        POP     AF

        LD      B,C                 ; B = color.
        LD      HL,ecs_sprite_color
        CALL    ECS_SetByteAt
        RET
