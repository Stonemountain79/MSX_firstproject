@echo off
set ASM=sjasmplus
if exist soundtester.rom del soundtester.rom
%ASM% soundtester.asm --raw=soundtester.rom
if errorlevel 1 goto error
if not exist soundtester.rom goto norom
for %%A in (soundtester.rom) do echo ROM created: %%~fA  Size: %%~zA bytes
goto end
:norom
echo ERROR: soundtester.rom was not created.
goto end
:error
echo ERROR: assembler returned an error.
:end
