; =============================================================================
; lib/ram.asm
; -----------------------------------------------------------------------------
; Runtime RAM layout.
;
; This file only uses EQU expressions. There is no ORG and no DS in
; this file. Therefore these labels become addresses in RAM without adding bytes to the
; ROM file.
;
; It is not a RAM reservation, only a layout. We declare all variables 
; here. When you write to RAM in other places, you overwrite this 
; structure. The only enforced rule is that this area does not enter your stack.
; 
;
; RAM_START is determined by RAM_BASE from constants.asm. By default, this is
; $8000, so page 2 can be used as runtime RAM.
; =============================================================================

RAM_START               EQU RAM_BASE

; -----------------------------------------------------------------------------
; Input state
; -----------------------------------------------------------------------------
input_dir               EQU RAM_START+0        ; Raw BIOS_GTSTCK direction 0..8.
input_dx                EQU input_dir+1        ; Signed dx: $FF, 0, 1.
input_dy                EQU input_dx+1         ; Signed dy: $FF, 0, 1.
input_fire              EQU input_dy+1         ; $00 of $FF.
input_fire_prev         EQU input_fire+1       ; Previous frame fire state.
input_fire_pressed      EQU input_fire_prev+1  ; One frame $FF on new press.

; -----------------------------------------------------------------------------
; Game state
; -----------------------------------------------------------------------------
player_entity_id        EQU input_fire_pressed+1 ; $FF = no player.

; -----------------------------------------------------------------------------
; Sound state
; -----------------------------------------------------------------------------
; RAM variables used by lib/sound.asm.
; Keep this layout in sync with the standalone definitions in soundtester.asm.
sound_music_enabled     EQU player_entity_id+1   ; 0 = music off, 1 = music on.
sound_music_tick        EQU sound_music_enabled+1 ; Free-running music tick counter.
sound_music_a_ptr       EQU sound_music_tick+1   ; Word pointer into channel A music data.
sound_music_a_wait      EQU sound_music_a_ptr+2  ; Frames until channel A reads the next command.
sound_music_b_ptr       EQU sound_music_a_wait+1 ; Word pointer into channel B music data.
sound_music_b_wait      EQU sound_music_b_ptr+2  ; Frames until channel B reads the next command.
sound_duration          EQU sound_music_b_wait+1 ; SFX duration in frames.
sound_sfx_volume        EQU sound_duration+1     ; Current SFX volume.
sound_sfx_noise         EQU sound_sfx_volume+1   ; Current SFX noise period.
sound_mute_a            EQU sound_sfx_noise+1    ; 0 = channel A audible, 1 = muted.
sound_mute_b            EQU sound_mute_a+1       ; 0 = channel B audible, 1 = muted.
sound_mute_c            EQU sound_mute_b+1       ; 0 = channel C audible, 1 = muted.
sound_ram_start         EQU sound_music_enabled
sound_ram_end           EQU sound_mute_c+1

; -----------------------------------------------------------------------------
; Render temp state
; -----------------------------------------------------------------------------
render_dst              EQU sound_ram_end        ; Word pointer in sprite_attr_buffer.
render_sprite_count     EQU render_dst+2         ; Number of sprites in buffer.

; -----------------------------------------------------------------------------
; ECS component arrays
; -----------------------------------------------------------------------------
; Entity ID = index in each array.
; ecs_flags determines which components are active.
; -----------------------------------------------------------------------------
ecs_ram_start           EQU render_sprite_count+1
ecs_flags               EQU ecs_ram_start
ecs_pos_x               EQU ecs_flags+MAX_ENTITIES
ecs_pos_y               EQU ecs_pos_x+MAX_ENTITIES
ecs_vel_x               EQU ecs_pos_y+MAX_ENTITIES
ecs_vel_y               EQU ecs_vel_x+MAX_ENTITIES
ecs_sprite_pattern      EQU ecs_vel_y+MAX_ENTITIES
ecs_sprite_color        EQU ecs_sprite_pattern+MAX_ENTITIES
ecs_ram_end             EQU ecs_sprite_color+MAX_ENTITIES

; -----------------------------------------------------------------------------
; Sprite attribute buffer
; -----------------------------------------------------------------------------
; Built every frame from ECS data and then copied to VRAM in one block.
; -----------------------------------------------------------------------------
sprite_attr_buffer      EQU ecs_ram_end
RAM_END                 EQU sprite_attr_buffer+SPRITE_ATTR_BYTES

; Safety check: runtime RAM may not touch the stack/BIOS work area.
        ASSERT RAM_END < STACK_TOP
