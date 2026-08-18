@echo off
REM Rebuilds client.swf from betterSkillys\client\src using the Apache Flex SDK in tools\.
setlocal
set ROOT=%~dp0
set SDK=%ROOT%tools\flexsdk
set CLIENT=%ROOT%betterSkillys\client

java -Xmx2g -jar "%SDK%\lib\mxmlc.jar" +flexlib="%SDK%\frameworks" ^
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

copy /y "%ROOT%client.swf" "%CLIENT%\bin\client.swf" >nul
pause
