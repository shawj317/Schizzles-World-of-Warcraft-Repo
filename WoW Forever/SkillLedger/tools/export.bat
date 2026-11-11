@echo off
setlocal
cd /d "%~dp0"

rem A double-clicked window is cmd.exe /c with no arguments. Pause at the end
rem so the message stays on screen. A prompt that already passed arguments
rem (including PowerShell's -o) does not pause.
set "DOUBLECLICK="
if "%~1"=="" (
  echo "%CMDCMDLINE%" | find /I "/c" >nul && set "DOUBLECLICK=1"
)

rem PowerShell puts this .bat on the front of %* when an argument starts
rem with a dash (--out does that). shift moves %%1 but leaves %%* unchanged,
rem so rebuild the list from %%1 after the shifts.
if /I "%~nx1"=="export.bat" shift
if /I "%~nx1"=="export.py" shift

set "FORWARDED="
:gather
if "%~1"=="" goto gathered
set FORWARDED=%FORWARDED% "%~1"
shift
goto gather
:gathered

set "PY="
where py >nul 2>&1 && set "PY=py -3"
if not defined PY where python >nul 2>&1 && set "PY=python"
if not defined PY (
  echo Python 3 was not found. Install it from https://www.python.org/downloads/ and tick Add python.exe to PATH, then run this again.
  if defined DOUBLECLICK pause
  exit /b 1
)
%PY% "%~dp0export.py" %FORWARDED%
set "RC=%ERRORLEVEL%"
if defined DOUBLECLICK pause
exit /b %RC%
