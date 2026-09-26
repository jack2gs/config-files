@echo off
setlocal enabledelayedexpansion

set "DIR=%~dp0"
set "FORCE=0"
if /i "%~1"=="--force" set "FORCE=1"
if /i "%~1"=="/f"      set "FORCE=1"

echo Linking from %DIR%
echo.

rem ---- edit this list: "src:dest"  (dest is relative to %USERPROFILE%) ----
for %%L in (
  "ideavimrc:.ideavimrc"
  "vscvimrc:.vscvimrc"
) do (
  for /f "tokens=1,* delims=:" %%A in ("%%~L") do (
    call :link_file "%%A" "%%B"
  )
)

echo.
echo Done.
endlocal
exit /b 0

rem ---------------------------------------------------------------
:link_file
set "SRC=%~1"
set "DEST=%~2"

set "FULL_SRC=%DIR%%SRC%"
if not exist "%FULL_SRC%" (
  echo   skip:    source not found: %FULL_SRC%
  exit /b 0
)

set "FULL_DEST=%USERPROFILE%\%DEST%"
for %%I in ("%FULL_DEST%") do set "DEST_DIR=%%~dpI"

if exist "%FULL_DEST%" (
  if "%FORCE%"=="1" (
    del /f /q "%FULL_DEST%"
    echo   replace: %FULL_DEST%
  ) else (
    echo   skip:    already exists: %FULL_DEST% ^(use --force^)
    exit /b 0
  )
)

if not exist "%DEST_DIR%" (
  mkdir "%DEST_DIR%"
  echo   mkdir:   %DEST_DIR%
)

mklink "%FULL_DEST%" "%FULL_SRC%" >nul
if errorlevel 1 (
  echo   FAIL:    mklink %FULL_DEST%
  echo            Run as Administrator or enable Developer Mode.
  exit /b 1
)
echo   link:    %FULL_DEST% -^> %FULL_SRC%
exit /b 0