@echo off
setlocal EnableExtensions

set "ADDON_NAME=path_of_the_ancients"
set "PROJECT_ROOT=%~dp0"

if "%~1"=="" (
    echo Usage: %~nx0 "C:\path\to\dota 2 beta" 1>&2
    exit /b 2
)

for %%I in ("%~1") do set "DOTA_ROOT=%%~fI"

if not exist "%DOTA_ROOT%\content\dota_addons" (
    echo Error: Dota content addon directory was not found: 1>&2
    echo %DOTA_ROOT%\content\dota_addons 1>&2
    exit /b 1
)

if not exist "%DOTA_ROOT%\game\dota_addons" (
    echo Error: Dota game addon directory was not found: 1>&2
    echo %DOTA_ROOT%\game\dota_addons 1>&2
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

if not exist "%TARGET%" (
    echo Error: project %KIND% directory is missing: 1>&2
    echo %TARGET% 1>&2
    exit /b 1
)

if exist "%LINK%" (
    echo Error: refusing to replace existing path: 1>&2
    echo %LINK% 1>&2
    exit /b 1
)

mklink /D "%LINK%" "%TARGET%" >nul
if errorlevel 1 (
    echo Error: could not create the %KIND% link. 1>&2
    echo Enable Windows Developer Mode or run Command Prompt as Administrator. 1>&2
    exit /b 1
)

echo Created %KIND% link: %LINK% ^-^> %TARGET%
exit /b 0
