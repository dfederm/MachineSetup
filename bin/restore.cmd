@echo off
call msbuild /t:Restore /Interactive /MaxCPUCount /NodeReuse:False /p:RestoreUseStaticGraphEvaluation=true /ConsoleLoggerParameters:Verbosity=Minimal;Summary;ForceNoAlign %*
