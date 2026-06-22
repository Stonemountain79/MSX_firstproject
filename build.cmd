@echo off
setlocal

rem -----------------------------------------------------------------------------
rem build.bat
rem -----------------------------------------------------------------------------
rem Build script for SjASMPlus v20190306.1.
rem
rem We use --raw=game.rom instead of OUTPUT/SAVEBIN in the source.
rem This prevents version differences in output directives.
rem -----------------------------------------------------------------------------

set "ASM=..\..\..\..\assembler\sjasmplus.exe"
if not exist "%ASM%" set "ASM=..\..\..\..\assembler\sjasmplus"
if not exist "%ASM%" set "ASM=..\..\..\assembler\sjasmplus.exe"
if not exist "%ASM%" set "ASM=..\..\..\assembler\sjasmplus"
if not exist "%ASM%" set "ASM=sjasmplus"

if exist game.rom del game.rom

echo %ASM% game.asm --raw=game.rom
"%ASM%" game.asm --raw=game.rom
if errorlevel 1 (
    echo.
    echo Build failed.
    exit /b 1
)

if not exist game.rom (
    echo.
    echo ERROR: game.rom was not created.
    echo Use manually: sjasmplus game.asm --raw=game.rom
    exit /b 1
)

for %%A in (game.rom) do (
    echo.
    echo ROM created: %%~fA
    echo Size: %%~zA bytes
    if not "%%~zA"=="16384" (
        echo WARNING: expected 16384 bytes for a 16 KB ROM.
        exit /b 1
    )
)

endlocal
