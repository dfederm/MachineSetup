# MachineSetup
This is my personal machine setup script. The script will configure some settings, install some apps, and do some light debloating.

## Structure

- `setup.ps1` — Main entry point, discovers components and runs those matching the selected scope
- `components/` — Individual setup components, each with `Detect` and `Install` logic
- `lib/` — Shared PowerShell modules (Console, Registry, WinGet, etc.)
- `bin/` — Scripts and tools deployed to BinDir
- `work/` — Work-specific bin files

## How to run

MachineSetup targets modern Windows desktops with [WinGet](https://learn.microsoft.com/windows/package-manager/winget/) available. The bootstrap script can start in Windows PowerShell, but it installs or detects PowerShell 7 before running setup.

To run the scripts from the repo exactly as-is (recommended only for me, or if you've forked this repo and customized it yourself):

```ps1
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
iex "& { $(iwr https://raw.githubusercontent.com/dfederm/MachineSetup/main/bootstrap.ps1) }" | Out-Null
```

If WinGet is unavailable, install or register Microsoft App Installer before running the bootstrap.

To manually download and tweak the scripts, clone or download the whole repo and run `setup.ps1` with PowerShell 7:

```ps1
# Interactive (will prompt for preferences)
pwsh .\setup.ps1

# Non-interactive
pwsh .\setup.ps1 -IsForWork -InstallCommsApps
```

Each component declares a `Scope` (`common`, `work`, `comms`, or `work-comms`) to control when it applies. The script is idempotent — each component detects whether it's already applied and skips itself if so.
