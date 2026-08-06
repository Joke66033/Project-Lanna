@echo off
title Lanna API & AI Model Server
cd /d "%~dp0Lanna_API"
set "PYTHON_EXE=%~dp0.venv\Scripts\python.exe"
if not exist "%PYTHON_EXE%" (
    echo [ERROR] Python environment not found at:
    echo %PYTHON_EXE%
    echo Run: python -m venv .venv
    echo Then install: .venv\Scripts\python.exe -m pip install -r Lanna_API\ai_engine\requirements.txt
    pause
    exit /b 1
)
echo ===================================================
echo   Starting Lanna AI Model Server on port 8005...
echo ===================================================
start "Lanna AI Server" /min "%PYTHON_EXE%" ai_engine\ai_server.py
timeout /t 2 /nobreak > nul

echo ===================================================
echo   Starting Lanna PHP API Server on http://localhost:8000
echo ===================================================
php -S 0.0.0.0:8000 router.php
if %ERRORLEVEL% neq 0 (
    echo.
    echo Failed to start PHP server. Please make sure PHP is installed and in your PATH.
    pause
)
