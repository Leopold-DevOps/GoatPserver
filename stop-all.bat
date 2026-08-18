@echo off
REM Stops the servers and the client.
taskkill /IM "flashplayer_18_sa (1).exe" /F >nul 2>&1
taskkill /IM WorldServer.exe /F >nul 2>&1
taskkill /IM App.exe /F >nul 2>&1
taskkill /IM redis-server.exe /F >nul 2>&1
echo Stopped.
