; =============================================================================
; lib/hardware.asm
; -----------------------------------------------------------------------------
; Hardware ports for MSX1/MSX2-compatible VDP and PSG access.
;
; This framework mostly uses BIOS routines for drawing. The sound system
; writes directly to the PSG ports, because that is short and clear.
; =============================================================================

VDP_DATA_PORT           EQU $98            ; VDP data port.
VDP_CTRL_PORT           EQU $99            ; VDP control/register port.

PSG_REG_PORT            EQU $A0            ; Select PSG register.
PSG_DATA_PORT           EQU $A1            ; Write PSG register value.
PSG_READ_PORT           EQU $A2            ; Read PSG register value.
