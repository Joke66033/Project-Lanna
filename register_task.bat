@echo off
title Register Lanna API Task
echo ===================================================
echo   Registering Lanna API Server in Task Scheduler
echo ===================================================
echo.
schtasks /create /tn "LannaAPIServer" /tr "wscript.exe D:\PROJECT_LANNA\start_api_server.vbs" /sc onlogon /f
if %ERRORLEVEL% equ 0 (
    echo.
    echo Task "LannaAPIServer" has been registered successfully!
    echo It will now run automatically in the background when you log into Windows.
) else (
    echo.
    echo [ERROR] Failed to register task.
    echo Please right-click this file and select "Run as administrator".
)
echo.
pause
