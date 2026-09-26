@echo off
setlocal enabledelayedexpansion

set "DIR=%~dp0"
set "FORCE=0"
if /i "%~1"=="--force" set "FORCE=1"
if /i "%~1"=="/f"      set "FORCE=1"

echo Installing from %DIR%
echo.

rem ---- edit this list: "src:dest"  (dest is relative to %USERPROFILE%) ----
for %%L in (
  "ideavimrc:.ideavimrc"
  "vscvimrc:.vscvimrc"
) do (
  for /f "tokens=1,* delims=:" %%A in ("%%~L") do (
    call :copy_file "%%A" "%%B"
  )
)

echo.
echo Merging VS Code settings...
call :merge_vscode "vsc_settings.json"

echo.
echo Done.
endlocal
exit /b 0

rem ===============================================================
rem Subroutines
rem ===============================================================

:copy_file
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
    echo   replace: %FULL_DEST%
  ) else (
    rem compare timestamps; skip if dest is newer or same
    for %%S in ("%FULL_SRC%")  do set "SRC_TIME=%%~tS"
    for %%D in ("%FULL_DEST%") do set "DEST_TIME=%%~tD"
    if "!SRC_TIME!"=="!DEST_TIME!" (
      echo   skip:    up to date: %FULL_DEST%
      exit /b 0
    )
    echo   update:  %FULL_DEST%
  )
) else (
  echo   create:  %FULL_DEST%
)

if not exist "%DEST_DIR%" (
  mkdir "%DEST_DIR%"
  echo   mkdir:   %DEST_DIR%
)

copy /y "%FULL_SRC%" "%FULL_DEST%" >nul
if errorlevel 1 (
  echo   FAIL:    copy to %FULL_DEST%
  exit /b 1
)
exit /b 0

:merge_vscode
set "VSC_SRC=%DIR%%~1"
set "VSC_DEST=%APPDATA%\Code\User\settings.json"

if not exist "%VSC_SRC%" (
  echo   skip:    source not found: %VSC_SRC%
  exit /b 0
)

if not exist "%APPDATA%\Code\User" mkdir "%APPDATA%\Code\User"

rem If destination does not exist, just copy
if not exist "%VSC_DEST%" (
  copy /y "%VSC_SRC%" "%VSC_DEST%" >nul
  echo   create:  %VSC_DEST%
  exit /b 0
)

rem Backup before modifying
copy /y "%VSC_DEST%" "%VSC_DEST%.bak" >nul

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$srcPath='%VSC_SRC%'; $destPath='%VSC_DEST%';" ^
  "try {" ^
  "  $src  = Get-Content -Raw -LiteralPath $srcPath  | ConvertFrom-Json;" ^
  "  $dest = Get-Content -Raw -LiteralPath $destPath | ConvertFrom-Json;" ^
  "} catch { Write-Host '  warn:    invalid JSON, skipping merge'; exit 2 }" ^
  "foreach ($p in $src.PSObject.Properties) {" ^
  "  $dest | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force" ^
  "}" ^
  "$dest | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $destPath -Encoding UTF8"

if errorlevel 1 (
  echo   FAIL:    merge %VSC_DEST%
  exit /b 1
)
echo   merge:   %VSC_DEST%  (backup: %VSC_DEST%.bak)
exit /b 0