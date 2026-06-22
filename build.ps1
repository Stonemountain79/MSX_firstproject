# -----------------------------------------------------------------------------
# build.ps1
# -----------------------------------------------------------------------------
# PowerShell build script for SjASMPlus v20190306.1.
# -----------------------------------------------------------------------------

$ErrorActionPreference = "Stop"

$asmCandidates = @(
    "..\..\..\..\assembler\sjasmplus.exe",
    "..\..\..\..\assembler\sjasmplus",
    "..\..\..\assembler\sjasmplus.exe",
    "..\..\..\assembler\sjasmplus",
    "sjasmplus"
)

$asm = $asmCandidates | Where-Object {
    ($_ -eq "sjasmplus") -or (Test-Path $_)
} | Select-Object -First 1

if (Test-Path "game.rom") {
    Remove-Item "game.rom"
}

Write-Host "$asm game.asm --raw=game.rom"
& $asm game.asm --raw=game.rom

if ($LASTEXITCODE -ne 0) {
    throw "Build failed."
}

if (!(Test-Path "game.rom")) {
    throw "game.rom was not created. Use: sjasmplus game.asm --raw=game.rom"
}

$rom = Get-Item "game.rom"
Write-Host ""
Write-Host "ROM created: $($rom.FullName)"
Write-Host "Size: $($rom.Length) bytes"

if ($rom.Length -ne 16384) {
    throw "Expected 16384 bytes for a 16 KB ROM."
}
