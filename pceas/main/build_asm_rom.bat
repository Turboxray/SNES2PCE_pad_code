@echo off

rem ***************************************************************************


setlocal

cd /d "%~dp0"

pushd

del log.txt

set PCE_INCLUDE=%CD%\..\lib;%CD%\..\..\..\lib

pceas -raw snes2pce_gamepad_demo.asm -l 2 -S > log.txt
type log.txt
pause
