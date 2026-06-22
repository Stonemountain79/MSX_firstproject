; =============================================================================
; lib/bios.asm
; -----------------------------------------------------------------------------
; MSX BIOS jump-table addresses and BIOS work-area variables.
;
; These routines are in the MSX main ROM. Because this framework runs as a cartridge ROM
; the BIOS jump table remains visible in page 0 and we can CALL these
; addresses directly.
;
; Naming convention in this project: all BIOS routines have the BIOS_ prefix.
; So use, for example, CALL BIOS_CHGMOD, not CALL CHGMOD.
; =============================================================================

; -----------------------------------------------------------------------------
; Display/VDP BIOS routines
; -----------------------------------------------------------------------------
BIOS_DISSCR             EQU $0041          ; Disable screen output.
BIOS_ENASCR             EQU $0044          ; Enable screen output.
BIOS_WRTVDP             EQU $0047          ; B=value, C=VDP register.
BIOS_RDVRM              EQU $004A          ; HL=VRAM address, output A=byte.
BIOS_WRTVRM             EQU $004D          ; HL=VRAM address, A=byte.
BIOS_SETRD              EQU $0050          ; Set VRAM read address.
BIOS_SETWRT             EQU $0053          ; Set VRAM write address.
BIOS_FILVRM             EQU $0056          ; HL=VRAM, BC=len, A=value.
BIOS_LDIRMV             EQU $0059          ; VRAM -> memory. HL=VRAM, DE=RAM, BC=len.
BIOS_LDIRVM             EQU $005C          ; Memory -> VRAM. HL=RAM/ROM, DE=VRAM, BC=len.
BIOS_CHGMOD             EQU $005F          ; A=screen mode.
BIOS_CHGCLR             EQU $0062          ; Apply colors from work area.
BIOS_CLRSPR             EQU $0069          ; Initialize sprite tables.
BIOS_WRTPSG             EQU $0093     	   ; A = PSG register, E = value

; -----------------------------------------------------------------------------
; Controller BIOS routines
; -----------------------------------------------------------------------------
BIOS_GTSTCK             EQU $00D5          ; A=0 cursors, 1 joy1, 2 joy2. Output A=0..8.
BIOS_GTTRIG             EQU $00D8          ; A=0 space, 1 joy1 A, 2 joy2 A, etc.

; -----------------------------------------------------------------------------
; BIOS work-area variables
; -----------------------------------------------------------------------------
BIOS_FORCLR             EQU $F3E9          ; Foreground color.
BIOS_BAKCLR             EQU $F3EA          ; Background color.
BIOS_BDRCLR             EQU $F3EB          ; Border color.
BIOS_JIFFY              EQU $FC9E          ; 60/50 Hz tick-counter.
