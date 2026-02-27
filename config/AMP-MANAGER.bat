@echo off
:: ==========================================================
:: AMP-MANAGER.BAT
:: A simple batch script to manage and scaffold a local AMP stack
:: Designed for Windows with Angie, MariaDB, PHP, and mkcert (SSL).
:: Provides a user-friendly terminal UI for configuration checks, 
:: domain management, and CA handling.
:: Author: Nuno Luciano
:: Date: 2026-02-25
:: Version: 1.11.3
:: LICENSE: MIT
:: ==========================================================
:: WARNING: UI ENCODING LOCK
:: This file MUST be saved in: ISO-8859-13 (Baltic)
:: The terminal MUST run in:   CP 850 (Western DOS)
:: Changing encoding will destroy the ASCII UI alignment.
:: ==========================================================
setlocal EnableDelayedExpansion

:: UAC ADMIN & CONHOST RUN
net file >nul 2>&1 || (
    powershell -Command "Start-Process conhost.exe -ArgumentList 'cmd.exe /c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

:: SINGLE INSTANCE LOCK
set "LOCKED=FALSE"
for /L %%i in (1,1,30) do (
    if "!LOCKED!"=="FALSE" (
        (9>"%TEMP%\amp_manager.lock" (
            set "LOCKED=TRUE"
            call :MAIN_LOGIC
            REM EXIT AFTER CLOSING MANAGER
            exit /b
        )) 2>nul
    )
    :: Delay (100ms) before retry
    if "!LOCKED!"=="FALSE" ping 127.0.0.1 -n 1 -w 100 >nul
)

:: ONLY SHOWS IF THE LOOP FINISHES WITHOUT LOCKING
cls
echo.
echo   %RED%[!] ERROR: AMP-MANAGER ALREADY ACTIVE%RS%
echo   --------------------------------------------
echo   Another window is already open.
echo.
pause
exit /b


:: ---------- ---------- ---------- MAIN

:MAIN_LOGIC
:: ENVIRONMENT SETUP
:: Sets PROJECT_ROOT to parent folder of script's location
cd /d "%~dp0"
for %%i in ("%~dp0..") do set "PROJECT_ROOT=%%~fi"

:: Global variables for paths and URLs
set "DRV=%~d0\"
set "URL=https://angie.local/"

:: COMPONENT PATHS
set "MKCERT=%PROJECT_ROOT%\config\mkcert.exe"
set "CERT_FOLDER=%PROJECT_ROOT%\config\certs"
set "CONFIG_FOLDER=%PROJECT_ROOT%\config\angie-sites"
set "WWW_FOLDER=%PROJECT_ROOT%\www"
set "HOSTS=%windir%\System32\drivers\etc\hosts"


:: ---------- ---------- ---------- WINDOW SETTINGS & THEME

:: ---------- ---------- IMPORTANT - USE IBM 850 ENCODING
CHCP 850 >NUL 2>&1
MODE CON COLS=80 LINES=42
TITLE AMP Manager

:: ---------- ---------- THEME SETTINGS
:: RGB values for the UI
set "BG_UI=19;17;15"
set "FG_UI=5;110;225"
set "LN_UI=120;140;207"
set "TX_UI=199;228;227"
set "RD_UI=240;65;90"
set "GR_UI=99;201;74"
set "OR_UI=240;140;10"

:: Capture the REAL Escape character
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
:: RS (reset): Returns to Theme colors
set "RS=%ESC%[48;2;%BG_UI%;38;2;%FG_UI%m"

:: Define modular color variables
:: SET_UI: Full Background + Foreground
set "SET_UI=%ESC%[48;2;%BG_UI%;38;2;%FG_UI%m"
:: LN: Line numbers and accents
set "LN=%ESC%[38;2;%LN_UI%m"
:: TX: Dynamic text (time, date, status)
set "TX=%ESC%[38;2;%TX_UI%m"
:: UI Colors Foreground [38;2;R;G;Bm]
set "RED=%ESC%[38;2;%RD_UI%m"
set "GRN=%ESC%[38;2;%GR_UI%m"
set "ORA=%ESC%[38;2;%OR_UI%m"
:: UI Colors Background [48;2;R;G;Bm]
set "RBG=%ESC%[48;2;%RD_UI%m"
set "GBG=%ESC%[48;2;%GR_UI%m"
:: Apply Initial UI Theme
echo %SET_UI%
CLS


:: ---------- ---------- ---------- MENU SETUP

:MENU

:: ---------- ---------- LOOP: DOMAIN DISCOVERY

:DOMAIN_SCAN
:: Reset variables before scan to avoid duplicates on menu refresh
set "DOMAINS="
set "COUNT=0"

:: RegEx:
:: findstr looks for '127.0.0.1' followed by any characters and ending in '.local'
:: tokens=2 grabs the second column (the domain name)
for /f "tokens=2" %%D in ('findstr /i /r "127\.0\.0\.1.*\.local" "%HOSTS%" 2^>nul') do (
    set "DOMAINS=!DOMAINS! "%%D""
    set /a COUNT+=1
)

:: ---------- ---------- DATE/TIME CAPTURE

:: DATE
:: Get the raw LocalDateTime
:: Format is: 202602200544...
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
:: Slice the string into ISO parts
set "YYYY=%dt:~0,4%"
set "MM=%dt:~4,2%"
set "DD=%dt:~6,2%"
:: Create the final ISO string: 2026-02-20
set "DATE=%YYYY%-%MM%-%DD%"

:: TIME
:: Capture current time and format to 24h (HHhMM)
set "raw_time=%TIME%"
:: Replace the space with a 0 if the hour is before 10am
if "%raw_time:~0,1%"==" " set "raw_time=0%raw_time:~1%"
:: Slice: HH from 0,2 and MM from 3,2
set "TIME=%raw_time:~0,2%h%raw_time:~3,2%"

:: ---------- ---------- CHECK STATUS
:: Initialize Global Status as Green
set "RAS=%GBG%"
:: Reset individual flags
set "S1_COL=%RED%"
set "S2_COL=%RED%"
set "S3_COL=%RED%"
set "S4_COL=%RED%"
set "S5_COL=%RED%"
set "S6_COL=%RED%"
set "S7_COL=%RED%"
set "S8_COL=%RED%"
set "S9_COL=%RED%"
set "S10_COL=%RED%"
set "S11_COL=%RED%"
set "S12_COL=%RED%"
set "S13_COL=%RED%"
set "MKCERT_CHECK=FALSE"
set "CAROOT_CHECK=FALSE"
set "ACTUAL_CAROOT="
set "DOCKER_RUN=FALSE"
:: Run Checks & Flip Global Status if any fail
if exist "%PROJECT_ROOT%\docker-compose.override.yml"         (set "S1_COL=%GRN%") else (set "RAS=%RED%")
if exist "%PROJECT_ROOT%\config\angie-sites\angie.local.conf" (set "S2_COL=%GRN%") else (set "RAS=%RED%")
if exist "%PROJECT_ROOT%\config\db-init\01-grant-root.sql"    (set "S3_COL=%GRN%") else (set "RAS=%RED%")
if exist "%PROJECT_ROOT%\config\php.ini"                      (set "S4_COL=%GRN%") else (set "RAS=%RED%")
if exist "%PROJECT_ROOT%\data\"                               (set "S5_COL=%GRN%") else (set "RAS=%RED%")
if exist "%PROJECT_ROOT%\www\angie.local\"                    (set "S6_COL=%GRN%") else (set "RAS=%RED%")
if exist "%PROJECT_ROOT%\config\certs\angie.local.pem"        (set "S7_COL=%GRN%") else (set "RAS=%RED%")

:: MKCERT BINARY CHECK
if exist "%MKCERT%" (set "S8_COL=%GRN%" & set "MKCERT_CHECK=TRUE") else (set "MKCERT_CHECK=FALSE" & set "RAS=%RED%")
:: GET CAROOT PATH
for /f "delims=" %%i in ('"%MKCERT%" -CAROOT') do set "ACTUAL_CAROOT=%%i"
:: CHECK rootCA.pem EXISTS
if exist "%ACTUAL_CAROOT%\rootCA.pem" (set "S9_COL=%GRN%" & set "CAROOT_CHECK=OK") else (set "CAROOT_CHECK=FALSE" & set "RAS=%RED%")
:: MANDATORY CA ENFORCEMENT
:: If mkcert exists but not CA, go to the install wizard immediately
::if "%CAROOT_CHECK%"=="FALSE" (
::    if "%MKCERT_CHECK%"=="TRUE" goto :CA_INSTALL_WIZARD
::)

:: DOCKER ENGINE CHECK
docker version >nul 2>&1 && (set "S10_COL=%GRN%" & set "DOCKER_RUN=TRUE") || (set "RAS=%RED%")

if "%DOCKER_RUN%"=="TRUE" (
docker ps --filter "status=running" | findstr "angie" >nul && (set "S11_COL=%GRN%") || (set "RAS=%RED%")
docker ps --filter "status=running" | findstr "db" >nul && (set "S12_COL=%GRN%") || (set "RAS=%RED%")
docker ps --filter "status=running" | findstr "php" >nul && (set "S13_COL=%GRN%") || (set "RAS=%RED%")
) else (
    set "RAS=%RED%"
)

:: Render 'ş' (square)+RS
set "S1=%S1_COL%ş%RS%"
set "S2=%S2_COL%ş%RS%"
set "S3=%S3_COL%ş%RS%"
set "S4=%S4_COL%ş%RS%"
set "S5=%S5_COL%ş%RS%"
set "S6=%S6_COL%ş%RS%"
set "S7=%S7_COL%ş%RS%"
set "S8=%S8_COL%ş%RS%"
set "S9=%S9_COL%ş%RS%"
set "S10=%S10_COL%°°°°°%RS%"
set "S11=%S11_COL%ÄÄÄÄÄ%RS%"
set "S12=%S12_COL%ÄÄÄÄÄ%RS%"
set "S13=%S13_COL%ÄÄÄÄÄ%RS%"

:: Global AMP Status
set "GAS=%RAS%"

:: ---------- ---------- RENDER UI
:: IMPORTANT: IBM 850, but saved as ISO-8859-13
CLS
echo °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
echo.
echo                              _______ _______  _____ 
echo                              ^|_____^| ^|  ^|  ^| ^|_____]
echo                              ^|     ^| ^|  ^|  ^| ^|
echo                              Angie - MariaDB - PHP
echo.
echo   ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿         ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿         ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
echo   ³     %TX%%TIME%%RS%    ÃÄÄÄÄÄÄÄÄÄ´       %TX%AMP-MANAGER%RS%      ÃÄÄÄÄÄÄÄÄÄ´  %TX%%DATE%%RS%  ³
echo   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ         ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ         ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
echo      ³                           ³            ³                           ³
echo   ÚÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄ¿
echo   ³ RUN ³          COMPONENT            ³ %TX%%DRV%%RS% ³     %TX%CONFIGURATION%RS%      ³ %TX%RDY%RS% ³
echo   ÃÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄ´
echo   ³%S10%%RS%ÃÄ DOCKER CONTAINER             ÃÄ docker-compose.override.yml ÃÄ %S1% Ä´
echo   ³%S11%%RS%ÃÄ Angie Web Server             ÃÄ amp\config\angie-sites      ÃÄ %S2% Ä´
ECHO   ³%S12%%RS%ÃÄ MariaDB Root                 ÃÄ amp\config\db-init          ÃÄ %S3% Ä´
ECHO   ³%S13%%RS%ÃÄ PHP Configuration            ÃÄ amp\config\php.ini          ÃÄ %S4% Ä´
ECHO   Ã°°°°°Åş Data (default database)      ÃÄ amp\data\ampdb              ÃÄ %S5% Ä´
ECHO   Ã°°°°°Åş Dashboard Angie.local        ÃÄ amp\www\angie.local         ÃÄ %S6% Ä´
ECHO   Ã°°°°°ÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄ angie.local SSL certificate ÃÄ %S7% Ä´
ECHO   Ã°°°°°Å%S8% %TX%Mkcert SSL/TLS certificate   %RS%ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÂÄÄÙ
ECHO   ÃÄ C ÄÅ%S9% %TX%Certificate Authority (CA)%RS%                                     ³
echo   ÃÄ A ÄÅş %TX%All Domains in Windows (HOSTS)%RS%                                 ³
ECHO   ÃÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
ECHO   ÃÄ S ÄÅş %TX%Sites managed by AMP %RS%                                          ³
ECHO   ÃÄ N ÄÅş %TX%NEW Domain%RS%                                                     ³
ECHO   ÃÄ R ÄÅş %TX%Remove Domain%RS%                                                  ³
ECHO   ÃÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
ECHO   ÃÄ O ÄÅş %TX%Open Browser%RS%                                                   ³
ECHO   ÃÄ H ÄÅş %TX%Help%RS%                                                           ³
ECHO   ÃÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄ¿                                            ÚÄÄÄÄÄÄÄÁÄÄ¿
ECHO   ÃÄ D ÄÅş %TX%DOCKER%RS%    ³                                            ³%GAS%  STATUS  %RS%³
ECHO   ÃÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄ´                                            ÀÄÄÄÄÄÄÄÂÄÄÙ
ECHO   ÃÄ X ÄÅş %TX%EXIT%RS%      ³                                                    ³
ECHO   ÀÄÄÂÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
ECHO      ³°°°°°°°°°°°°°°°°°°°°°°°°°A°M°P°°v°1°11°3°°°°°°°°°°°°°°°°°°°°°°°°°°°°³
ECHO    ÚÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
echo   °³°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° 
echo    ³
:: Seat Number :       1 2 3 4 5 6 7 8 9
:: Key Assigned:       C A S N R O H D X
:: choice /c CSLNRBHAX /n /m "%ESC%   Select: "
choice /c CASNROHDX /n /m "%RS%   ÀÄş %TX%Select an option:%RS%"
echo.
:: Mapping:
if errorlevel 9 goto :EXIT          :: X
if errorlevel 8 goto :DOCKERUN      :: D
if errorlevel 7 goto :HELP          :: H
if errorlevel 6 goto :BROWSER       :: O
if errorlevel 5 goto :REMOVEDOMAIN  :: R
if errorlevel 4 goto :NEWDOMAIN     :: N
if errorlevel 3 goto :SSL           :: S
if errorlevel 2 goto :LISTDOMAIN    :: A
if errorlevel 1 goto :CAUTHORITY    :: C


:: ---------- ---------- ---------- SSL

:SSL
cls
:: Refresh the master list of all domains
call :GET_DOMAINS

:SSL_LOOP
call :LIST_TABLE "AMP SITES                                                               " "AMP_ONLY"
if %errorlevel% equ 0 goto MENU
:: MAP IDs to domains in a temporary array for direct access
:: The ID chosen is already valid from the array
set "TARGET=!MAP_%RESULT_ID%!"
if "!TARGET!"=="" goto SSL_LOOP

start https://!TARGET!
goto SSL_LOOP

:: ---------- ---------- ---------- CA

:CAUTHORITY
cls
call :DRAW_HEADER "Certificate Authority (CA) Management                                   "
echo.
CALL :ALERT "%ORA%CRITICAL%RS%" "%TX%The CA is the trust anchor for ALL local SSL certificates.%RS%"
echo.
echo         %TX%If you reset the CA,%RS% %RED%all existing sites will become INSECURE%RS% %TX% 
echo         until their certificates are re-generated.%RS%
echo.
echo         [1] %RED%Reset CA Wizard     (Uninstall, Wipe, and Fresh Install)%RS% 
echo         [2] %GRN%Managed SSL Sites%RS%   (Issued certs for existing domains)
echo         [3] %GRN%Help SSL%RS%            (Troubleshoot "Insecure" errors)
echo         [4] %GRN%Help System Info%RS%    (AMP and mkcert on Windows/Browsers)
echo         [5] %TX%Return to Menu      (Safe choice - No changes)%RS%
echo.
echo         ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
echo.

:: custom prompt without a newline
set "C_SELECT="
<nul set /p "=%TX%        Select Option [1-5] or [M]:%RS% "

set /p "C_SELECT="

if /I "!C_SELECT!"=="M" goto MENU
if "!C_SELECT!"=="5" goto MENU

:: OPTION 1: RESET
if "!C_SELECT!"=="1" (
    echo.
    call :ALERT "DANGER" "This will invalidate ALL current .local certificates!"
    set /p "CONFIRM= Are you sure? [Y/N]: "
    if /I "!CONFIRM!"=="Y" goto MKCERT_INSTALL
    goto CAUTHORITY
)

:: OPTION 2: GOTO SSL LIST
if "!C_SELECT!"=="2" (
    echo  Navigating to Managed Sites...
    timeout /t 2 >nul
    goto SSL
)

:: OPTION 3: GOTO HELP (SSL SECTION)
if "!C_SELECT!"=="3" (
    set "FAQ_ID=3"
    goto HELP_LOOP
)

:: OPTION 4: GENERAL HELP
if "!C_SELECT!"=="4" (
    goto HELP
)

:: FALLBACK
echo  %RED%Invalid option.%RS%
timeout /t 2 >nul
goto CAUTHORITY

:MKCERT_INSTALL
echo.
echo  ---------------------------------------------------------
echo   Resetting and Installing mkcert Root Certificate Authority
echo  ---------------------------------------------------------
echo.

:: Uninstall previous CA (removes from Windows + browsers)
echo  Uninstalling previous mkcert CA...
:: REMOVE powershell / MISMATCH ERRORS
::powershell -Command "Start-Process '%MKCERT%' -ArgumentList '-uninstall' -Verb RunAs"

:: RUN UNINSTALL
"%MKCERT%" -uninstall >nul 2>&1

:: Detect mkcert CA root folder
for /f "delims=" %%i in ('"%MKCERT%" -CAROOT 2^>nul') do set "TEMP_CAROOT=%%i"

:: Delete mkcert folder completely
if defined TEMP_CAROOT (
    if exist "!TEMP_CAROOT!" (
        echo  Cleaning mkcert folder...
        rem rmdir /s /q "!TEMP_CAROOT!" >nul 2>&1
        rem force remove folder mkcert
        rmdir /s /q "%LOCALAPPDATA%\mkcert" >nul 2>&1
        timeout /t 1 >nul
    )
)

:: Check folder removed
if exist "!TEMP_CAROOT!" (
    echo  [ERROR] mkcert folder could not be removed.
    echo  Close Docker Desktop, Angie, editors, terminals, then retry.
    echo.
    pause
    goto MENU
)

echo.
echo  A Windows security prompt will appear.
echo  You MUST click YES to trust the new Root CA.
echo.
pause

:: Install new CA
:: REMOVED UAC ELEVATION/MISMATCH ERRORS
:: powershell -Command "Start-Process '%MKCERT%' -ArgumentList '-install' -Verb RunAs"
"%MKCERT%" -install >nul 2>&1

:: Wait for mkcert to finish writing CA files
set "TEMP_CAROOT="
for /f "delims=" %%i in ('"%MKCERT%" -CAROOT 2^>nul') do set "TEMP_CAROOT=%%i"

set "WAIT_COUNT=0"
:WAIT_FOR_CA
if exist "!TEMP_CAROOT!\rootCA.pem" if exist "!TEMP_CAROOT!\rootCA-key.pem" goto CA_READY

timeout /t 1 >nul
set /a WAIT_COUNT+=1
if %WAIT_COUNT% GEQ 10 goto CA_TIMEOUT
goto WAIT_FOR_CA

:CA_READY
call :SUCCESS "SUCCESS" "mkcert Root CA successfully installed."
goto MENU

:CA_TIMEOUT
call :ALERT "ERROR" "mkcert CA installation did not complete in time."
goto MENU

:: Refresh CAROOT path
set "TEMP_CAROOT="
for /f "delims=" %%i in ('"%MKCERT%" -CAROOT 2^>nul') do set "TEMP_CAROOT=%%i"

:: Check that mkcert created the CA files
if exist "!TEMP_CAROOT!\rootCA.pem" if exist "!TEMP_CAROOT!\rootCA-key.pem" (
    echo  [SUCCESS] mkcert Root CA successfully installed.
    echo  CAROOT: !TEMP_CAROOT!
    echo.
    timeout /t 2 >nul
    pause
    goto MENU
)

echo  [ERROR] mkcert CA installation failed.
echo  The CA files were not created.
echo.
pause
goto MENU


:: ---------- ---------- ---------- LIST DOMAIN

:LISTDOMAIN
cls
:: Safety check for empty hosts
if "!DOMAINS!"=="" ( 
    cls
    call :DRAW_HEADER "ERROR"
    echo   No local domains detected in hosts file. 
    pause
    goto MENU 
)

:: use shared UI
call :LIST_TABLE "ACTIVE LOCAL DOMAINS                                                    "

echo    ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
echo.   
echo    Return to menu...
timeout /t 2 >nul
goto MENU


:: ---------- ---------- ---------- NEW DOMAIN

:NEWDOMAIN
cls
call :DRAW_HEADER "Create New Local Domain                                                 "
ECHO.
echo         %TX%Scaffolding a new project creates a server configuration, SSL, 
echo         and optionnally a standardized directory structure.%RS%
ECHO.
echo         %ORA%NOTE:%RS% %TX%A protection mechanism prevents overriding ANGIE.LOCAL 
echo         You can update its .conf and SSL if you have changed the CA.%RS%
echo.
echo         ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
echo.
:: Clear the variable first
set "DOMAIN_NAME="

:: Custom prompt without a newline
<nul set /p "=%TX%        Enter name (e.g. project): %RS%"

:: prompt empty string
set /p DOMAIN_NAME=""

:: Validation
if "!DOMAIN_NAME!"=="" (
    echo.
    echo         %ORA%[SKIP]%RS% No name entered. Returning to menu...
    timeout /t 2 >nul
    goto MENU
)

:: SANITIZATION
:: Force lowercase - prevents Linux/Windows casing conflicts
for %%A in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
    set "DOMAIN_NAME=!DOMAIN_NAME:%%A=%%A!"
)

:: Remove spaces and accidental .local suffixes
set "DOMAIN_NAME=!DOMAIN_NAME: =!"
set "DOMAIN_NAME=!DOMAIN_NAME:.local=!"

:: DEFINE FINAL VARIABLES
set "FULL_DOMAIN=!DOMAIN_NAME!.local"
set "TARGET_DIR=%WWW_FOLDER%\!FULL_DOMAIN!"

:: CONFLICT VALIDATION
:: Check if the directory already exists to prevent overwriting
findstr /i /c:"127.0.0.1 !FULL_DOMAIN!" "%HOSTS%" >nul
if !errorlevel! == 0 (
    echo.
    echo         %ORA%Check if HOSTS entry exists...%RS%
    echo.
    call :ALERT "Error" "!FULL_DOMAIN! already exists in hosts."
    echo.
    pause & goto DOMAIN_SCAN
)

:: FOLDER SCAFFOLDING & PROTECTION
if /I "!DOMAIN_NAME!"=="angie" (
    echo.
    echo         %ORA%[SYSTEM]%RS% Detected angie.local - Preserving assets.
    goto SKIP_SCAFFOLD
)

if not exist "!TARGET_DIR!" (
    REM CASE A: NEW PROJECT
    echo.
    call :ALERT "%ORA%NOTICE%RS%" "%TX%Project folder missing at:%RS%"
    echo         ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    echo.
    echo         !TARGET_DIR!
    echo.
    echo         ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    echo.

    rem custom input for scaffolding
    <nul set /p "=%TX%        Create folder and deploy scaffold? [Y/N]: %RS%"

    rem clear non-numeric to prevent errors
    set /p "CREATE_FOLDER="
    rem Handle Exit first

    if /I "!CREATE_FOLDER!"=="Y" (
        mkdir "!TARGET_DIR!" 2>nul
        
        if exist "%WWW_FOLDER%\_scaffold\" (
            echo         %ORA%[INFO]%RS% Deploying templates...
            xcopy /E /I /Y "%WWW_FOLDER%\_scaffold\*" "!TARGET_DIR!\" >nul
            
            if exist "!TARGET_DIR!\index.php" (
                powershell -Command "(Get-Content '!TARGET_DIR!\index.php') -replace '\{\{DOMAIN\}\}', '!FULL_DOMAIN!' | Set-Content '!TARGET_DIR!\index.php'"
            )
        ) else (
            call :ALERT "ERROR" "Scaffold missing! Using basic fallback..."
            mkdir "!TARGET_DIR!\error-pages" 2>nul
            echo ^<?php echo "Welcome to !FULL_DOMAIN!"; ?^> > "!TARGET_DIR!\index.php"
        )
    ) else (
        echo         %ORA%[SKIP]%RS% Scaffolding aborted.
        timeout /t 2 >nul
        goto MENU
    )
) else (
    :: CASE B: EXISTING PROJECT
    echo.
    call :ALERT "%RED%WARNING%RS%" "%TX%Project folder already exists:%RS%"
    echo         ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    echo.
    echo         !TARGET_DIR!
    echo.
    echo         ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    echo.

    rem custom input for SSL/Config setup
    <nul set /p "=%TX%         Continue with SSL/Config setup anyway? [Y/N]: %RS%"

    rem clear non-numeric to prevent errors
    set /p "CONTINUE="
    rem Handle Exit first

    if /I "!CONTINUE!" NEQ "Y" (
        echo         %ORA%[SKIP]%RS% Setup aborted by user.
        goto MENU
    )
)

:SKIP_SCAFFOLD

:: SAFETY BACKUP
copy /y "%HOSTS%" "%HOSTS%.bak" >nul

:: SSL GENERATION
"%MKCERT%" -cert-file "%CERT_FOLDER%\!FULL_DOMAIN!.pem" -key-file "%CERT_FOLDER%\!FULL_DOMAIN!-key.pem" "!FULL_DOMAIN!" "localhost" 127.0.0.1 ::1

:: UPDATE HOSTS AND FLUSH DNS
echo 127.0.0.1 !FULL_DOMAIN! >> "%HOSTS%"
ipconfig /flushdns >nul

:: SITE CONFIG GENERATION
(
echo # HTTP Redirect to HTTPS
echo server {
echo     listen 80;
echo     server_name !FULL_DOMAIN!;
echo     return 301 https://^$host^$request_uri;
echo }
echo.
echo # Main SSL Block
echo server {
echo     listen 443 ssl;
echo     http2 on;
echo     server_name !FULL_DOMAIN!;
echo.
echo     # API Zone
echo     status_zone !FULL_DOMAIN!;
echo.
echo     # Docker Internal DNS
echo     resolver 127.0.0.11 valid=30s;
echo     set ^$upstream_php php;
echo.
echo     ssl_certificate     /etc/angie/certs/!FULL_DOMAIN!.pem;
echo     ssl_certificate_key /etc/angie/certs/!FULL_DOMAIN!-key.pem;
echo.
echo     # Performance: Compression
echo     gzip on;
echo     gzip_types text/plain text/css application/javascript application/json image/svg+xml;
echo.
echo     # SECURITY
echo     add_header X-Frame-Options "SAMEORIGIN" always;
echo     add_header X-Content-Type-Options "nosniff" always;
echo     add_header X-XSS-Protection "1; mode=block" always;
echo.
echo     # DEVELOPMENT API CONFIG
echo     add_header 'Access-Control-Allow-Origin' '*' always;
echo     add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, DELETE, PUT' always;
echo     add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
echo.
echo     # SERVER IDENTITY
echo     add_header X-Served-By "Angie 1.11.3 [DEV-MODE] - !FULL_DOMAIN!" always;
echo.
echo     root /www/!FULL_DOMAIN!;
echo     index index.php index.html;
echo.
echo     # Global error pages
echo     error_page 404 /error-pages/404.php;
echo     error_page 500 502 503 504 /error-pages/50x.php;
echo     error_page 503 /error-pages/maintenance.php;
echo.
echo     location / {
echo         try_files ^$uri ^$uri/ /index.php?^$query_string;
echo     }
echo.
echo     location ~ \.php^$ {
echo         fastcgi_pass ^$upstream_php:9000^;
echo         include fastcgi_params^;
echo         fastcgi_param SCRIPT_FILENAME ^$document_root^$fastcgi_script_name;
echo         fastcgi_intercept_errors on;
ECHO.
echo         # Disable for development to ensure we always get the full response for debugging
echo         # fastcgi_cache fastcgi_cache;
echo         # fastcgi_cache_valid 200 302 10m;
echo         # fastcgi_cache_valid 404 1m;
echo.
echo         # or using shorten cache TTL to 10 seconds for development
echo         # and production-like caching behavior without long waits
echo         fastcgi_cache_valid 200 302 10s;   
echo         fastcgi_cache_valid 404 1s;
echo.   
echo         # Angie key to store and look up cached PHP responses 
echo         # Re-enable for production-like
echo         #fastcgi_cache_key "$scheme$request_method$host$request_uri";
echo.
echo         # Required for custom dashboard Cache API HIT/MISS/BYPASS
echo         add_header X-FastCGI-Cache $upstream_cache_status always;
echo.
echo         add_header X-FastCGI-Cache $upstream_cache_status always;
echo     }
echo.
echo     # Protect error pages
echo     location ~ ^/error-pages/.*\.php$ {
echo        root /www/!FULL_DOMAIN!;
echo        internal;
echo        fastcgi_pass php:9000;
echo        include fastcgi_params;
echo        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
echo     }
echo.
echo     # Logging
echo     access_log /var/log/angie/!FULL_DOMAIN!.access.log;
echo     error_log  /var/log/angie/!FULL_DOMAIN!.error.log warn;
echo }
) > "%CONFIG_FOLDER%\!FULL_DOMAIN!.conf"

:: DOCKER SYNC START
set "OV_FILE=%PROJECT_ROOT%\docker-compose.override.yml"
set "MASTER_COMPOSE=%PROJECT_ROOT%\docker-compose.yml"

docker info >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo         ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ 
    echo         Checking Docker status...
    echo         %ORA%[INFO]%RS% %TX%Docker detected. Syncing loop fix...%RS%
    echo.
    echo         ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    
    REM If file is missing, create YAML structure using PowerShell
    if not exist "%OV_FILE%" (
        powershell -NoProfile -Command "$yml = 'services:', '  php:', '    extra_hosts:', '      - \"host.docker.internal:host-gateway\"'; $yml | Out-File -FilePath '%OV_FILE%' -Encoding ascii"
    )

    REM Append the domain safely
    findstr /i "!FULL_DOMAIN!" "%OV_FILE%" >nul
    if !errorlevel! neq 0 (
        REM Using PowerShell to prevent trailing space "ghosts" break the YAML
        powershell -NoProfile -Command "Add-Content -Path '%OV_FILE%' -Value '      - \"!FULL_DOMAIN!:host-gateway\"' -Encoding ascii"
    )

    REM Execute with absolute paths
    docker compose -f "%MASTER_COMPOSE%" -f "%OV_FILE%" up -d --no-deps php
    
    if !errorlevel! neq 0 (
        call :ALERT "ERROR" "Docker failed to update. Check !OV_FILE! indentation."
    )
) else (
    call :ALERT "SKIP" "Docker not running."
)
:: DOCKER SYNC END

echo.
call :SUCCESS "%GRN% !FULL_DOMAIN! %RS% %TX%setup is complete.%RS%"
echo.
goto RESTART_PROMPT


:: ---------- ---------- ---------- DELETE DOMAIN

:REMOVEDOMAIN
:: 1. CALL THE SHARED SERVICE
call :LIST_TABLE "REMOVE LOCAL DOMAIN                                                     " "EDIT"
if %errorlevel% equ 0 goto MENU

set "TARGET_DOMAIN=!MAP_%RESULT_ID%!"

:: COMMENTED TO ALLOW 'RE-INSTALL' WHEN MISMATCH config/SSL files if the CA was changed
:: PROTECTION LOGIC - Moved up for immediate exit on protected domain
:: Prevent deletion of angie.local which would cause loss of access to the dashboard 
:: if /I "!TARGET_DOMAIN!"=="angie.local" (
::    echo.
::    echo  %RED%[PROTECTED]%RS% Access Denied! angie.local is a system domain.
::    pause & goto MENU
:: )

:: VALIDATION
if "!TARGET_DOMAIN!"=="" (
    echo. & echo   %RED%[!] Invalid ID selection.%RS%
    timeout /t 2 >nul & goto REMOVEDOMAIN
)

:: IDENTIFY DOMAIN TYPE
set "IS_AMP=FALSE"
if exist "%CONFIG_FOLDER%\!TARGET_DOMAIN!.conf" set "IS_AMP=TRUE"

:: CONFIRMATION - Dynamic based on type
cls
call :DRAW_HEADER "CONFIRM DELETION                                                        "
echo.
if "!IS_AMP!"=="TRUE" (
    CALL :ALERT "%RED%WARNING%RS%" "%TX%You are about to delete an AMP-MANAGED project%RS%"
    echo         %ORA%Target:%RS%%TX% !TARGET_DOMAIN! %RS%
    echo.
    echo         This action will permanently remove:
    echo.
    echo         %RED%- Deletes entry from HOSTS file
    echo         - Deletes Angie .conf file
    echo         - Deletes SSL certificates
    echo         - Removes from Docker Loopback%RS%
    echo.
    echo         %ORA%[NOTE]%RS% The project source folder will %TX%NOT%RS% be deleted.
    echo         Manual backup is recommended.
) else (
    echo         %ORA%TYPE: FOREIGN/OTHER DOMAIN%RS%
    echo         %RED%WARNING:%RS% You are about to remove: %TX%!TARGET_DOMAIN!%RS%
    echo.
    echo         - Deletes entry from HOSTS file ONLY
)
echo.

    <nul set /p "=%TX%        Type%RS% %ORA%'DELETE'%RS% %TX%to confirm (or Enter to cancel): %RS%"
    set "CONFIRM="
    set /p CONFIRM=""

if /I "!CONFIRM!" neq "DELETE" goto MENU

:: EXECUTION: HOSTS FILE (Common to both)
copy /y "%HOSTS%" "%HOSTS%.bak" >nul
powershell -NoProfile -Command "$c = Get-Content '%HOSTS%'; $c | Where-Object { $_ -notmatch '127\.0\.0\.1\s+!TARGET_DOMAIN!' } | Set-Content '%HOSTS%'"
ipconfig /flushdns >nul

echo.
call :SUCCESS "%ORA%Removed%RS%" "!TARGET_DOMAIN! has been deleted from hosts."

:: EXECUTION: AMP-SPECIFIC CLEANUP
if "!IS_AMP!"=="TRUE" (

    <nul set /p "=%TX%        Delete SSL and Config files? (y/n): %RS%"
    set "CLEAN="
    set /p CLEAN=""

    if /i "!CLEAN!"=="y" (
        del /f /q "%CERT_FOLDER%\!TARGET_DOMAIN!*.pem" 2>nul
        del /f /q "%CONFIG_FOLDER%\!TARGET_DOMAIN!.conf" 2>nul
        call :SUCCESS "%ORA%Deleted%RS%" "SSL and Config files for !TARGET_DOMAIN!"
    )

    :: DOCKER SYNC
    set "OV_FILE=%PROJECT_ROOT%\docker-compose.override.yml"
    set "TEMP_OV=%PROJECT_ROOT%\docker-compose.override.tmp"
    set "MASTER_COMPOSE=%PROJECT_ROOT%\docker-compose.yml"

    if exist "!OV_FILE!" (
        echo         %ORA%[INFO]%RS% Removing !TARGET_DOMAIN! from Docker bridge...
        powershell -NoProfile -Command "$c = Get-Content '!OV_FILE!'; $c | Where-Object { $_ -notmatch '!TARGET_DOMAIN!' } | Set-Content '!TEMP_OV!'"
        if exist "!TEMP_OV!" move /y "!TEMP_OV!" "!OV_FILE!" >nul
        
        docker info >nul 2>&1
        if !errorlevel! equ 0 (
            echo         %ORA%[INFO]%RS% Syncing PHP container...
            docker compose -f "!MASTER_COMPOSE!" -f "!OV_FILE!" up -d --no-deps php
        )
    )
)

echo.
call :SUCCESS "%GRN%Completed%RS%" "!TARGET_DOMAIN! removal process complete."
echo.
timeout /t 2 >nul
goto RESTART_PROMPT


:: ---------- ---------- RESTART SERVER

:RESTART_PROMPT
cls
call :DRAW_HEADER "Angie Server Update                                                     "
echo.
:: custom input field for confirmation
<nul set /p "=%TX%     Restart Angie? (y/n): %RS%"
set "RESTART="
set /p RESTART=""

if /i "!RESTART!"=="y" (
    pushd "%PROJECT_ROOT%"
    docker compose restart angie
    popd
)
echo.
echo        Returning to menu...
timeout /t 2 >nul
goto :DOMAIN_SCAN


:: ---------- ---------- ---------- BROWSER

:BROWSER
:: The "" is for the window title (required by 'start' logic)
start "" "%URL%"
goto :MENU


:: ---------- ---------- ---------- HELP

:HELP
cls
set "FAQ_ID=1"

:HELP_LOOP
cls
call :DRAW_HEADER "AMP-MANAGER KNOWLEDGE BASE                                              "
echo.
echo         [1]  %TX%Getting Started (Angie.local)%RS%    [4]  %TX%SSL ^& Certificates%RS%
echo         [2]  %TX%Setup .local Domains%RS%             [5]  %TX%Database Settings%RS%
echo         [3]  %TX%Troubleshooting Docker%RS%           [M]  %TX%Back to Main Menu%RS%
echo        ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
echo.

if "!FAQ_ID!"=="1" (
    echo        %ORA%TOPIC: Getting Started%RS%
    echo.
    echo        %TX%Angie.local is your control center. It serves to display domains
    echo        with SSL certificates, and health-check dashboard. If this isn't
    echo        loading check Docker is running and the container "angie" is 'Up'%RS%
)
if "!FAQ_ID!"=="2" (
    echo        %ORA%TOPIC: Setup .local Domains%RS%
    echo.
    echo        %TX%1. Add your project to the '\www\project.local\' folder.
    echo        2. Use AMP-MANAGER to create Angie config and SSL certificate.
    echo        3. Ensure your .conf file matches the domain name.%RS%
)
if "!FAQ_ID!"=="3" (
    echo        %ORA%TOPIC: Troubleshooting Docker%RS%
    echo.
    echo        %TX%1. Port 80/443 Conflict: Close Skype, IIS, or other web servers.
    echo        2. Container Crash: Run 'docker logs angie' to find syntax errors.%RS%
)
if "!FAQ_ID!"=="4" (
    echo        %ORA%TOPIC: SSL ^& Certificates%RS%
    echo.
    echo        %TX%We use a local Root CA. If browsers show a red warning:
    echo        For domain-specific issues, re-issuing the cert usually helps.
    echo        Run AMP-MANAGER option 'Remove Domain', to delete .conf and .pem
    echo        Then 'New Domain' to generate a new config and SSL certificate.%RS%
)
if "!FAQ_ID!"=="5" (
    echo        %ORA%TOPIC: Database Settings%RS%
    echo.
    echo        %TX%Default MariaDB host is 'db'. Connection port: 3306
    echo        Admin: root ^| Pass: rootpass123 ^| Database: ampdb
    echo        User: ampuser ^| Pass: ampass456 ^| Database: ampdb%RS% 
)

echo.
echo        ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
echo.

:: custom input for faq topics
<nul set /p "=%TX%        Enter Topic # or [M]%RS%: "

:: clear non-numeric to prevent errors
set /p "H_SELECT="
:: Handle Exit first
if /I "!H_SELECT!"=="M" goto MENU

:: Handle Numbers safely clearing non-numeric noise
for /L %%i in (1,1,5) do (
    if "!H_SELECT!"=="%%i" (
        set "FAQ_ID=%%i"
        goto HELP_LOOP
    )
)
:: stay on help section
goto HELP_LOOP


:: ---------- ---------- ---------- DOCKER

:DOCKERUN
cls
call :DRAW_HEADER "Docker Stack Management                                                 "
echo.
echo        %TX%[SYSTEM] Analyzing Container States...%RS%

:: Engine Check
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    call :ALERT "DOCKER ENGINE OFF" "Please launch Docker Desktop and wait for it to start."
    echo.
    pause
    goto MENU
)

:: Identify Current State
set "D_STATE=%RED%STOPPED%RS%"
docker ps --filter "status=running" | findstr "angie" >nul
if %errorlevel% equ 0 set "D_STATE=%GRN%ACTIVE%RS%"

echo.
echo        Current Status: [ !D_STATE! ]
echo.
echo        [U] Start / Up Stack
echo        [R] Restart Stack
echo        [S] Stop Stack 
echo        [M] Back to Menu
echo.
echo        ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
echo.
:: Custom Input Handling
set "D_ACTION="
<nul set /p "=%TX%       Select Action [U, R, S] or [M]: %RS%"
set /p D_ACTION=""

if /I "!D_ACTION!"=="M" goto MENU
if "!D_ACTION!"=="" goto MENU

:: Action Branching
if /I "!D_ACTION!"=="U" goto :DOCKER_UP
if /I "!D_ACTION!"=="R" goto :DOCKER_RESTART
if /I "!D_ACTION!"=="S" goto :DOCKER_STOP

:: Fallback for invalid keys
echo.
echo    %RED%[!] Invalid selection.%RS%
timeout /t 2 >nul
goto DOCKERUN

:DOCKER_UP
echo.
echo    %ORA%[ACTION]%RS% Starting services (Angie, DB, PHP)...
docker-compose up -d
goto DOCKER_DONE

:DOCKER_RESTART
echo.
echo    %ORA%[ACTION]%RS% Restarting containers...
docker-compose restart
goto DOCKER_DONE

:DOCKER_STOP
echo.
echo    %RED%[ACTION]%RS% Stopping containers...
docker-compose stop
goto DOCKER_DONE

:DOCKER_DONE
:: Completion Wrap-up
echo.
call :SUCCESS "DOCKER" "Task requested has been executed."
echo.
echo    %TX%Returning to menu in 3s...%RS%
timeout /t 3 >nul
goto MENU


:: ---------- ---------- ---------- EXIT

:EXIT
cls
call :ALERT "Exiting AMP-Manager..." "%TX%Go make something awesome. Have Fun ^_^/ %RS%"

:: remove the single instance lock file to avoid trash
if exist "%TEMP%\amp_manager.lock" del /f /q "%TEMP%\amp_manager.lock" >nul 2>&1

:: timeout for user to read the status
timeout /t 5 >nul
exit /b


:: ---------- ---------- ---------- UI SUBROUTINES

:: ---------- ---------- UI HEADER

:LIST_TABLE
:: %1 = Title, %2 = Filter Mode
set "TOTAL_COUNT=0"
for %%d in (!DOMAINS!) do (
    set "VALID=TRUE"
    if "%~2"=="AMP_ONLY" ( if not exist "%CONFIG_FOLDER%\%%d.conf" set "VALID=FALSE" )
    
    if "!VALID!"=="TRUE" (
        set /a TOTAL_COUNT+=1
        set "MAP_!TOTAL_COUNT!=%%d"
    )
)

set "PAGE_SIZE=10"
set "CUR_PAGE=1"

:RENDER_PAGE
set /a "START_IDX=((CUR_PAGE-1) * PAGE_SIZE) + 1"
set /a "END_IDX=START_IDX + PAGE_SIZE - 1"
if !END_IDX! gtr !TOTAL_COUNT! set "END_IDX=!TOTAL_COUNT!"

cls
call :DRAW_HEADER "%~1"
echo.
echo    ID    STATUS    DOMAIN                           CONFIG    SSL
echo    ÄÄÄÄ  ÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄ
echo.

for /L %%i in (!START_IDX!, 1, !END_IDX!) do (
    set "DOMAIN=!MAP_%%i!"
    
    :: 1. DATA CHECKS
    set "HAS_CONF=%RED%MISSING%RS%"
    set "HAS_PEM=%RED%MISSING%RS%"
    set "ROW_STAT=%TX%FOREIGN %RS%"

    if exist "%CONFIG_FOLDER%\!DOMAIN!.conf" (
        set "HAS_CONF=%GRN%FOUND   %RS%"
        set "ROW_STAT=%GRN%ACTIVE  %RS%"
        if exist "%CERT_FOLDER%\!DOMAIN!.pem" set "HAS_PEM=%GRN%FOUND   %RS%"
    )
    
    :: 2. SYSTEM OVERRIDE
    if /I "!DOMAIN!"=="angie.local" set "ROW_STAT=%TX%SYSTEM  %RS%"

    :: 3. PADDING FOR THE TABLE LOOK
    set "ID_PAD= %%i" & if %%i geq 10 set "ID_PAD=%%i"
    set "NAME_PAD=!DOMAIN!                               " & set "D_NAME=!NAME_PAD:~0,31!"

    :: 4. THE OUTPUT
    echo    [!ID_PAD!]  !ROW_STAT!  !D_NAME!  !HAS_CONF!  !HAS_PEM!
)



:: PAGINATION FOOTER
echo.
echo    ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
set /a "TOTAL_PAGES=(TOTAL_COUNT + PAGE_SIZE - 1) / PAGE_SIZE"

:: FOOTER STATISTICS
:: Only display if there are entries to show
echo.
if !TOTAL_COUNT! gtr 0 (
    echo    Page !CUR_PAGE! of !TOTAL_PAGES! (!TOTAL_COUNT! entries^)
) else (
    echo    %ORA%[!] No entries found in this view.%RS%
)
echo.
echo.

:: CONDITIONAL INTERACTION
set "ALLOW_SELECT=FALSE"
if "%~2"=="AMP_ONLY" set "ALLOW_SELECT=TRUE"
if "%~2"=="EDIT"     set "ALLOW_SELECT=TRUE"

if "!ALLOW_SELECT!"=="TRUE" (
    echo    [N] Next Page   [P] Previous   [M] Menu   [ID] Select Item
    echo.
    set "CHOICE="
    <nul set /p "=%TX%   Action (Select ID): %RS%"
    set /p CHOICE=""
) else (
    echo    [N] Next Page   [P] Previous   [M] Return to Menu
    echo.
    set "CHOICE="
    <nul set /p "=%TX%   Action: %RS%"
    set /p CHOICE=""
)

:: NAVIGATION LOGIC (N/P/M)
if /I "!CHOICE!"=="M" exit /b 0
if /I "!CHOICE!"=="N" ( if !CUR_PAGE! lss !TOTAL_PAGES! set /a CUR_PAGE+=1 & goto RENDER_PAGE )
if /I "!CHOICE!"=="P" ( if !CUR_PAGE! gtr 1 set /a CUR_PAGE-=1 & goto RENDER_PAGE )

:: VALIDATION
:: Block selection ONLY if we list "ALL" mode
if "!ALLOW_SELECT!"=="FALSE" (
    echo !CHOICE!| findstr /r "^[0-9][0-9]*$" >nul && (
        echo. & echo   %ORA%[!] Selection disabled in System View.%RS%
        timeout /t 2 >nul & goto RENDER_PAGE
    )
)

set "RESULT_ID=!CHOICE!"
exit /b 1

:: ---------- ---------- DRAW HEADER

:DRAW_HEADER
cls
echo  ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
echo  ³²²²²²²²²²²²²²²²²²²²²²²²²²²  A M P - M A N A G E R ²²²²²²²²²²²²²²²²²²²²²²²²²²³
echo  ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
echo  ³°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°³
echo  ³  %TX% %~1 %RS%³
echo  ³°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°³
echo  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
exit /b


:: ---------- ---------- ALERT BOX

:ALERT
echo. 
echo         %RED%ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
echo         ³²²²²²²²²²²²²²²²²²²²²²²²  W A R N I N G  ²²²²²²²²²²²²²²²²²²²²²²²³
echo         ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ%RS%
echo.
echo.
echo         %~1
if not "%~2"=="" (
  echo         %~2
)
echo.
exit /b


:: ---------- ---------- SUCCESS BOX

:SUCCESS
echo. 
echo         %GRN%ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
echo         ³²²²²²²²²²²²²²²²²²²²²²²²  S U C C E S S  ²²²²²²²²²²²²²²²²²²²²²²²³
echo         ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ%RS%
echo.
echo.
echo         %~1
if not "%~2"=="" (
  echo         %~2
)
echo.
exit /b


:: ---------- ---------- INFO BOX

:INFO
echo.
echo         ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
echo         ³        %TX%Please refer to the HELP menu for instructions.%RS%        ³
echo         ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
echo         ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
echo.  
exit /b