@echo off
REM Rebuilds the C# servers after editing source.
dotnet build "%~dp0betterSkillys\source\betterSkillys.sln" -c Debug
pause
