@echo off
REM Rebuilds client.swf from client\src, then deploys it so the account
REM server serves it at http://127.0.0.1:8080/client.swf
setlocal
set ROOT=%~dp0
set JAVA=%ROOT%tools\jre\jdk-11.0.32+9-jre\bin\java.exe
set SDK=%ROOT%tools\flexsdk
set CLIENT=%ROOT%client

"%JAVA%" -Xmx2g -jar "%SDK%\lib\mxmlc.jar" +flexlib="%SDK%\frameworks" ^
  -load-config="%ROOT%tools\build-config.xml" -theme= ^
  -external-library-path+="%ROOT%tools\playerglobal32_0.swc" ^
  -library-path+="%CLIENT%\libs" ^
  -library-path+="%SDK%\frameworks\libs\framework.swc" ^
  -source-path+="%CLIENT%\src" ^
  -swf-version=15 -default-size 800 600 -default-frame-rate 60 -default-background-color 0x000000 ^
  -optimize=true -use-direct-blit=true ^
  -keep-as3-metadata+=Inject -keep-as3-metadata+=Embed -keep-as3-metadata+=PostConstruct -keep-as3-metadata+=ArrayElementType ^
  -strict=true -warnings=false ^
  -o "%ROOT%client.swf" -- "%CLIENT%\src\WebMain.as"
if errorlevel 1 goto :fail

if not exist "%CLIENT%\bin" mkdir "%CLIENT%\bin"
copy /y "%ROOT%client.swf" "%CLIENT%\bin\client.swf" >nul
copy /y "%ROOT%client.swf" "%ROOT%source\Shared\resources\web\client.swf" >nul
copy /y "%ROOT%client.swf" "%ROOT%source\App\bin\Debug\net8.0\resources\web\client.swf" >nul
echo Client built and deployed.
goto :eof

:fail
echo Client build FAILED.
