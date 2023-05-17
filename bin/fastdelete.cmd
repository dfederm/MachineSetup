@ECHO OFF
SET FOLDER=%1

IF EXIST "%FOLDER%" (
    ECHO Deleting %FOLDER%...
    DEL /F /Q /S "%FOLDER%" > NUL
    RMDIR /Q /S "%FOLDER%"
) ELSE (
    ECHO Folder does not exist: %FOLDER%
)

SET FOLDER=
