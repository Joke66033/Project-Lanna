Set WshShell = CreateObject("WScript.Shell")
' Run the Python server invisibly (0 = hidden window)
WshShell.Run "cmd /c D:\PROJECT_LANNA\.venv\Scripts\python D:\PROJECT_LANNA\Lanna_API\ai_engine\ai_server.py", 0, false
