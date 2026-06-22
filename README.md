# MSX Z80 ECS Framework

Starter framework for an MSX game in Z80 assembly with an Entity Component System-like structure.
A fun excersize for me in order to learn ASM and to learn programming for the MSX1

This version has been cleaned up for **SjASMPlus v20190306.1**:

- no `OUTPUT` in the source;
- no `SAVEBIN`;
- no `OUTEND`;
- no directives in column 1;
- consistent label names across all includes.

## Build

Windows:

```bat
buildAll
buildSound
```

Manual build:

```bat
sjasmplus game.asm --raw=game.rom
```

Linux/macOS:

```sh
./build.sh
```

After a successful build, this file will be created in the same directory:

```text
game.rom
```

After a successful build for the soundtester, this file will be created in the same directory:

```text
soundtester.rom
```

Expected size:

```text
16384 bytes
```

For example, test it in openMSX:

```bat
openmsx -cart game.rom
```

## Why `--raw=game.rom`?

With my SjASMPlus version, output through source directives caused problems. Therefore, the build writes the ROM with this command-line option:

```bat
sjasmplus game.asm --raw=game.rom
```

`game.asm` starts at `ORG $4000`, emits the MSX cartridge header, and pads the ROM at the end with:

```asm
        DS      ROM_LIMIT-$,$FF
```

This makes the output exactly 16 KB.

## Why ROM instead of BIN?

This project uses a **16 KB ROM** at `$4000-$7FFF`.

The fixed code, tiles, tilemap, and sprite patterns are stored in ROM. RAM remains free for runtime data: entities, component arrays, input state, sound state, and sprite buffers. Because this is not a 32 KB ROM, page 2 (`$8000-$BFFF`) remains available as RAM on machines where that page contains RAM.

By default, the framework uses RAM starting at `$8000`. This gives the most workspace. You can change this in `lib/constants.asm`:

```asm
USE_PAGE2_RAM           EQU 1      ; maximum RAM starting at $8000
USE_PAGE2_RAM           EQU 0      ; more conservative RAM starting at $C000
```

## File overview

```text
game.asm              Main file, ROM header, game loop, include list
lib/constants.asm     Global constants, component masks, VRAM layout
lib/bios.asm          MSX BIOS jump-table addresses
lib/hardware.asm      VDP/PSG port addresses
lib/ram.asm           Runtime RAM layout through EQU, costs no ROM bytes
lib/utils.asm         MemFill, MemClear, runtime clear
lib/input.asm         Cursor/joystick/fire input
lib/sound.asm         Small PSG blip/sound update
lib/drawing.asm       Screen 2, tiles, sprites, VRAM uploads
lib/ecs.asm           Entity create/destroy and component accessors
lib/systems.asm       Player, movement, and sprite render systems
lib/tiles.asm         Demo tiles, tilemap, and sprite patterns
build.bat             Windows build through --raw=game.rom
build.cmd             Same as build.bat
build.ps1             PowerShell build through --raw=game.rom
build.sh              Unix shell build through --raw=game.rom
```

## Label convention

To prevent label confusion, this version uses one consistent convention:

```text
Drawing_InitScreen2          code label
Drawing_UploadSpriteBuffer   code label
TilePatterns                 ROM data label
TilePatterns_End             end of ROM data label
BIOS_CHGMOD                  BIOS constant
VRAM_PATTERN_0               VRAM constant
player_entity_id             RAM variable
```

## ECS model

Each entity is an index from `0` to `MAX_ENTITIES-1`.

Components are stored in separate arrays:

```asm
ecs_flags[id]
ecs_pos_x[id]
ecs_pos_y[id]
ecs_vel_x[id]
ecs_vel_y[id]
ecs_sprite_pattern[id]
ecs_sprite_color[id]
```

`ecs_flags[id]` contains bits such as:

```asm
COMP_ALIVE
COMP_POSITION
COMP_VELOCITY
COMP_SPRITE
COMP_PLAYER
```

Systems iterate over all entities and test masks such as `MASK_MOVABLE` or `MASK_RENDERABLE`.

## Demo

After startup, you see a simple Screen 2 tilemap with a border. The player sprite is in the center.

Controls:

- Cursor keys or joystick 1 move the player.
- Space or joystick 1 button A plays a short PSG blip.

## Extending

Planned next steps:

- Use `COMP_COLLIDER` and add `System_Collision`.
- Add animation arrays, for example `ecs_anim_frame` and `ecs_anim_timer`.
- Create an enemy spawner with `ECS_CreateEntity`.
- Replace tile data and the tilemap with `INCBIN` output from an editor/converter.
- Replace the PSG blip with a real music/SFX player.
- For larger games, ROM bank switching can be implemented. This 16 KB variant is intentionally chosen for maximum simple runtime RAM space.
