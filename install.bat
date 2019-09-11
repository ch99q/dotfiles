@echo off

WHERE choco >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
    if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
    
    @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
)

WHERE git >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
    if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
    
    choco install -y git --params "/WindowsTerminal /NoShellIntegration /GitOnlyOnPath /SChannel"
)

reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v HideFileExt /t REG_DWORD /d 0 /f
powershell -c gps 'explorer' ^| stop-process

rd /s /q "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Git"

"%PROGRAMFILES%\Git\bin\bash.exe" .\install.sh