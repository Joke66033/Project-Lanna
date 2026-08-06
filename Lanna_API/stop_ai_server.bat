@echo off
echo Stopping Lanna AI Translation Server...
powershell -Command "Get-CimInstance Win32_Process | Where-Object {$_.CommandLine -match 'ai_server.py'} | ForEach-Object { Stop-Process -Id $_.ProcessId -Force; Write-Host 'Stopped process' $_.ProcessId }"
echo Done!
pause
