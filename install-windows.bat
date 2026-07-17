@echo off
REM ============================================================
REM NEO Operator — Windows Installer
REM ============================================================
REM What this does:
REM   1. Checks if WSL 2 is installed (and installs it if not)
REM   2. Checks if Docker Desktop is installed (and walks you
REM      through install if not)
REM   3. Starts Docker if it isn't running
REM   4. Starts NEO Operator
REM   5. Opens your browser to NEO
REM
REM How to use:
REM   - Right-click this file -> "Run as administrator"
REM   - If Windows shows a blue "protected your PC" screen,
REM     click "More info" then "Run anyway"
REM   - Answer the prompts
REM   - Wait ~10-15 minutes the first time
REM
REM If anything breaks, just reply to the email that sent you
REM this file and describe what you saw.
REM ============================================================

setlocal enabledelayedexpansion
chcp 65001 >nul

echo.
echo ============================================================
echo                NEO Operator Installer for Windows
echo ============================================================
echo.
echo This will set up NEO Operator on your computer. It may take
echo 10-15 minutes the first time. You'll be asked a few yes/no
echo questions along the way.
echo.
echo ------------------------------------------------------------
echo  WINDOWS DEFENDER NOTICE (READ THIS FIRST):
echo ------------------------------------------------------------
echo  The first time you run a .bat file, Windows may show a
echo  blue screen that says "Windows protected your PC".
echo
echo  THIS IS NORMAL. To continue:
echo    1. Click "More info" (small text below the message)
echo    2. Click "Run anyway"
echo
echo  If you DO NOT see that blue screen and the window
echo  disappears instead, that means your double-click was
echo  blocked. Do this instead:
echo
echo    1. Press the Windows key, type: cmd
echo    2. Right-click "Command Prompt", choose "Run as admin"
echo    3. In the black window, type:
echo         cd "%~dp0"
echo         install-windows.bat
echo    4. Press Enter
echo ------------------------------------------------------------
echo.
pause

REM ---- Step 1: Check for admin ----
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ============================================================
    echo  ERROR: This installer needs to run as Administrator.
    echo ============================================================
    echo.
    echo  You probably double-clicked the file. That doesn't
    echo  automatically give it admin rights.
    echo.
    echo  DO THIS INSTEAD:
    echo    1. Press the Windows key, type: cmd
    echo    2. Right-click "Command Prompt", choose "Run as admin"
    echo    3. In the black window, type:
    echo         cd "%~dp0"
    echo         install-windows.bat
    echo    4. Press Enter
    echo.
    echo  OR right-click install-windows.bat in File Explorer
    echo  and choose "Run as administrator" (top option).
    echo.
    pause
    exit /b 1
)

echo [1/5] Checking Windows version...
ver | findstr /i "10\." >nul
if %errorLevel% neq 0 (
    echo.
    echo WARNING: This installer is designed for Windows 10.
    echo It may work on Windows 11 but is untested.
    echo.
    set /p CONTINUE="Continue anyway? (y/n): "
    if /i not "!CONTINUE!"=="y" exit /b 1
)

REM ---- Step 2: Install WSL ----
echo.
echo [2/5] Checking for WSL (Windows Subsystem for Linux)...
wsl --status >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo WSL is not installed. This is required for NEO Operator.
    echo Installing it now. Your computer may reboot.
    echo.
    set /p INSTALL_WSL="Install WSL? (y/n): "
    if /i not "!INSTALL_WSL!"=="y" exit /b 1

    wsl --install
    echo.
    echo WSL has been installed. Your computer needs to reboot
    echo before continuing.
    echo.
    echo After your computer restarts, find this file again
    echo (probably in your Downloads folder) and double-click it.
    echo.
    pause
    shutdown /r /t 0
    exit /b 0
)
echo    WSL is installed.

REM ---- Step 3: Check Docker ----
echo.
echo [3/5] Checking for Docker Desktop...
docker --version >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo Docker Desktop is not installed. This is required.
    echo.
    echo I'm going to open your browser to the Docker download
    echo page. Download and install Docker Desktop, then come
    echo back here and press any key.
    echo.
    echo IMPORTANT: When the installer asks about WSL 2, leave
    echo the checkbox CHECKED. That's the default.
    echo.
    pause
    start https://www.docker.com/products/docker-desktop/
    echo.
    echo (Waiting for you to finish installing Docker...)
    echo When Docker Desktop is installed and running (you'll
    echo see a whale icon in your system tray), press any key
    echo here to continue.
    pause

    REM Verify install
    docker --version >nul 2>&1
    if %errorLevel% neq 0 (
        echo.
        echo Docker still isn't detected. Make sure Docker
        echo Desktop is running (whale icon in system tray)
        echo and try again.
        echo.
        pause
        exit /b 1
    )
)
echo    Docker is installed.

REM ---- Step 4: Start Docker if not running ----
echo.
echo [4/5] Starting Docker Desktop (if not already running)...
docker info >nul 2>&1
if %errorLevel% neq 0 (
    echo Starting Docker Desktop. This takes about 30 seconds.
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo Waiting for Docker to be ready...
    :WAIT_DOCKER
    timeout /t 5 /nobreak >nul
    docker info >nul 2>&1
    if %errorLevel% neq 0 goto WAIT_DOCKER
)
echo    Docker is running.

REM ---- Step 5: Check for .env file ----
echo.
echo [5/5] Looking for your API key configuration...
if not exist ".env" (
    if exist ".env.example" (
        echo.
        echo No .env file found. Creating one from the template.
        echo.
        echo NEXT STEP: Open the file called .env in this folder
        echo with Notepad. Find the line that says:
        echo     DEEPSEEK_API_KEY=
        echo Replace it with your actual API key. Save the file.
        echo Then come back here and press any key.
        echo.
        echo Don't have an API key yet? Get one free at:
        echo https://platform.deepseek.com/api_keys
        echo.
        copy ".env.example" ".env"
        notepad ".env"
        echo.
        echo Did you save the file with your API key? Press any
        echo key to continue, or close this window to cancel.
        pause
    ) else (
        echo.
        echo ERROR: No .env or .env.example file found.
        echo Make sure you extracted the entire ZIP file, not
        echo just the install script.
        echo.
        pause
        exit /b 1
    )
)

REM ---- Start NEO Operator ----
echo.
echo ============================================================
echo                Starting NEO Operator
echo ============================================================
echo.
echo This takes 2-3 minutes the first time (downloading the
echo NEO Operator container). After that it's about 10 seconds.
echo.

docker compose up -d
if %errorLevel% neq 0 (
    echo.
    echo Something went wrong starting NEO Operator.
    echo.
    echo Common fixes:
    echo   - Make sure Docker Desktop is running
    echo   - Make sure you saved your .env file with a real API key
    echo   - Restart this installer
    echo.
    echo If you're stuck, reply to the email and tell me what
    echo you see.
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo           NEO Operator is running!
echo ============================================================
echo.
echo Opening your browser to NEO in 3 seconds...
timeout /t 3 /nobreak >nul
start http://localhost:8080

echo.
echo NEO is now running in your browser.
echo.
echo To use it again later:
echo   - Make sure Docker Desktop is running (whale icon)
echo   - Double-click this install.bat file again
echo   - Or just open http://localhost:8080 in your browser
echo.
echo To stop NEO: open a terminal here and run "docker compose down"
echo.
echo Questions? Reply to the email.
echo.
pause
