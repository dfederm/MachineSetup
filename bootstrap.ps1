$TempDir = "$env:TEMP\MachineSetup"
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $TempDir -ItemType Directory > $null
$ZipPath = "$TempDir\bundle.zip"
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri https://github.com/dfederm/MachineSetup/archive/refs/heads/main.zip -OutFile $ZipPath
$ProgressPreference = 'Continue'
Expand-Archive -LiteralPath $ZipPath -DestinationPath $TempDir
$SetupScript = (Get-ChildItem -Path $TempDir -Filter setup.ps1 -Recurse).FullName
& $SetupScript @args
Remove-Item $TempDir -Recurse -Force