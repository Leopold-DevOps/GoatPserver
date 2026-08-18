@echo off
REM Starts Redis + account server (8080) + world server (2050), then the client.
REM Layout: this repo is the root; toolchain lives in tools\.
set ROOT=%~dp0
set SRC=%ROOT%source

start "Redis"       cmd /k "cd /d %SRC%\Redis && redis-server.exe --port 6379"
timeout /t 3 >nul
start "AppEngine"   cmd /k "cd /d %SRC%\App\bin\Debug\net8.0 && App.exe"
timeout /t 3 >nul
start "WorldServer" cmd /k "cd /d %SRC%\WorldServer\bin\Debug\net8.0 && WorldServer.exe"
timeout /t 5 >nul
start "Client" "%ROOT%flashplayer_18_sa (1).exe" http://127.0.0.1:8080/client.swf
