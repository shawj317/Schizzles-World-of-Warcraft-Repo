@echo off
setlocal
cd /d "%~dp0"
set "PY="
where py >nul 2>&1 && set "PY=py -3"
if not defined PY where python >nul 2>&1 && set "PY=python"
if not defined PY (
  echo Python 3 was not found. Install it from https://www.python.org/downloads/ and run this again.
  exit /b 1
)
%PY% "%~dp0export.py" %*
exit /b %ERRORLEVEL%
