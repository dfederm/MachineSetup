# MachineSetup
This is my personal machine setup script. The script will configure some settings, install some app, and do some light debloating.

## How to run

To run the scripts from the repo exactly as-is (recommended only for me, or if you've forked this repo and customized it yourself):

```ps1
iex "& { $(iwr https://raw.githubusercontent.com/dfederm/MachineSetup/main/bootstrap.ps1) }" | Out-Null
```

To manually download and tweak the scripts, just clone or download the whole repo and run `setup.ps1`
