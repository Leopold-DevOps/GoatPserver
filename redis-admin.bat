@echo off
REM Interactive admin tool for the Redis database (accounts, rank, fame, chars).
REM Requires redis-server to be running - start-all.bat does that.
python "%~dp0dev\redis-admin.py"
pause
