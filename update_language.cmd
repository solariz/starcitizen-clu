@echo off
setlocal EnableExtensions EnableDelayedExpansion


set VER=2026-04-09
REM ============================================================
REM  SC.CLU - Star Citizen Component Language Updater
REM  by solariz, find at:
REM  https://github.com/solariz/starcitizen-clu
REM ============================================================

REM === Enable UTF-8 === 
for /f "tokens=2 delims=:" %%A in ('chcp') do set _OLDCP=%%A
chcp 65001 >nul 2>&1

REM === Enable VT100 sequences === 
for /f "tokens=3" %%a in ('reg query HKCU\Console /v VirtualTerminalLevel 2^>nul') do set VTLevel=%%a
if not "!VTLevel!"=="0x1" reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

REM === ANSI color codes ===
set "RESET=[0m"
set "BOLD=[1m"
set "CYAN=[36m"
set "GREEN=[32m"
set "YELLOW=[33m"
set "RED=[31m"
set "GRAY=[90m"

REM === Configuration ===
set "GAME=Star Citizen"
set "PACK=Custom Language Pack"
set "TMPFILE=%TEMP%\global_%RANDOM%%RANDOM%.ini"
set "MINLINES=6000"
set "MINSIZE=6291456"

REM === Language Pack URLs ===
set "URL_EXOAE_REMIX=https://github.com/ExoAE/ScCompLangPack/raw/refs/heads/main/ScCompLangPackRemix2/data/Localization/english/global.ini"
set "URL_EXOAE_LONG=https://github.com/ExoAE/ScCompLangPack/raw/refs/heads/main/ScCompLangPack/data/Localization/english/global.ini"
set "URL_BELTAKODA_BASE=https://raw.githubusercontent.com/BeltaKoda/ScCompLangPackRemix/refs/tags"

REM ============================================================
REM  DISPLAY ASCII HEADER
REM ============================================================
cls
echo.
echo %CYAN%
echo  _____ _____  _____  _     _   _ 
echo /  ___/  __ \/  __ \^| ^|   ^| ^| ^| ^|
echo \ `--.^| /  \/^| /  \/^| ^|   ^| ^| ^| ^|
echo  `--. \ ^|    ^| ^|    ^| ^|   ^| ^| ^| ^|
echo /\__/ / \__/\^| \__/\^| ^|___^| ^|_^| ^|
echo \____/ \____(_)____/\_____/\___/ 
echo %RESET%%BOLD%SC.CLU !VER!%RESET%  Component Lang Updater
echo %GRAY%github.com/solariz/starcitizen-clu%RESET%
echo.
echo %GRAY%This tool downloads community language packs that rename%RESET%
echo %GRAY%component names to better human-readable formats.%RESET%
echo.
echo %GRAY%Language Pack Credits:%RESET%
echo   %CYAN%ExoAE%RESET%    - github.com/ExoAE/ScCompLangPack
echo   %CYAN%BeltaKoda%RESET% - github.com/BeltaKoda/ScCompLangPackRemix
echo %GRAY%============================================================%RESET%
echo.

REM ============================================================
REM  DETECT INSTALLATION LOCATION
REM ============================================================
set "LIVE_DIR="
set "ENGLISH_DIR="
set "TARGET_DIR="
set "DATAP4K_FOUND=0"
set "EXE_FOUND=0"

REM Check if we're in Localization\english directory (3 levels deep from LIVE)
for %%P in ("%CD%\..\..\..") do set "CHECK_LIVE=%%~fP"
if exist "!CHECK_LIVE!\Data.p4k" set "DATAP4K_FOUND=1"
if not !DATAP4K_FOUND! EQU 1 if exist "!CHECK_LIVE!\data.p4k" set "DATAP4K_FOUND=1"
if not !DATAP4K_FOUND! EQU 1 if exist "!CHECK_LIVE!\DATA.P4K" set "DATAP4K_FOUND=1"
if !DATAP4K_FOUND! EQU 1 (
    if exist "!CHECK_LIVE!\Bin64\StarCitizen.exe" set "EXE_FOUND=1"
    if not !EXE_FOUND! EQU 1 if exist "!CHECK_LIVE!\bin64\StarCitizen.exe" set "EXE_FOUND=1"
    if not !EXE_FOUND! EQU 1 if exist "!CHECK_LIVE!\BIN64\StarCitizen.exe" set "EXE_FOUND=1"
    if !EXE_FOUND! EQU 1 (
        set "LIVE_DIR=!CHECK_LIVE!"
        set "ENGLISH_DIR=%CD%"
        set "TARGET_DIR=!ENGLISH_DIR!"
        goto :setup_target
    )
)

REM Check if we're in LIVE directory
set "DATAP4K_FOUND=0"
set "EXE_FOUND=0"
if exist "%CD%\Data.p4k" set "DATAP4K_FOUND=1"
if not !DATAP4K_FOUND! EQU 1 if exist "%CD%\data.p4k" set "DATAP4K_FOUND=1"
if not !DATAP4K_FOUND! EQU 1 if exist "%CD%\DATA.P4K" set "DATAP4K_FOUND=1"
if !DATAP4K_FOUND! EQU 1 (
    if exist "%CD%\Bin64\StarCitizen.exe" set "EXE_FOUND=1"
    if not !EXE_FOUND! EQU 1 if exist "%CD%\bin64\StarCitizen.exe" set "EXE_FOUND=1"
    if not !EXE_FOUND! EQU 1 if exist "%CD%\BIN64\StarCitizen.exe" set "EXE_FOUND=1"
    if !EXE_FOUND! EQU 1 (
        set "LIVE_DIR=%CD%"
        set "ENGLISH_DIR=%CD%\data\Localization\english"
        set "TARGET_DIR=!ENGLISH_DIR!"
        goto :setup_target
    )
)

REM Check parent directories for LIVE folder
set "CHECK_DIR=%CD%"
:check_parent
set "DATAP4K_FOUND=0"
set "EXE_FOUND=0"
if exist "!CHECK_DIR!\Data.p4k" set "DATAP4K_FOUND=1"
if not !DATAP4K_FOUND! EQU 1 if exist "!CHECK_DIR!\data.p4k" set "DATAP4K_FOUND=1"
if not !DATAP4K_FOUND! EQU 1 if exist "!CHECK_DIR!\DATA.P4K" set "DATAP4K_FOUND=1"
if !DATAP4K_FOUND! EQU 1 (
    if exist "!CHECK_DIR!\Bin64\StarCitizen.exe" set "EXE_FOUND=1"
    if not !EXE_FOUND! EQU 1 if exist "!CHECK_DIR!\bin64\StarCitizen.exe" set "EXE_FOUND=1"
    if not !EXE_FOUND! EQU 1 if exist "!CHECK_DIR!\BIN64\StarCitizen.exe" set "EXE_FOUND=1"
    if !EXE_FOUND! EQU 1 (
        set "LIVE_DIR=!CHECK_DIR!"
        set "ENGLISH_DIR=!CHECK_DIR!\data\Localization\english"
        set "TARGET_DIR=!ENGLISH_DIR!"
        goto :setup_target
    )
)
set "PARENT_CHECK=!CHECK_DIR!"
set "CHECK_DIR=!CHECK_DIR!\.."
for %%P in ("!CHECK_DIR!") do set "CHECK_DIR=%%~fP"
if /i "!PARENT_CHECK!"=="!CHECK_DIR!" goto :invalid_location
goto :check_parent

:invalid_location
echo %RED%%BOLD%ERROR: INVALID LOCATION%RESET%
echo.
echo %YELLOW%This script must be placed inside the LIVE folder of your%RESET%
echo %YELLOW%Star Citizen installation.%RESET%
echo.
echo %GRAY%Default location:%RESET%
echo   C:\Program Files\Roberts Space Industries\StarCitizen\LIVE\
echo.
echo %GRAY%The LIVE folder must contain:%RESET%
echo   %GRAY%- Data.p4k%RESET%
echo   %GRAY%- Bin64\StarCitizen.exe%RESET%
echo.
goto :cleanup

:setup_target
REM Ensure target directory exists
if not exist "!TARGET_DIR!\." (
    mkdir "!TARGET_DIR!" >nul 2>&1
)

REM ============================================================
REM  EXTRACT GAME VERSION FROM build_manifest.id
REM ============================================================
set "SC_VERSION="
set "FULL_VERSION="
set "MANIFEST_FILE=!LIVE_DIR!\build_manifest.id"

if exist "!MANIFEST_FILE!" (
    for /f "tokens=2 delims=:," %%A in ('findstr /i "Branch" "!MANIFEST_FILE!"') do (
        set "BRANCH_RAW=%%~A"
        REM Remove quotes and whitespace, extract version after "sc-alpha-"
        set "BRANCH_RAW=!BRANCH_RAW: =!"
        set "BRANCH_RAW=!BRANCH_RAW:"=!"
        REM Extract version number (e.g., 4.5.0 from sc-alpha-4.5.0)
        for /f "tokens=3 delims=-" %%V in ("!BRANCH_RAW!") do set "SC_VERSION=%%V"
    )
    for /f "tokens=* delims=" %%A in ('findstr /i "Version" "!MANIFEST_FILE!"') do (
        if not defined FULL_VERSION (
            set "VER_LINE=%%A"
            for /f "tokens=2 delims=:" %%B in ("!VER_LINE!") do (
                set "VER_RAW=%%B"
                set "VER_RAW=!VER_RAW: =!"
                set "VER_RAW=!VER_RAW:"=!"
                set "VER_RAW=!VER_RAW:,=!"
                if not "!VER_RAW!"=="" set "FULL_VERSION=!VER_RAW!"
            )
        )
    )
)

if "!SC_VERSION!"=="" (
    echo %RED%Warning: Could not detect game version from build_manifest.id%RESET%
    set "SC_VERSION=unknown"
)
if not defined FULL_VERSION set "FULL_VERSION=unknown"

echo %GRAY%============================================================%RESET%
echo  Detected Game Version: %GREEN%%BOLD%!SC_VERSION!%RESET%  %GRAY%(!FULL_VERSION!)%RESET%
echo  Installation Path: %GRAY%!LIVE_DIR!%RESET%
echo %GRAY%============================================================%RESET%
echo.

REM ============================================================
REM  PROBE BELTAKODA URL (GitHub API - latest release tag)
REM ============================================================
set "URL_BELTAKODA="
set "BELTAKODA_SOURCE="
set "BELTAKODA_TAG="

curl -sf "https://api.github.com/repos/BeltaKoda/ScCompLangPackRemix/releases/latest" > "%TEMP%\bk_api.txt" 2>nul

if exist "%TEMP%\bk_api.txt" (
    for /f "tokens=* delims=" %%A in ('findstr /i "tag_name" "%TEMP%\bk_api.txt"') do (
        if not defined BELTAKODA_TAG (
            set "LINE=%%A"
            for /f "tokens=2 delims=:" %%B in ("!LINE!") do (
                set "TAG_RAW=%%B"
                set "TAG_RAW=!TAG_RAW: =!"
                set "TAG_RAW=!TAG_RAW:"=!"
                set "TAG_RAW=!TAG_RAW:,=!"
                if not "!TAG_RAW!"=="" set "BELTAKODA_TAG=!TAG_RAW!"
            )
        )
    )
)
del "%TEMP%\bk_api.txt" 2>nul

if defined BELTAKODA_TAG (
    set "ENV_SUFFIX="
    echo !BELTAKODA_TAG! | findstr /i /c:"-LIVE" >nul 2>&1
    if !errorlevel! EQU 0 set "ENV_SUFFIX=LIVE"
    if not defined ENV_SUFFIX (
        echo !BELTAKODA_TAG! | findstr /i /c:"-PTU" >nul 2>&1
        if !errorlevel! EQU 0 set "ENV_SUFFIX=PTU"
    )
    if defined ENV_SUFFIX (
        set "PROBE_URL=!URL_BELTAKODA_BASE!/!BELTAKODA_TAG!/!ENV_SUFFIX!/data/Localization/english/global.ini"
        curl -s -L -o nul -w "%%{http_code}" --head "!PROBE_URL!" > "%TEMP%\probe_result.txt" 2>nul
        set /p PROBE_CODE=<"%TEMP%\probe_result.txt"
        del "%TEMP%\probe_result.txt" 2>nul
        if "!PROBE_CODE!"=="200" (
            set "URL_BELTAKODA=!PROBE_URL!"
            set "BELTAKODA_SOURCE=!ENV_SUFFIX!"
        )
    )
)

REM ============================================================
REM  CHECK AVAILABILITY AND LAST MODIFIED DATES
REM ============================================================
echo %CYAN%Checking language pack availability...%RESET%
echo.

REM Check ExoAE Remix
set "EXOAE_REMIX_STATUS=%RED%UNAVAILABLE%RESET%"
curl -s -L -o nul -w "%%{http_code}" --head "!URL_EXOAE_REMIX!" > "%TEMP%\chk.txt" 2>nul
set /p CHK=<"%TEMP%\chk.txt"
if "!CHK!"=="200" set "EXOAE_REMIX_STATUS=%GREEN%Available%RESET%"

REM Check ExoAE Long
set "EXOAE_LONG_STATUS=%RED%UNAVAILABLE%RESET%"
curl -s -L -o nul -w "%%{http_code}" --head "!URL_EXOAE_LONG!" > "%TEMP%\chk.txt" 2>nul
set /p CHK=<"%TEMP%\chk.txt"
if "!CHK!"=="200" set "EXOAE_LONG_STATUS=%GREEN%Available%RESET%"
del "%TEMP%\chk.txt" 2>nul

REM Check BeltaKoda (already probed above)
set "BELTAKODA_STATUS=%RED%UNAVAILABLE (no matching release found)%RESET%"
if defined URL_BELTAKODA set "BELTAKODA_STATUS=%GREEN%Available (!BELTAKODA_SOURCE! - !BELTAKODA_TAG!)%RESET%"

REM ============================================================
REM  DISPLAY SELECTION MENU
REM ============================================================
echo %WHITE%%BOLD%  SELECT YOUR PREFERRED NAMING STYLE:%RESET%
echo %GRAY%-------------------------------------------------------------%RESET%
echo.
echo   %CYAN%[1]%RESET% ExoAE Remix Version
echo       %GRAY%Example:%RESET% %YELLOW%MIL-2A "XL-1"%RESET%
echo       %GRAY%Status:%RESET% !EXOAE_REMIX_STATUS!
echo.
echo   %CYAN%[2]%RESET% ExoAE Long Version
echo       %GRAY%Example:%RESET% %YELLOW%XL-1 Military A%RESET%
echo       %GRAY%Status:%RESET% !EXOAE_LONG_STATUS!
echo.
echo   %CYAN%[3]%RESET% BeltaKoda Alternate Short Version
echo       %GRAY%Example:%RESET% %YELLOW%M2A XL-1%RESET%
echo       %GRAY%Status:%RESET% !BELTAKODA_STATUS!
echo.
echo   %CYAN%[Q]%RESET% %GRAY%Quit%RESET%
echo.
echo %GRAY%-------------------------------------------------------------%RESET%
echo.

set /p "CHOICE=  %WHITE%Enter your choice (1-3 or Q):%RESET% "

if /i "!CHOICE!"=="Q" goto :cleanup
if /i "!CHOICE!"=="1" (
    set "URL=!URL_EXOAE_REMIX!"
    set "PACK_NAME=ExoAE Remix"
    goto :start_download
)
if /i "!CHOICE!"=="2" (
    set "URL=!URL_EXOAE_LONG!"
    set "PACK_NAME=ExoAE Long"
    goto :start_download
)
if /i "!CHOICE!"=="3" (
    if not defined URL_BELTAKODA (
        echo.
        echo %RED%BeltaKoda pack is not available for version !SC_VERSION!%RESET%
        echo %YELLOW%Please select another option or wait for the author to update.%RESET%
        echo.
        pause
        goto :setup_target
    )
    set "URL=!URL_BELTAKODA!"
    set "PACK_NAME=BeltaKoda Alternate"
    goto :start_download
)

echo %RED%Invalid choice. Please try again.%RESET%
timeout /t 2 >nul
goto :setup_target

:start_download
REM Check if global.ini exists for first-time setup
if not exist "!TARGET_DIR!\global.ini" (
    cls
    echo %YELLOW%%BOLD%
    echo ============================================================
    echo          NO PREVIOUS INSTALLATION DETECTED
    echo ============================================================
    echo %RESET%%GRAY%
    echo We did not find a previous language pack installation.
    echo.
    echo Do you want to download the %WHITE%!PACK_NAME!%GRAY% language pack
    echo and let us set everything up for you?
    echo %RESET%
    echo.
    set /p "SETUP_CHOICE=Download and setup language pack? (Y/N): "
    
    if /i "!SETUP_CHOICE!" NEQ "Y" (
        echo.
        echo %GRAY%Setup cancelled.%RESET%
        goto :cleanup
    )
    
    REM Check and update user.cfg
    set "USERCFG=!LIVE_DIR!\user.cfg"
    set "HAS_LANGUAGE_LINE=0"
    
    if exist "!USERCFG!" (
        findstr /i /c:"g_language" "!USERCFG!" >nul 2>&1
        if !errorlevel! EQU 0 set "HAS_LANGUAGE_LINE=1"
    )
    
    if !HAS_LANGUAGE_LINE! EQU 0 (
        echo %CYAN%Updating user.cfg...%RESET%
        if not exist "!USERCFG!" (
            echo g_language = english > "!USERCFG!"
        ) else (
            echo. >> "!USERCFG!"
            echo g_language = english >> "!USERCFG!"
        )
        echo %GREEN%user.cfg updated.%RESET%
        echo.
    )
    echo.
)

REM Continue with update
cls
echo %CYAN%%BOLD%
echo ============================================================
echo        STAR CITIZEN - CUSTOM LANGUAGE UPDATE
echo ============================================================
echo %RESET%%GRAY%
echo  Game       : %GAME%
echo  Version    : !SC_VERSION!
echo  Pack       : !PACK_NAME!
echo  Location   : !TARGET_DIR!
echo ============================================================
echo %RESET%
echo.

REM Set target file path
set "TARGET=!TARGET_DIR!\global.ini"

REM ============================================================
REM  [1/4] DOWNLOAD
REM ============================================================
echo %CYAN%[1/4] Fetching latest language data...%RESET%
echo.

curl --fail --location --show-error --progress-bar --connect-timeout 15 --max-time 120 "!URL!" -o "!TMPFILE!"

if errorlevel 1 (
    echo.
    echo %RED%Download failed or timed out.%RESET%
    goto :debug_dump
)

if not exist "!TMPFILE!" (
    echo %RED%Temp file not created.%RESET%
    goto :debug_dump
)

echo %GREEN%Download completed.%RESET%
echo.

REM ============================================================
REM  [2/4] FILE SIZE CHECK
REM ============================================================
echo %CYAN%[2/4] Verifying file size...%RESET%

for %%F in ("!TMPFILE!") do set "FILESIZE=%%~zF"
echo %GRAY%    Size detected: !FILESIZE! bytes%RESET%

if !FILESIZE! LSS !MINSIZE! (
    echo %RED%File too small (needs ^> 6 MB^).%RESET%
    goto :debug_dump
)

echo %GREEN%Size check passed.%RESET%
echo.

REM ============================================================
REM  [3/4] LINE COUNT CHECK
REM ============================================================
echo %CYAN%[3/4] Counting translation entries...%RESET%
<nul set /p "=%GRAY%    Processing... "

set "LINECOUNT=0"
for /f %%A in ('find /c /v "" ^< "!TMPFILE!"') do set "LINECOUNT=%%A"

echo done%RESET%
echo %GRAY%    Lines detected: %LINECOUNT%%RESET%

if !LINECOUNT! EQU 0 (
    echo %RED%Failed to determine line count.%RESET%
    goto :debug_dump
)

if !LINECOUNT! LSS !MINLINES! (
    echo %RED%Not enough entries (needs at least %MINLINES%^).%RESET%
    goto :debug_dump
)

echo %GREEN%Content check passed.%RESET%
echo.

REM ============================================================
REM  [4/4] COMPARE & UPDATE
REM ============================================================
echo %CYAN%[4/4] Checking existing installation...%RESET%

if exist "!TARGET!" (
    <nul set /p "=%GRAY%    Comparing files... "
    fc /b "!TARGET!" "!TMPFILE!" >nul 2>&1
    if !errorlevel! EQU 0 (
        echo skipped%RESET%
        echo %YELLOW%Language pack already up to date. No changes made.%RESET%
        goto :cleanup
    )
    echo done%RESET%
)

echo %GREEN%New version detected. Installing update...%RESET%
copy /y "!TMPFILE!" "!TARGET!" >nul

echo.
echo %GREEN%%BOLD%Update complete!%RESET%
echo %GRAY%You are ready to launch Star Citizen.%RESET%

goto :cleanup

REM ============================================================
REM  DEBUG OUTPUT
REM ============================================================
:debug_dump
echo.
echo %RED%%BOLD%--- DEBUG INFORMATION ---%RESET%
echo %GRAY%Temp file   : !TMPFILE!%RESET%
echo %GRAY%Target file : !TARGET!%RESET%
echo %GRAY%URL used    : !URL!%RESET%

if exist "!TMPFILE!" (
    for %%F in ("!TMPFILE!") do echo %GRAY%Temp size   : %%~zF bytes%RESET%
) else (
    echo %RED%Temp file does NOT exist.%RESET%
)

echo %GRAY%Last errorlevel: !errorlevel!%RESET%
echo.

if exist "!TMPFILE!" (
    echo %GRAY%Showing first 20 lines:%RESET%
    set "_COUNT=0"
    for /f "tokens=* delims=" %%L in ('findstr /R /N "^" "!TMPFILE!"') do (
        echo %%L
        set /a _COUNT+=1
        if !_COUNT! GEQ 20 goto :end_preview
    )
    :end_preview
)

echo %RED%%BOLD%--------------------------%RESET%
echo.

REM ============================================================
REM  CLEANUP
REM ============================================================
:cleanup
if exist "!TMPFILE!" del "!TMPFILE!"
echo.
echo %GRAY%Press any key to exit...%RESET%
pause >nul

chcp %_OLDCP% >nul 2>&1
endlocal
