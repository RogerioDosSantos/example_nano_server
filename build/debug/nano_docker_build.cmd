@echo off
SETLOCAL EnableDelayedExpansion

set LOCAL_BIN_STAGING_DIR=BinariesToCopy
set VS_REMOTE_DEBUGGER_BIN="%VSINSTALLDIR%CoreCon\Binaries\Phone Tools\Debugger\target\x64"
set VS_REMOTE_DEBUGGER_LIB="%VSINSTALLDIR%CoreCon\Binaries\Phone Tools\Debugger\target\lib"
rem set VS_CRT_REDIST_REL="%VcToolsRedistDir%onecore\x64\Microsoft.VC150.CRT"
set VS_CRT_REDIST_REL="%VcToolsRedistDir%onecore\x64\Microsoft.VC141.CRT"
rem set VS_CRT_REDIST_DBG="%VcToolsRedistDir%onecore\debug_nonredist\x64\Microsoft.VC150.DebugCRT"
set VS_CRT_REDIST_DBG="%VcToolsRedistDir%onecore\debug_nonredist\x64\Microsoft.VC141.DebugCRT"
set UCRT_DLL_PATH="%WindowsSdkBinPath%\x64\ucrt"

set VS_OUT_DIR=%1
set DockerImageName=nanodbg

:: Check execution environment
if "%VSINSTALLDIR%" == "" (
    goto RunFromDevCmd
)

:: Check for valid Usage
if "%1"=="" ( 
    goto Usage
)

if not exist %VS_OUT_DIR% (
    goto InvalidDeployPath
)

::Check for VS 2017 + Pre-reqs
if not exist %VS_REMOTE_DEBUGGER_BIN% (
    goto NoVs
) 

::Check for docker
call docker.exe version >nul
if ERRORLEVEL 1 (
    goto NoDocker
)

:: Copy to local staging directory
echo Staging Remote Binaries...
call robocopy.exe %VS_REMOTE_DEBUGGER_BIN% %LOCAL_BIN_STAGING_DIR% /S /E >nul
if %ERRORLEVEL% GTR 8 (
    echo Error while staging debugger binaries - Debugger BIN. Exiting...
    exit /b 1
)

call robocopy.exe %VS_REMOTE_DEBUGGER_LIB% %LOCAL_BIN_STAGING_DIR% /S /E >nul
if %ERRORLEVEL% GTR 8 (
    echo Error while staging debugger binaries - Debugger LIB. Exiting...
    exit /b 1
)

call robocopy.exe %VS_CRT_REDIST_DBG% %LOCAL_BIN_STAGING_DIR% /S /E >nul
if %ERRORLEVEL% GTR 8 (
    echo Error while staging debugger binaries - C++ Runtime Debug. Exiting...
    exit /b 1
)

call robocopy.exe %VS_CRT_REDIST_REL% %LOCAL_BIN_STAGING_DIR% /S /E >nul
echo C++ Runtime Release
if %ERRORLEVEL% GTR 8 (
    echo Error while staging debugger binaries - C++ Runtime Release. Exiting...
    exit /b 1
)

echo Universal C++ Runtime
call robocopy.exe %UCRT_DLL_PATH% %LOCAL_BIN_STAGING_DIR% /S /E >nul
if %ERRORLEVEL% GTR 8 (
    :: Non-fatal error, but debug binaries won't work
    echo Warning! Unable to stage UCRT dll, debug binaries will not run in the container.
)

echo Building container...
set dockerBuildCmd=docker build ^
    --no-cache ^
    -t %DockerImageName% ^
    --build-arg VS_REMOTE_DEBUGGER_PATH=%LOCAL_BIN_STAGING_DIR% ^
    --build-arg VS_OUT_DIR=%VS_OUT_DIR% ^
    .
call %dockerBuildCmd% >nul

if ERRORLEVEL 1 (
    echo Encountered error while building Container, exiting..
    goto :EOF
)


echo Launching Nano Container...
set dockerRunCmd=docker run ^
    --name nanodbg ^
    --rm -it ^
    -d ^
    -v %VS_OUT_DIR%:%VS_OUT_DIR% ^
    %DockerImageName%


::Capture the Container ID
for /f "tokens=*" %%i in ('%dockerRunCmd% ^| findstr /r "^[0-z].*"') do set CONID=%%i

if ERRORLEVEL 1 (
    echo Encountered error while launching Nano Container, exiting..
    goto :EOF
)

echo.
echo   Nano Server Container started with id: %CONID:~0,12%
echo.

:: cleanup staged files
if exist %local_bin_staging_dir% (
    rd /q /s %local_bin_staging_dir%
)

goto :EOF

:InvalidDeployPath
echo.
echo   Incorrect test binaries path 
echo.
goto :EOF

:RunFromDevCmd
echo.
echo  Please run the script in a Visual Studio Developer Command Prompt 
echo.
goto :EOF

:NoVs
echo.
echo Pre-requisites missing:
echo.
echo    Visual Studio 2017 with following workloads:
echo        Universal Windows Platform Development
echo        Desktop Development with C++
echo.
echo    Free Commmunity Edition available from visualstudio.com
echo.
goto :EOF

:NoDocker
echo.
echo Pre-requisites missing:
echo.
echo    Docker for Windows missing or not in PATH
echo.
echo    Free download available at: https://docs.docker.com/docker-for-windows/
echo.
goto :EOF

:Usage
echo.
echo Usage:
echo.
echo    NanoDockerBuild.cmd [full-path-to-test-binaries]
echo.
goto :EOF
