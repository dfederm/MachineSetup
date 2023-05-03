@echo off

REM Set up macros
doskey /macrofile="%~dp0\macros.txt"

REM Back up Terminal settings
copy /y "%LocalAppData%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" "%~dp0\..\WindowsTerminal\settings.json" >NUL