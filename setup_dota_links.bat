@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "ADDON_NAME=path_of_the_ancients"
set "PROJECT_ROOT=%~dp0"
if "%~1"=="" (
    echo Usage: %~nx0 "C:\path\to\dota 2 beta" 1>&2
    exit /b 2
)
for %%I in ("%~1") do set "DOTA_ROOT=%%~fI"
if not exist "!DOTA_ROOT!\content\dota_addons" (
    echo Error: Dota content addon directory was not found: 1>&2
    echo !DOTA_ROOT!\content\dota_addons 1>&2
    exit /b 1
)
if not exist "!DOTA_ROOT!\game\dota_addons" (
    echo Error: Dota game addon directory was not found: 1>&2
    echo !DOTA_ROOT!\game\dota_addons 1>&2
    exit /b 1
)
call :link_addon_root content
if errorlevel 1 exit /b 1
call :link_addon_root game
if errorlevel 1 exit /b 1
echo Dota addon links created successfully.
exit /b 0

:link_addon_root
set "KIND=%~1"
set "TARGET=%PROJECT_ROOT%%KIND%"
set "LINK=%DOTA_ROOT%\%KIND%\dota_addons\%ADDON_NAME%"
if not exist "!TARGET!" (
    echo Error: project !KIND! directory is missing: 1>&2
    echo !TARGET! 1>&2
    exit /b 1
)
if not exist "!LINK!" (
    mkdir "!LINK!" >nul
    if errorlevel 1 (
        echo Error: could not create directory: 1>&2
        echo !LINK! 1>&2
        exit /b 1
    )
) else (
    if not exist "!LINK!\" (
        echo Error: refusing to use existing non-directory path: 1>&2
        echo !LINK! 1>&2
        exit /b 1
    )
)
for /f "delims=" %%F in ('dir /b "!TARGET!"') do (
    if /I not "%%~nxF"=="maps" (
        set "ITEM_TARGET=!TARGET!\%%F"
        set "ITEM_LINK=!LINK!\%%F"
        if exist "!ITEM_LINK!" (
            echo Error: refusing to replace existing path: 1>&2
            echo !ITEM_LINK! 1>&2
            exit /b 1
        )
        if exist "!ITEM_TARGET!\" (
            mklink /D "!ITEM_LINK!" "!ITEM_TARGET!" >nul
        ) else (
            mklink "!ITEM_LINK!" "!ITEM_TARGET!" >nul
        )
        if errorlevel 1 (
            echo Error: could not create link for %%F 1>&2
            echo Enable Windows Developer Mode or run Command Prompt as Administrator. 1>&2
            exit /b 1
        )
        echo Created !KIND! link: !ITEM_LINK! ^-^> !ITEM_TARGET!
    )
)
exit /b 0