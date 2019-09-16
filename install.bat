@echo off

goto check_Permissions

:check_Permissions
    echo Administrative permissions required. Detecting permissions...

    net session >nul 2>&1
    if %errorLevel% == 0 (
        echo Success: Administrative permissions confirmed.

        goto chocolatey
    ) else (
        echo Failure: Current permissions inadequate.
    )

    pause >nul & exit

:chocolatey
WHERE choco >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
    echo|set /p="[INFO] Installing Chocolatey... "
    
    @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" >nul 2>nul && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    
    IF %ERRORLEVEL% NEQ 0 (
        echo SUCCESS
    ) else (
        echo FAILED
        pause >nul & exit
    )
) else (
    echo [INFO] Installing Chocolatey... Skipping
)

:git
IF not exist "%PROGRAMFILES%\Git\bin\bash.exe" (
    echo|set /p="[INFO] Installing Git... "

    choco install --force -y git --params "/WindowsTerminal /NoShellIntegration /SChannel" >nul

    IF %ERRORLEVEL% EQU 0 (
        echo SUCCESS
    ) else (
        echo FAILED
        pause >nul & exit
    )
) else (
    echo [INFO] Installing Git... Skipping
)

:cygwin
IF "%CYGWIN_PATH%"=="" (
    echo|set /p="[INFO] Installing Cygwin... "

    Call :Browse4Folder "Choose location to install Cygwin"
) else (
    echo [INFO] Installing Cygwin... Skipping
)

IF "%CYGWIN_PATH%"=="" (
    IF "%Location%" NEQ "Dialog Cancelled" (
        if exist "%Location%/" (
            if not exist %Location%/bin/cygpath.exe (
                choco install --force cygwin --params "/InstallDir:%Location% /NoStartMenu" >nul

                IF %ERRORLEVEL% EQU 0 (
                    echo SUCCESS

                    setx CYGWIN_PATH %Location% >nul 2>nul
                    set CYGWIN_PATH=%Location% >nul 2>nul

                    goto vscode
                ) else (
                    echo FAILED
                    pause >nul & exit
                )
            ) else (
                echo SUCCESS

                setx CYGWIN_PATH %Location% >nul 2>nul
                set CYGWIN_PATH=%Location% >nul 2>nul

                ERR=Cygwin was already installed at %Location%
            )
        )
    )
    echo FAILED
    pause >nul & exit
)

:vscode
WHERE code >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
    echo|set /p="[INFO] Installing VSCode... "

    choco install --force -y vscode >nul

    IF %ERRORLEVEL% EQU 0 (
        echo SUCCESS
    ) else (
        echo FAILED
        pause >nul & exit
    )
) else (
    echo [INFO] Installing VSCode... Skipping
)

:jq
IF not exist "%CYGWIN_PATH%\bin\jq.exe" (
    echo|set /p="[INFO] Installing Jq... "

    choco install --force -y jq --source cygwin >nul

    IF %ERRORLEVEL% EQU 0 (
        echo SUCCESS
    ) else (
        echo FAILED
        pause >nul & exit
    )
) else (
    echo [INFO] Installing Jq... Skipping
)

:install
SET DIR=%~dp0
SET DIR=%DIR:~0,-1%

runas /user:%userdomain%\%username% "%PROGRAMFILES%\Git\bin\bash.exe %DIR%\install.sh %*"
exit


::***************************************************************************
:Browse4Folder
set Location=
set vbs="%temp%\_.vbs"
set cmd="%temp%\_.cmd"
for %%f in (%vbs% %cmd%) do if exist %%f del %%f
for %%g in ("vbs cmd") do if defined %%g set %%g=
(
    echo set shell=WScript.CreateObject("Shell.Application"^) 
    echo set f=shell.BrowseForFolder(0,"%~1",0,"%~2"^) 
    echo if typename(f^)="Nothing" Then  
    echo wscript.echo "set Location=Dialog Cancelled" 
    echo WScript.Quit(1^)
    echo end if 
    echo set fs=f.Items(^):set fi=fs.Item(^) 
    echo p=fi.Path:wscript.echo "set Location=" ^& p
)>%vbs%
cscript //nologo %vbs% > %cmd%
for /f "delims=" %%a in (%cmd%) do %%a
for %%f in (%vbs% %cmd%) do if exist %%f del /f /q %%f
for %%g in ("vbs cmd") do if defined %%g set %%g=
goto :eof
::***************************************************************************