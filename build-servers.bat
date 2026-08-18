@echo off
REM Rebuilds the C# servers after editing source.
dotnet build "%~dp0source\betterSkillys.sln" -c Debug
pause
