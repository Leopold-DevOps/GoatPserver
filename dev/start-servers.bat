@echo off
REM Starts Redis + account server (8080) + world server (2050) in separate windows.
set ROOT=%~dp0betterSkillys\source

start "Redis"       cmd /k "cd /d %ROOT%\Redis && redis-server.exe --port 6379"
timeout /t 2 >nul
start "AppEngine"   cmd /k "cd /d %ROOT%\App\bin\Debug\net8.0 && App.exe"
timeout /t 2 >nul
start "WorldServer" cmd /k "cd /d %ROOT%\WorldServer\bin\Debug\net8.0 && WorldServer.exe"
