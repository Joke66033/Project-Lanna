@echo off
title Lanna API Server
cd /d "%~dp0Lanna_API"
echo ===================================================
echo   Starting Lanna PHP API Server on http://localhost:8000
echo ===================================================
php -S 0.0.0.0:8000 router.php
if %ERRORLEVEL% neq 0 (
    echo.
    echo Failed to start PHP server. Please make sure PHP is installed and in your PATH.
    pause
)
