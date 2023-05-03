@echo off

rem TODO! This previously ran in the context of OneDrive. Need to figure out how to properly bootstrap

rem The script to run each time cmd starts.
if not exist "%~dp0\init.cmd" (
  call :print-err "%~dp0\init.cmd does not exist!"
  exit /B 1
)

call :print-header "Gathering information"

if not defined CodeDir (
  set /p CodeDir=Where is your code directory located? 
) else (
  call :print "CodeDir already set to %CodeDir%"
)

mkdir %CodeDir% 2>NUL
call :set-env-var CodeDir "%CodeDir%"
call :set-env-var NUGET_PACKAGES "%CodeDir%\.nuget"
call :set-env-var NUGET_HTTP_CACHE_PATH "%CodeDir%\.nuget\.http"

set /p InstallCommsApps=Do you need communication apps, eg. Telegram, Teams? (y/n) 

call :print-header "Configuring registry and env vars"

where /q %~n0%~x0
if ERRORLEVEL 1 (
  call :print "Adding scripts directory to the PATH"
  call :add-to-path "%~dp0"
) else (
  call :print "Scripts directory already on the PATH"
)

call :print "Configuring cmd Autorun"
call reg add "HKCU\Software\Microsoft\Command Processor" /v "Autorun" /d "\"%~dp0\init.cmd\"" /t REG_EXPAND_SZ /f >NUL

call :print "Showing file extensions in Explorer"
call reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v HideFileExt /t REG_DWORD /d 0 /f >NUL

call :print "Showing hidden files and directories in Explorer"
call reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v Hidden /t REG_DWORD /d 1 /f >NUL

call :print "Restore classic context menu"
call reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve >NUL

call :print "Enable Developer Mode"
call powershell -Command "Start-process -filepath %ComSpec% -argumentlist @('/c','reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v "AllowDevelopmentWithoutDevLicense" /d 1 /t REG_DWORD /f >NUL') -Verb RunAs"

rem TODO: This doesn't seem to work entirely. Need to go to System Properties -> Remote and enable remote desktop
rem call :print "Enable Remote Desktop"
rem call powershell -Command "Start-process -filepath %ComSpec% -argumentlist @('/c','reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >NUL') -Verb RunAs"
rem call powershell -Command "Start-process -filepath %ComSpec% -argumentlist @('/c','netsh advfirewall firewall set rule group="remote desktop" new enable=yes') -Verb RunAs"

call :print "Enable Long Paths"
call powershell -Command "Start-process -filepath %ComSpec% -argumentlist @('/c','reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem" /v "LongPathsEnabled" /d 1 /t REG_DWORD /f >NUL') -Verb RunAs"

rem TODO: This doesn't work because I can't figure out how to escape properly. The powershell command should be: iex "& { $(irm https://aka.ms/install-artifacts-credprovider.ps1) } -AddNetfx"
rem call :print "Installing Artifacts Cred Provider"
rem call powershell -Command "iex '& { $(irm https://aka.ms/install-artifacts-credprovider.ps1) } -AddNetfx'"

call :print "Force NuGet to use auth dialogs"
call :set-env-var NUGET_CREDENTIALPROVIDER_FORCE_CANSHOWDIALOG_TO true
call :set-env-var NUGET_CREDENTIALPROVIDER_MSAL_ENABLED true

call :print "Opting out of .NET Telemetry"
call :set-env-var DOTNET_CLI_TELEMETRY_OPTOUT 1

call :print "Excluding CodeDir from Defender"
call powershell -Command "Start-process -filepath powershell -argumentlist @('-Command','Add-MpPreference -ExclusionPath %CodeDir%') -Verb RunAs"

call :print "Uninstalling Junk Apps"
call powershell -Command "Start-process -filepath powershell -argumentlist @('-Command','Get-AppxPackage -allusers Microsoft.549981C3F5F10 | Remove-AppxPackage') -Verb RunAs"
call powershell -Command "Start-process -filepath powershell -argumentlist @('-Command','Get-AppxPackage -allusers Microsoft.BingWeather | Remove-AppxPackage') -Verb RunAs"
call powershell -Command "Start-process -filepath powershell -argumentlist @('-Command','Get-AppxPackage -allusers Microsoft.GetHelp | Remove-AppxPackage') -Verb RunAs"
call powershell -Command "Start-process -filepath powershell -argumentlist @('-Command','Get-AppxPackage -allusers Microsoft.Getstarted | Remove-AppxPackage') -Verb RunAs"
call powershell -Command "Start-process -filepath powershell -argumentlist @('-Command','Get-AppxPackage -allusers Microsoft.MixedReality.Portal | Remove-AppxPackage') -Verb RunAs"

call :print-header "Installing applications via WinGet"
call :winget-install Microsoft.DotNet.SDK.7
call :winget-install Git.Git
call :winget-install Microsoft.WindowsTerminal
call :winget-install Microsoft.PowerShell
call :winget-install icsharpcode.ILSpy
call :winget-install Microsoft.NuGet
call :winget-install Notepad++.Notepad++
call :winget-install KirillOsenkov.MSBuildStructuredLogViewer
call :winget-install WinDirStat.WinDirStat
call :winget-install OpenJS.NodeJS
call :winget-install Microsoft.VisualStudioCode
call :winget-install SourceGear.DiffMerge
call :winget-install Microsoft.VisualStudio.2022.Enterprise
call :winget-install Microsoft.VisualStudio.2022.Enterprise.Preview
call :winget-install Microsoft.PowerToys
call :winget-install "Regex Hero"
call :winget-install 7zip.7zip
call :winget-install "NuGet Package Explorer"
call :winget-install Microsoft.SQLServerManagementStudio
call :winget-install Microsoft.RemoteDesktopClient

if "%InstallCommsApps%" == "y" (
  call :winget-install Telegram.TelegramDesktop
  call :winget-install Microsoft.Teams
)

call :print-header "Setting git config and aliases"
rem note: Using absolute paths since Git isn't on the PATH yet since it was just installed.
"%ProgramFiles%\Git\cmd\git.exe" config --global core.editor "\"%ProgramFiles%\\Notepad++\\notepad++.exe\" -multiInst -notabbar -nosession -noPlugin"
"%ProgramFiles%\Git\cmd\git.exe" config --global core.autocrlf true
"%ProgramFiles%\Git\cmd\git.exe" config --global core.fscache true
"%ProgramFiles%\Git\cmd\git.exe" config --global core.longpaths true
"%ProgramFiles%\Git\cmd\git.exe" config --global fetch.prune true
"%ProgramFiles%\Git\cmd\git.exe" config --global pull.rebase true
"%ProgramFiles%\Git\cmd\git.exe" config --global push.default current
"%ProgramFiles%\Git\cmd\git.exe" config --global merge.conflictstyle diff3
"%ProgramFiles%\Git\cmd\git.exe" config --global diff.colorMoved zebra
"%ProgramFiles%\Git\cmd\git.exe" config --global alias.amend "commit --amend --date=now --no-edit"
"%ProgramFiles%\Git\cmd\git.exe" config --global alias.sync "pull --rebase origin main"

call :print "Copying Terminal settings"
copy /y "%~dp0\..\WindowsTerminal\settings.json" "%LocalAppData%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" >NUL

rem note: Using absolute paths since dotnet isn't on the PATH yet since it was just installed.
call :print "Installing SlnGen"
"%ProgramFiles%\dotnet\dotnet.exe" tool install --global Microsoft.VisualStudio.SlnGen.Tool --add-source https://api.nuget.org/v3/index.json --ignore-failed-sources

rem init now to avoid the need to restart the console
call :print-header "Running init"
call "%~dp0\init.cmd"

rem cleanup
set InstallCommsApps=

call :print-header "Done!"
exit /b

:set-env-var
SETX %1 "%~2">NUL
SET "%1=%~2"
goto :eof

:add-to-path
for /f "usebackq tokens=2,*" %%A in (`reg query HKCU\Environment /v PATH`) do set OLD_USER_PATH=%%B
set NEW_USER_PATH=%OLD_USER_PATH%;%~1

rem Add double escape if there is a trailing slash. See: https://ss64.com/nt/syntax-esc.html
IF %NEW_USER_PATH:~-1% EQU \ (
  SET "NEW_USER_PATH=%NEW_USER_PATH%\"
)

call reg add "HKCU\Environment" /v PATH /t REG_SZ /d "%NEW_USER_PATH%" /f >NUL
set OLD_USER_PATH=
set NEW_USER_PATH=
set "PATH=%PATH%;%~1"
goto :eof

:winget-install
call :print "Installing %~1"
winget install %1 --silent --no-upgrade --accept-package-agreements --accept-source-agreements
if %ERRORLEVEL% EQU 0 (
  call :print "%~1 installed successfully"
) else if %ERRORLEVEL% EQU -1978335135 (
  REM 0x8A150061 (APPINSTALLER_CLI_ERROR_PACKAGE_ALREADY_INSTALLED)
  call :print "%~1 already installed"
) else (
  call :print-err "%~1 failed to install! winget exit code %ERRORLEVEL%"
)
goto :eof

rem print helpers
:print-header
call powershell write-host -fore Cyan '%1'"
goto :eof

:print
call powershell "write-host '  ' -NoNewLine ; powershell write-host -fore Gray '%1'"
goto :eof

:print-err
call powershell "write-host '  ' -NoNewLine ; powershell write-host -back Red '%1'"
goto :eof
