@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul 2>&1
title DeadMoon Universal API Verify Script - Powered by Ikaleio/lm-detector

rem ============================================================================
rem  DEADMOON UNIVERSAL API VERIFY SCRIPT (v2.2)
rem  Powered by Ikaleio/lm-detector (https://github.com/Ikaleio/lm-detector)
rem  Runtime powered by Oven Bun (https://github.com/oven-sh/bun)
rem ============================================================================

rem Initialize ANSI Escape Character for Windows 10/11 Terminal Colors
for /f "delims=#" %%E in ('"prompt #$E# & for %%e in (1) do rem"') do set "ESC=%%E"
set "C_RESET=%ESC%[0m"
set "C_BOLD=%ESC%[1m"
set "C_DIM=%ESC%[2m"
set "C_RED=%ESC%[91m"
set "C_GREEN=%ESC%[92m"
set "C_YELLOW=%ESC%[93m"
set "C_BLUE=%ESC%[94m"
set "C_PURPLE=%ESC%[95m"
set "C_CYAN=%ESC%[96m"
set "C_WHITE=%ESC%[97m"
set "C_GRAY=%ESC%[90m"

rem ============================================================================
rem Force working directory and all dependency/cache paths into this script's folder
rem ============================================================================
cd /d "%~dp0"
set "WORK_DIR=%~dp0"
set "DEPS_DIR=%~dp0lm_detector_deps"
set "BUN_DIR=%DEPS_DIR%\bun-windows-x64"
set "BUN_EXE=%BUN_DIR%\bun.exe"
set "BUN_INSTALL=%DEPS_DIR%\bun_home"
set "BUN_INSTALL_CACHE_DIR=%DEPS_DIR%\bun_cache"
set "TEMP=%DEPS_DIR%\tmp"
set "TMP=%DEPS_DIR%\tmp"
set "HELPER_MJS=%DEPS_DIR%\provider_helper.mjs"
set "SELECTED_MODELS_FILE=%DEPS_DIR%\selected_models.txt"
set "SETTINGS_FILE=%DEPS_DIR%\saved_settings.cmd"
set "KEY_FILE=%DEPS_DIR%\saved_apikey.txt"

if not exist "%DEPS_DIR%" mkdir "%DEPS_DIR%"
if not exist "%BUN_INSTALL%" mkdir "%BUN_INSTALL%"
if not exist "%BUN_INSTALL_CACHE_DIR%" mkdir "%BUN_INSTALL_CACHE_DIR%"
if not exist "%TEMP%" mkdir "%TEMP%"

rem ============================================================================
rem Default Relay-Safe Session Settings (OpenRouter + Smart Mode Default)
rem ============================================================================
set "BASE_URL=https://openrouter.ai/api/v1"
set "HAS_SAVED_URL=NO"
set "API_KEY="
set "KEY_STORAGE=NONE"

set "SMART_MODE=ON"
set "ANTHROPIC_MODE=OFF"
set "API_PROTO=cc"
set "PROTO_DESC=OpenAI Chat [-a cc]"

set "FORCE_SEQUENTIAL=ON"
set "PARALLEL_COUNT=1"

set "NO_STREAM_MODE=OFF"
set "TOKENIZER_MODE=OFF"
set "STRICT_MODE=OFF"
set "SAVE_JSON=OFF"
set "UI_ANIMATIONS=ON"

set "SAMPLE_COUNT=3"
set "ROUND_COUNT=1"
set "REQ_TIMEOUT=180"
set "EFFORT_LEVEL="

if exist "%SETTINGS_FILE%" (
    call "%SETTINGS_FILE%"
    set "HAS_SAVED_URL=YES"
)

if exist "%KEY_FILE%" (
    set /p API_KEY=<"%KEY_FILE%"
    if not "!API_KEY!" equ "" set "KEY_STORAGE=SAVED ON DISK"
)

rem ============================================================================
rem Step 1: Initialize Local Portable Dependencies & Play Animated Boot Splash
rem ============================================================================
call :ensure_dependencies
if errorlevel 1 (
    echo.
    echo %C_RED%[ERROR] Failed to initialize local dependencies in %DEPS_DIR%%C_RESET%
    pause
    exit /b 1
)

call :boot_splash

rem ============================================================================
rem Step 2: Initial Endpoint & API Key Setup (Skipped if Already Saved!)
rem ============================================================================
if /i "%HAS_SAVED_URL%" equ "NO" call :configure_endpoint_first_time
if "%API_KEY%" equ "" call :configure_apikey_initial

rem ============================================================================
rem Step 3: Interactive Main Menu
rem ============================================================================

:main_menu
set "PROTO_DESC=OpenAI Chat [-a cc]"
if /i "%API_PROTO%" equ "message" set "PROTO_DESC=Anthropic Messages [-a message]"
if /i "%API_PROTO%" equ "responses" set "PROTO_DESC=OpenAI Responses [-a responses]"

set "PARALLEL_COUNT=3"
if /i "%FORCE_SEQUENTIAL%" equ "ON" set "PARALLEL_COUNT=1"

set "NS_FLAG="
if /i "%NO_STREAM_MODE%" equ "ON" set "NS_FLAG=-ns"
set "TOK_FLAG="
if /i "%TOKENIZER_MODE%" equ "ON" set "TOK_FLAG=--tokenizer"
set "STRICT_FLAG="
if /i "%STRICT_MODE%" equ "ON" set "STRICT_FLAG=-s"
set "EFFORT_FLAG="
if not "%EFFORT_LEVEL%" equ "" set "EFFORT_FLAG=-e %EFFORT_LEVEL%"

set "KEY_DISP=%C_RED%[NOT SET - Press K to set]%C_RESET%"
if not "%API_KEY%" equ "" set "KEY_DISP=%C_GREEN%!API_KEY:~0,8!...!API_KEY:~-4! [%KEY_STORAGE% - Press V to reveal]%C_RESET%"

set "BADGE_SMART=%C_GRAY%[OFF]%C_RESET%"
set "SMART_DESC=Manual Mode active - using toggles 6-9/S below"
set "MODE_DISP=%C_YELLOW%[MANUAL MODE]%C_RESET% %C_CYAN%-a %API_PROTO% -p %PARALLEL_COUNT% --count %SAMPLE_COUNT% -n %ROUND_COUNT% --timeout %REQ_TIMEOUT% %NS_FLAG% %TOK_FLAG% %STRICT_FLAG% %EFFORT_FLAG%%C_RESET%"
if /i "%SMART_MODE%" equ "ON" set "BADGE_SMART=%C_GREEN%[ON ]%C_RESET%"
if /i "%SMART_MODE%" equ "ON" set "SMART_DESC=Auto-tunes protocol ^& self-heals on stream/rate errors"
if /i "%SMART_MODE%" equ "ON" set "MODE_DISP=%C_GREEN%[SMART AUTO-CONFIG]%C_RESET% %C_CYAN%[Auto-detects optimal flags ^& retries]%C_RESET%"

set "BADGE_ANTH=%C_GRAY%[OFF]%C_RESET%"
if /i "%ANTHROPIC_MODE%" equ "ON" set "BADGE_ANTH=%C_GREEN%[ON ]%C_RESET%"
set "BADGE_SEQ=%C_GRAY%[OFF]%C_RESET%"
if /i "%FORCE_SEQUENTIAL%" equ "ON" set "BADGE_SEQ=%C_GREEN%[ON ]%C_RESET%"
set "BADGE_NS=%C_GRAY%[OFF]%C_RESET%"
if /i "%NO_STREAM_MODE%" equ "ON" set "BADGE_NS=%C_GREEN%[ON ]%C_RESET%"
set "BADGE_TOK=%C_GRAY%[OFF]%C_RESET%"
if /i "%TOKENIZER_MODE%" equ "ON" set "BADGE_TOK=%C_GREEN%[ON ]%C_RESET%"
set "BADGE_STR=%C_GRAY%[OFF]%C_RESET%"
if /i "%STRICT_MODE%" equ "ON" set "BADGE_STR=%C_GREEN%[ON ]%C_RESET%"
set "BADGE_JSN=%C_GRAY%[OFF]%C_RESET%"
if /i "%SAVE_JSON%" equ "ON" set "BADGE_JSN=%C_GREEN%[ON ]%C_RESET%"
set "BADGE_ANIM=%C_GRAY%[OFF]%C_RESET%"
if /i "%UI_ANIMATIONS%" equ "ON" set "BADGE_ANIM=%C_GREEN%[ON ]%C_RESET%"

cls
call :draw_moon_header
echo %C_PURPLE%============================================================================%C_RESET%
echo   %C_BOLD%%C_WHITE%DEADMOON UNIVERSAL API VERIFY SCRIPT%C_RESET%   %C_CYAN%[Powered by Ikaleio/lm-detector]%C_RESET%
echo %C_PURPLE%============================================================================%C_RESET%
echo   %C_GRAY%Local Folder      :%C_RESET% %DEPS_DIR%
echo   %C_GRAY%Current Base URL  :%C_RESET% %C_YELLOW%%BASE_URL%%C_RESET%
echo   %C_GRAY%Current API Key   :%C_RESET% %KEY_DISP%
echo   %C_GRAY%Active Mode       :%C_RESET% %MODE_DISP%
echo %C_PURPLE%============================================================================%C_RESET%
echo   %C_BOLD%%C_YELLOW%VERIFICATION ^& DISCOVERY ACTIONS%C_RESET%
echo   %C_CYAN%[1]%C_RESET% Verify a Single Model %C_GRAY%[type model ID manually]%C_RESET%
echo   %C_CYAN%[2]%C_RESET% Batch-Verify Multiple Models %C_GRAY%[enter comma-separated model IDs]%C_RESET%
echo   %C_CYAN%[3]%C_RESET% Auto-Detect Models from Provider %C_GRAY%[fetch full /models catalog ^& search]%C_RESET%
echo   %C_CYAN%[4]%C_RESET% Quick Diagnostic Ping %C_GRAY%[1-request test across OpenAI ^& Anthropic modes]%C_RESET%
echo.
echo   %C_BOLD%%C_YELLOW%RELAY COMPATIBILITY ^& PROTOCOL TOGGLES%C_RESET% %C_GRAY%[Toggling 6-9/S switches to Manual]%C_RESET%
echo   %C_GREEN%[M]%C_RESET% Smart Auto-Config Mode [Recommended] : %BADGE_SMART%  %C_GRAY%%SMART_DESC%%C_RESET%
echo   %C_PURPLE%[6]%C_RESET% Anthropic Messages Mode [-a message] : %BADGE_ANTH%  %C_GRAY%Manual Protocol: %PROTO_DESC%%C_RESET%
echo   %C_PURPLE%[7]%C_RESET% Force Sequential Requests [-p 1]     : %BADGE_SEQ%  %C_GRAY%Parallelism: -p %PARALLEL_COUNT%%C_RESET%
echo   %C_PURPLE%[8]%C_RESET% Non-Streaming JSON Mode [-ns]        : %BADGE_NS%  %C_GRAY%Fixes dropped SSE streams%C_RESET%
echo   %C_PURPLE%[9]%C_RESET% Upstream Tokenizer Probe             : %BADGE_TOK%  %C_GRAY%Sends ~12 extra requests%C_RESET%
echo   %C_PURPLE%[S]%C_RESET% Strict Scoring Mode [-s]             : %BADGE_STR%  %C_GRAY%Requires 3 full samples%C_RESET%
echo   %C_PURPLE%[J]%C_RESET% Save JSON Verification Report        : %BADGE_JSN%  %C_GRAY%Exports report_*.json%C_RESET%
echo.
echo   %C_BOLD%%C_YELLOW%CONFIGURATION ^& MAINTENANCE%C_RESET%
echo   %C_BLUE%[5]%C_RESET% Change Base URL / Provider           %C_BLUE%[K]%C_RESET% Set / Save / Clear API Key
echo   %C_BLUE%[V]%C_RESET% View / Reveal Saved API Key          %C_BLUE%[R]%C_RESET% Adjust Rounds / Samples / Effort
echo   %C_BLUE%[I]%C_RESET% Analyze Saved JSON Report Offline    %C_BLUE%[A]%C_RESET% UI Animations : %BADGE_ANIM%
echo   %C_BLUE%[U]%C_RESET% Update lm-detector [lmfpd@latest]    %C_RED%[0]%C_RESET% Exit DeadMoon Verifier
echo %C_PURPLE%============================================================================%C_RESET%
set "MENU_CHOICE="
set /p "MENU_CHOICE=%C_BOLD%%C_CYAN%Select an option: %C_RESET%"

if /i "%MENU_CHOICE%" equ "1" goto :test_single
if /i "%MENU_CHOICE%" equ "2" goto :test_batch_custom
if /i "%MENU_CHOICE%" equ "3" goto :auto_detect_models
if /i "%MENU_CHOICE%" equ "4" goto :diagnostic_ping
if /i "%MENU_CHOICE%" equ "5" goto :menu_change_url
if /i "%MENU_CHOICE%" equ "M" goto :toggle_smart
if /i "%MENU_CHOICE%" equ "6" goto :toggle_protocol
if /i "%MENU_CHOICE%" equ "7" goto :toggle_sequential
if /i "%MENU_CHOICE%" equ "8" goto :toggle_nostream
if /i "%MENU_CHOICE%" equ "9" goto :toggle_tokenizer
if /i "%MENU_CHOICE%" equ "S" goto :toggle_strict
if /i "%MENU_CHOICE%" equ "J" goto :toggle_json
if /i "%MENU_CHOICE%" equ "A" goto :toggle_anim
if /i "%MENU_CHOICE%" equ "K" goto :menu_change_key
if /i "%MENU_CHOICE%" equ "V" goto :view_apikey
if /i "%MENU_CHOICE%" equ "R" goto :configure_tuning
if /i "%MENU_CHOICE%" equ "I" goto :analyze_offline
if /i "%MENU_CHOICE%" equ "U" goto :update_lmfpd
if /i "%MENU_CHOICE%" equ "0" goto :exit_script
goto :main_menu

rem ============================================================================
rem Subroutine: DeadMoon Static Header & Animated Splash / Transitions
rem ============================================================================

:draw_moon_header
echo       %C_CYAN%.       +%C_RESET%        %C_BLUE%.================.%C_RESET%        %C_CYAN%*        .%C_RESET%
echo    %C_CYAN%+    %C_YELLOW%d~~b%C_RESET%      %C_BLUE%.==='  %C_YELLOW%.------------.%C_BLUE%  '===.%C_RESET%      %C_YELLOW%d~~b%C_RESET%     %C_CYAN%.%C_RESET%
echo       %C_CYAN%. %C_YELLOW%d  b%C_RESET%    %C_BLUE%/   %C_YELLOW%.-'    .      o    '-.%C_BLUE%   \%C_RESET%     %C_YELLOW%d  b%C_RESET%   %C_CYAN%+%C_RESET%
echo                %C_BLUE%/  %C_YELLOW%.'   o       .      .   '.%C_BLUE%  \%C_RESET%        %C_CYAN%.%C_RESET%
echo     %C_CYAN%*%C_RESET%         %C_BLUE%[===]%C_YELLOW%  .    %C_WHITE%/        \%C_YELLOW%    .  %C_BLUE%[===]%C_RESET%   %C_CYAN%+       *%C_RESET%
echo          %C_BLUE%.--- [===]%C_YELLOW%     %C_WHITE%\____/    \____/%C_YELLOW%   %C_BLUE%[===] ---.%C_RESET%
echo         %C_BLUE%(     [===]%C_YELLOW%   o      %C_WHITE%.----.%C_YELLOW%      O %C_BLUE%[===]     )%C_RESET%   %C_YELLOW%d~b%C_RESET%
echo     %C_CYAN%.%C_RESET%    %C_BLUE%'--- [===]%C_YELLOW%    .    %C_WHITE%/      \%C_YELLOW%   .   %C_BLUE%[===] ---'%C_RESET%    %C_YELLOW%d b%C_RESET%
echo        %C_CYAN%+%C_RESET%       %C_BLUE%\  %C_YELLOW%'.     .            o  .'%C_BLUE%  /%C_RESET%       %C_CYAN%*%C_RESET%
echo     %C_CYAN%.%C_RESET%           %C_BLUE%'.  %C_YELLOW%'-.    o   .   .  .-'%C_BLUE%  .'%C_RESET%     %C_CYAN%.       +%C_RESET%
echo          %C_CYAN%*%C_RESET%        %C_BLUE%'===='%C_YELLOW%--------------%C_BLUE%'===='%C_RESET%          %C_CYAN%.%C_RESET%
exit /b 0

:boot_splash
if /i "%UI_ANIMATIONS%" equ "OFF" exit /b 0
if exist "%BUN_EXE%" if exist "%HELPER_MJS%" (
    "%BUN_EXE%" run "%HELPER_MJS%" boot
    exit /b 0
)
exit /b 0

:animate_action
if /i "%UI_ANIMATIONS%" equ "OFF" exit /b 0
if exist "%BUN_EXE%" if exist "%HELPER_MJS%" (
    "%BUN_EXE%" run "%HELPER_MJS%" pulse "%~1"
    exit /b 0
)
echo.
echo   %C_PURPLE%[ %C_YELLOW%o%C_PURPLE% ]%C_RESET% %C_CYAN%~~~^>%C_RESET% %C_WHITE%%~1%C_RESET%
exit /b 0

:animate_toggle
if /i "%UI_ANIMATIONS%" equ "OFF" exit /b 0
if exist "%BUN_EXE%" if exist "%HELPER_MJS%" (
    "%BUN_EXE%" run "%HELPER_MJS%" toggle "%~1" "%~2"
    exit /b 0
)
exit /b 0

rem ============================================================================
rem Option 1: Verify a Single Model
rem ============================================================================

:test_single
call :animate_action "Opening Single-Model Fingerprint Scanner..."
echo.
echo %C_GRAY%Examples: anthropic/claude-opus-5.5, anthropic/claude-opus-4.6, openai/gpt-4.1, deepseek/deepseek-r1%C_RESET%
set "TARGET_MODEL="
set /p "TARGET_MODEL=%C_CYAN%Enter exact model ID to verify [or press Enter to cancel]: %C_RESET%"
if "%TARGET_MODEL%" equ "" goto :main_menu

call :run_detector "%TARGET_MODEL%"
echo.
pause
goto :main_menu

rem ============================================================================
rem Option 2: Batch-Verify Custom List of Models
rem ============================================================================

:test_batch_custom
call :animate_action "Opening Multi-Model Batch Queue..."
echo.
echo %C_GRAY%Enter model names separated by commas or spaces.%C_RESET%
echo %C_GRAY%Example: anthropic/claude-opus-5.5, openai/gpt-4.1, deepseek/deepseek-r1%C_RESET%
set "MODEL_LIST="
set /p "MODEL_LIST=%C_CYAN%Models to verify: %C_RESET%"
if "%MODEL_LIST%" equ "" goto :main_menu

for %%M in (%MODEL_LIST%) do (
    call :run_detector "%%~M"
)
echo.
echo %C_GREEN%[DONE] Finished batch verification.%C_RESET%
pause
goto :main_menu

rem ============================================================================
rem Option 3: Auto-Detect Models from Provider & Interactive Picker
rem ============================================================================

:auto_detect_models
call :animate_action "Scanning Provider Model Catalog [/models]..."
if "%API_KEY%" equ "" (
    echo.
    echo %C_YELLOW%[WARN] API Key is not set. Please enter your API Key first.%C_RESET%
    call :configure_apikey_initial
)
if exist "%SELECTED_MODELS_FILE%" del /q "%SELECTED_MODELS_FILE%" >nul 2>&1

echo.
"%BUN_EXE%" run "%HELPER_MJS%" models "%BASE_URL%" "%API_KEY%" "%SELECTED_MODELS_FILE%"
if not exist "%SELECTED_MODELS_FILE%" (
    echo.
    pause
    goto :main_menu
)

echo.
echo %C_PURPLE%============================================================================%C_RESET%
echo   %C_BOLD%%C_YELLOW%Starting Verification for Selected Provider Model[s]...%C_RESET%
echo %C_PURPLE%============================================================================%C_RESET%
for /f "usebackq tokens=* delims=" %%M in ("%SELECTED_MODELS_FILE%") do (
    if not "%%~M" equ "" (
        call :run_detector "%%~M"
    )
)
echo.
echo %C_GREEN%[DONE] Completed verification of selected models.%C_RESET%
pause
goto :main_menu

rem ============================================================================
rem Option 4: Quick 1-Request Diagnostic Ping (Tests OpenAI & Anthropic Routes)
rem ============================================================================

:diagnostic_ping
call :animate_action "Initializing Dual-Protocol Diagnostic Ping..."
if "%API_KEY%" equ "" call :configure_apikey_initial
echo.
set "PING_MODEL="
set /p "PING_MODEL=%C_CYAN%Enter model ID to ping-test [default: openai/gpt-4o-mini]: %C_RESET%"
if "%PING_MODEL%" equ "" set "PING_MODEL=openai/gpt-4o-mini"

echo.
"%BUN_EXE%" run "%HELPER_MJS%" ping "%BASE_URL%" "%API_KEY%" "%PING_MODEL%"
echo.
pause
goto :main_menu

rem ============================================================================
rem Option V & K: View / Reveal API Key & API Key Manager
rem ============================================================================

:view_apikey
call :animate_action "Opening Local API Key Viewer..."
echo.
"%BUN_EXE%" run "%HELPER_MJS%" view-key "%BASE_URL%" "%API_KEY%" "%KEY_STORAGE%" "%KEY_FILE%"
echo.
pause
goto :main_menu

:menu_change_key
call :animate_action "Opening API Key Vault Manager..."
echo.
echo %C_PURPLE%----------------------------------------------------------------------------%C_RESET%
echo   %C_BOLD%%C_YELLOW%API Key Vault ^& Storage Manager%C_RESET%
echo %C_PURPLE%----------------------------------------------------------------------------%C_RESET%
echo   %C_GRAY%Active Base URL :%C_RESET% %C_CYAN%%BASE_URL%%C_RESET%
echo   %C_GRAY%Storage Status  :%C_RESET% %C_GREEN%%KEY_STORAGE%%C_RESET%
echo   %C_GRAY%Local Key File  :%C_RESET% %KEY_FILE%
echo.
echo   %C_CYAN%[1]%C_RESET% Enter ^& Save New API Key Locally %C_GRAY%[Auto-loads on every launch]%C_RESET%
echo   %C_CYAN%[2]%C_RESET% Enter Session-Only API Key %C_GRAY%[Kept in RAM only, not saved to disk]%C_RESET%
echo   %C_CYAN%[3]%C_RESET% Save Current Session API Key to Disk
echo   %C_CYAN%[4]%C_RESET% Delete / Wipe Saved API Key from Disk
echo   %C_CYAN%[5]%C_RESET% View / Reveal Full Current API Key
echo   %C_CYAN%[6]%C_RESET% Cancel / Return to Main Menu
echo.
set "KEY_OPT="
set /p "KEY_OPT=%C_BOLD%%C_CYAN%Choose [1-6, default=1]: %C_RESET%"
if "%KEY_OPT%" equ "" set "KEY_OPT=1"

if "%KEY_OPT%" equ "1" (
    set "NEW_KEY="
    set /p "NEW_KEY=%C_YELLOW%Paste API Key to save locally: %C_RESET%"
    if not "!NEW_KEY!" equ "" (
        set "API_KEY=!NEW_KEY!"
        "%BUN_EXE%" run "%HELPER_MJS%" save-key "%KEY_FILE%" "!API_KEY!"
        set "KEY_STORAGE=SAVED ON DISK"
    )
    goto :main_menu
)
if "%KEY_OPT%" equ "2" (
    set "NEW_KEY="
    set /p "NEW_KEY=%C_YELLOW%Paste Session-Only API Key: %C_RESET%"
    if not "!NEW_KEY!" equ "" (
        set "API_KEY=!NEW_KEY!"
        set "KEY_STORAGE=SESSION MEMORY"
        echo %C_GREEN%[OK] API Key loaded into session memory only.%C_RESET%
    )
    goto :main_menu
)
if "%KEY_OPT%" equ "3" (
    if "%API_KEY%" equ "" (
        echo %C_RED%[WARN] No API Key is currently loaded in session memory.%C_RESET%
        pause
        goto :main_menu
    )
    "%BUN_EXE%" run "%HELPER_MJS%" save-key "%KEY_FILE%" "%API_KEY%"
    set "KEY_STORAGE=SAVED ON DISK"
    pause
    goto :main_menu
)
if "%KEY_OPT%" equ "4" (
    if exist "%KEY_FILE%" del /q "%KEY_FILE%" >nul 2>&1
    set "API_KEY="
    set "KEY_STORAGE=NONE"
    echo %C_GREEN%[OK] Saved API Key wiped from disk and cleared from session.%C_RESET%
    pause
    goto :main_menu
)
if "%KEY_OPT%" equ "5" goto :view_apikey
goto :main_menu

:configure_apikey_initial
echo.
echo %C_PURPLE%----------------------------------------------------------------------------%C_RESET%
echo   %C_BOLD%%C_YELLOW%API Key Setup for %BASE_URL%%C_RESET%
echo %C_PURPLE%----------------------------------------------------------------------------%C_RESET%
set "NEW_KEY="
set /p "NEW_KEY=%C_CYAN%Paste your API Key [or press Enter to skip]: %C_RESET%"
if "%NEW_KEY%" equ "" exit /b 0
set "API_KEY=%NEW_KEY%"
set "KEY_STORAGE=SESSION MEMORY"

echo.
set "SAVE_KEY_ANS="
set /p "SAVE_KEY_ANS=%C_YELLOW%Save this API Key locally so you don't have to paste it next time? [Y/N, default=Y]: %C_RESET%"
if "%SAVE_KEY_ANS%" equ "" set "SAVE_KEY_ANS=Y"
if /i "%SAVE_KEY_ANS%" equ "Y" (
    "%BUN_EXE%" run "%HELPER_MJS%" save-key "%KEY_FILE%" "%API_KEY%"
    set "KEY_STORAGE=SAVED ON DISK"
)
exit /b 0

rem ============================================================================
rem Menu Wrapper for Base URL
rem ============================================================================

:menu_change_url
call :animate_action "Opening Endpoint Configuration..."
call :configure_endpoint_saved
goto :main_menu

rem ============================================================================
rem Toggles (Options M, 6, 7, 8, 9, S, J, A)
rem ============================================================================

:toggle_smart
if /i "%SMART_MODE%" equ "ON" (
    set "SMART_MODE=OFF"
) else (
    set "SMART_MODE=ON"
)
call :animate_toggle "Smart Auto-Config Mode" "%SMART_MODE%"
call :save_settings
goto :main_menu

:toggle_protocol
set "SMART_MODE=OFF"
if /i "%ANTHROPIC_MODE%" equ "OFF" (
    set "ANTHROPIC_MODE=ON"
    set "API_PROTO=message"
) else (
    set "ANTHROPIC_MODE=OFF"
    set "API_PROTO=cc"
)
call :animate_toggle "Manual Mode -> Anthropic Messages [-a message]" "%ANTHROPIC_MODE%"
call :save_settings
goto :main_menu

:toggle_sequential
set "SMART_MODE=OFF"
if /i "%FORCE_SEQUENTIAL%" equ "ON" (
    set "FORCE_SEQUENTIAL=OFF"
    set "PARALLEL_COUNT=3"
) else (
    set "FORCE_SEQUENTIAL=ON"
    set "PARALLEL_COUNT=1"
)
call :animate_toggle "Manual Mode -> Force Sequential [-p 1]" "%FORCE_SEQUENTIAL%"
call :save_settings
goto :main_menu

:toggle_nostream
set "SMART_MODE=OFF"
if /i "%NO_STREAM_MODE%" equ "OFF" (
    set "NO_STREAM_MODE=ON"
) else (
    set "NO_STREAM_MODE=OFF"
)
call :animate_toggle "Manual Mode -> Non-Streaming JSON [-ns]" "%NO_STREAM_MODE%"
call :save_settings
goto :main_menu

:toggle_tokenizer
set "SMART_MODE=OFF"
if /i "%TOKENIZER_MODE%" equ "OFF" (
    set "TOKENIZER_MODE=ON"
) else (
    set "TOKENIZER_MODE=OFF"
)
call :animate_toggle "Manual Mode -> Upstream Tokenizer Probe" "%TOKENIZER_MODE%"
call :save_settings
goto :main_menu

:toggle_strict
set "SMART_MODE=OFF"
if /i "%STRICT_MODE%" equ "OFF" (
    set "STRICT_MODE=ON"
) else (
    set "STRICT_MODE=OFF"
)
call :animate_toggle "Manual Mode -> Strict Scoring Mode [-s]" "%STRICT_MODE%"
call :save_settings
goto :main_menu

:toggle_json
if /i "%SAVE_JSON%" equ "OFF" (
    set "SAVE_JSON=ON"
) else (
    set "SAVE_JSON=OFF"
)
call :animate_toggle "Save JSON Verification Report" "%SAVE_JSON%"
call :save_settings
goto :main_menu

:toggle_anim
if /i "%UI_ANIMATIONS%" equ "ON" (
    set "UI_ANIMATIONS=OFF"
) else (
    set "UI_ANIMATIONS=ON"
)
call :save_settings
goto :main_menu

rem ============================================================================
rem Option R: Configure Advanced Tuning Parameters
rem ============================================================================

:configure_tuning
call :animate_action "Loading Advanced Detection Parameters..."
echo.
echo %C_PURPLE%----------------------------------------------------------------------------%C_RESET%
echo   %C_BOLD%%C_YELLOW%Advanced Detection Parameters [Press Enter to keep current value]%C_RESET%
echo %C_PURPLE%----------------------------------------------------------------------------%C_RESET%
set "NEW_SAMPLES="
set /p "NEW_SAMPLES=Samples per round [1-3, current=%SAMPLE_COUNT%]: "
if "%NEW_SAMPLES%" equ "1" set "SAMPLE_COUNT=1"
if "%NEW_SAMPLES%" equ "2" set "SAMPLE_COUNT=2"
if "%NEW_SAMPLES%" equ "3" set "SAMPLE_COUNT=3"

set "NEW_ROUNDS="
set /p "NEW_ROUNDS=Number of sequential rounds [-n, current=%ROUND_COUNT%]: "
if not "%NEW_ROUNDS%" equ "" set "ROUND_COUNT=%NEW_ROUNDS%"

set "NEW_TIMEOUT="
set /p "NEW_TIMEOUT=Request timeout in seconds [--timeout, current=%REQ_TIMEOUT%]: "
if not "%NEW_TIMEOUT%" equ "" set "REQ_TIMEOUT=%REQ_TIMEOUT%"

set "NEW_EFFORT="
set /p "NEW_EFFORT=Reasoning effort [-e: low/medium/high/xhigh/max or NONE, current=%EFFORT_LEVEL%]: "
if /i "%NEW_EFFORT%" equ "NONE" (
    set "EFFORT_LEVEL="
) else if not "%NEW_EFFORT%" equ "" (
    set "EFFORT_LEVEL=%NEW_EFFORT%"
)

set "NEW_PROTO="
set /p "NEW_PROTO=Protocol override [cc / message / responses, Enter to keep %API_PROTO%]: "
if /i "%NEW_PROTO%" equ "cc" (
    set "API_PROTO=cc"
    set "ANTHROPIC_MODE=OFF"
    set "SMART_MODE=OFF"
)
if /i "%NEW_PROTO%" equ "message" (
    set "API_PROTO=message"
    set "ANTHROPIC_MODE=ON"
    set "SMART_MODE=OFF"
)
if /i "%NEW_PROTO%" equ "responses" (
    set "API_PROTO=responses"
    set "ANTHROPIC_MODE=CUSTOM"
    set "SMART_MODE=OFF"
)

call :save_settings
goto :main_menu

rem ============================================================================
rem Option I: Analyze a Saved JSON Report Offline
rem ============================================================================

:analyze_offline
call :animate_action "Scanning Local Folder for Saved JSON Reports..."
echo.
echo %C_YELLOW%Available JSON reports in %WORK_DIR%:%C_RESET%
dir /b "%WORK_DIR%report_*.json" 2>nul
echo.
set "REPORT_FILE="
set /p "REPORT_FILE=%C_CYAN%Enter JSON filename to re-analyze offline [or press Enter to cancel]: %C_RESET%"
if "%REPORT_FILE%" equ "" goto :main_menu
if not exist "%REPORT_FILE%" (
    if exist "%WORK_DIR%%REPORT_FILE%" set "REPORT_FILE=%WORK_DIR%%REPORT_FILE%"
)
if not exist "%REPORT_FILE%" (
    echo %C_RED%[ERROR] File not found: %REPORT_FILE%%C_RESET%
    pause
    goto :main_menu
)
echo.
"%BUN_EXE%" x --cwd "%DEPS_DIR%" --bun lmfpd@latest --input "%REPORT_FILE%"
echo.
pause
goto :main_menu

rem ============================================================================
rem Subroutine: Run lmfpd Against a Specified Model (Smart Mode vs Manual Mode)
rem ============================================================================

:run_detector
set "CURRENT_MODEL=%~1"
if "%CURRENT_MODEL%" equ "" exit /b 0
if "%API_KEY%" equ "" call :configure_apikey_initial
call :animate_action "Preparing Verification Engine for %CURRENT_MODEL%..."

set "JSON_FILE="
set "JSON_ARGS="
if /i "%SAVE_JSON%" equ "ON" (
    set "SAFE_NAME=%CURRENT_MODEL:/=-%"
    set "SAFE_NAME=!SAFE_NAME::=-!"
    set "JSON_FILE=%WORK_DIR%report_!SAFE_NAME!.json"
    set "JSON_ARGS=--output "!JSON_FILE!""
)

if /i "%SMART_MODE%" equ "ON" (
    "%BUN_EXE%" run "%HELPER_MJS%" smart-verify "%BASE_URL%" "%API_KEY%" "%CURRENT_MODEL%" "%BUN_EXE%" "%DEPS_DIR%" "%SAMPLE_COUNT%" "%ROUND_COUNT%" "%REQ_TIMEOUT%" "%EFFORT_LEVEL%" "!JSON_FILE!"
    exit /b 0
)

echo.
echo %C_PURPLE%============================================================================%C_RESET%
echo   %C_BOLD%%C_YELLOW%Testing Model :%C_RESET% %C_WHITE%%CURRENT_MODEL%%C_RESET% %C_GRAY%[MANUAL MODE]%C_RESET%
echo   %C_BOLD%%C_YELLOW%Endpoint      :%C_RESET% %C_CYAN%%BASE_URL%%C_RESET%
echo   %C_BOLD%%C_YELLOW%Engine        :%C_RESET% %C_GRAY%Ikaleio/lm-detector [lmfpd@latest]%C_RESET%
echo   %C_BOLD%%C_YELLOW%Settings      :%C_RESET% %C_CYAN%-a %API_PROTO%  -p %PARALLEL_COUNT%  --count %SAMPLE_COUNT%  -n %ROUND_COUNT%  --timeout %REQ_TIMEOUT%  %NS_FLAG% %TOK_FLAG% %STRICT_FLAG% %EFFORT_FLAG%%C_RESET%
if not "!JSON_FILE!" equ "" echo   %C_GREEN%Report File   : !JSON_FILE!%C_RESET%
echo %C_PURPLE%============================================================================%C_RESET%

"%BUN_EXE%" x --cwd "%DEPS_DIR%" --bun lmfpd@latest -b "%BASE_URL%" -k "%API_KEY%" -m "%CURRENT_MODEL%" -a "%API_PROTO%" -p %PARALLEL_COUNT% --count %SAMPLE_COUNT% -n %ROUND_COUNT% --timeout %REQ_TIMEOUT% %NS_FLAG% %TOK_FLAG% %STRICT_FLAG% %EFFORT_FLAG% %JSON_ARGS%
exit /b 0

rem ============================================================================
rem Subroutine: Ensure Portable Bun, lmfpd & Helper Script Exist in %DEPS_DIR%
rem ============================================================================

:ensure_dependencies
call :locate_bun
if exist "%BUN_EXE%" goto :check_lmfpd_pkg

cls
call :draw_moon_header
echo.
echo %C_PURPLE%============================================================================%C_RESET%
echo   %C_BOLD%%C_YELLOW%First-Time Setup: Downloading Portable Bun Runtime into local folder...%C_RESET%
echo   %C_GRAY%Destination: %DEPS_DIR%%C_RESET%
echo %C_PURPLE%============================================================================%C_RESET%
set "BUN_ZIP=%DEPS_DIR%\bun-windows-x64.zip"
set "BUN_URL=https://github.com/oven-sh/bun/releases/latest/download/bun-windows-x64.zip"

call :download_file "%BUN_URL%" "%BUN_ZIP%"
if not exist "%BUN_ZIP%" (
    echo %C_RED%[ERROR] Could not download Bun from %BUN_URL%%C_RESET%
    exit /b 1
)

echo %C_CYAN%[INFO] Extracting portable Bun runtime...%C_RESET%
call :extract_zip "%BUN_ZIP%" "%DEPS_DIR%"
del /q "%BUN_ZIP%" >nul 2>&1

call :locate_bun
if not exist "%BUN_EXE%" (
    echo %C_RED%[ERROR] bun.exe was not found after extraction in %DEPS_DIR%.%C_RESET%
    exit /b 1
)

:check_lmfpd_pkg
if exist "%DEPS_DIR%\node_modules\lmfpd" goto :extract_helper
echo.
echo %C_CYAN%[INFO] Installing Ikaleio/lm-detector [lmfpd@latest] into %DEPS_DIR%...%C_RESET%
"%BUN_EXE%" add --cwd "%DEPS_DIR%" lmfpd@latest

:extract_helper
set "SELF_SCRIPT=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c = [System.IO.File]::ReadAllLines($env:SELF_SCRIPT); $s = -1; $e = -1; for ($i = 0; $i -lt $c.Length; $i++) { $t = $c[$i].Trim(); if ($t -eq ':: === BEGIN_HELPER_MJS ===') { $s = $i + 1 } elseif ($t -eq ':: === END_HELPER_MJS ===') { $e = $i - 1 } }; if ($s -gt 0 -and $e -ge $s) { [System.IO.File]::WriteAllLines($env:HELPER_MJS, $c[$s..$e], (New-Object System.Text.UTF8Encoding($false))) }"
exit /b 0

rem ============================================================================
rem Subroutine: Locate bun.exe Anywhere Inside %DEPS_DIR%
rem ============================================================================

:locate_bun
if exist "%DEPS_DIR%\bun-windows-x64\bun.exe" (
    set "BUN_EXE=%DEPS_DIR%\bun-windows-x64\bun.exe"
    exit /b 0
)
if exist "%DEPS_DIR%\bun-windows-x64-baseline\bun.exe" (
    set "BUN_EXE=%DEPS_DIR%\bun-windows-x64-baseline\bun.exe"
    exit /b 0
)
if exist "%DEPS_DIR%\bun.exe" (
    set "BUN_EXE=%DEPS_DIR%\bun.exe"
    exit /b 0
)
for /r "%DEPS_DIR%" %%F in (bun.exe) do (
    if exist "%%~fF" (
        set "BUN_EXE=%%~fF"
        exit /b 0
    )
)
exit /b 1

:update_lmfpd
call :animate_action "Updating Ikaleio/lm-detector [lmfpd@latest]..."
echo.
echo %C_CYAN%[INFO] Updating lmfpd@latest and reference fingerprint bank in %DEPS_DIR%...%C_RESET%
"%BUN_EXE%" add --cwd "%DEPS_DIR%" lmfpd@latest
echo %C_GREEN%[DONE] Update complete.%C_RESET%
pause
goto :main_menu

rem ============================================================================
rem Subroutine: Configure Endpoint (Base URL) - First-Time & Change Menu
rem ============================================================================

:configure_endpoint_first_time
echo.
echo %C_PURPLE%----------------------------------------------------------------------------%C_RESET%
echo   %C_BOLD%%C_YELLOW%First-Time Setup: Select or Enter 3rd-Party API Base URL%C_RESET%
echo %C_PURPLE%----------------------------------------------------------------------------%C_RESET%
echo   %C_CYAN%[1]%C_RESET% OpenRouter    %C_GRAY%https://openrouter.ai/api/v1 [Default]%C_RESET%
echo   %C_CYAN%[2]%C_RESET% Enter Custom 3rd-Party Base URL %C_GRAY%e.g., https://api.example.com/v1%C_RESET%
echo.
set "URL_CHOICE="
set /p "URL_CHOICE=%C_BOLD%%C_CYAN%Choose [1-2, default=1]: %C_RESET%"
if "%URL_CHOICE%" equ "" set "URL_CHOICE=1"
if "%URL_CHOICE%" equ "1" (
    set "BASE_URL=https://openrouter.ai/api/v1"
    set "HAS_SAVED_URL=YES"
    goto :save_settings
)
if "%URL_CHOICE%" equ "2" (
    set "NEW_URL="
    set /p "NEW_URL=%C_YELLOW%Enter full Base URL: %C_RESET%"
    if not "!NEW_URL!" equ "" set "BASE_URL=!NEW_URL!"
    set "HAS_SAVED_URL=YES"
    goto :save_settings
)
goto :save_settings

:configure_endpoint_saved
echo.
echo %C_PURPLE%----------------------------------------------------------------------------%C_RESET%
echo   %C_BOLD%%C_YELLOW%Select or Enter 3rd-Party API Base URL%C_RESET%
echo %C_PURPLE%----------------------------------------------------------------------------%C_RESET%
echo   %C_GRAY%Saved Base URL :%C_RESET% %C_GREEN%%BASE_URL%%C_RESET%
echo.
echo   %C_CYAN%[1]%C_RESET% Keep Saved    %C_GRAY%[%BASE_URL%]%C_RESET%
echo   %C_CYAN%[2]%C_RESET% OpenRouter    %C_GRAY%[https://openrouter.ai/api/v1]%C_RESET%
echo   %C_CYAN%[3]%C_RESET% Enter Custom 3rd-Party Base URL %C_GRAY%[e.g., https://api.example.com/v1]%C_RESET%
echo.
set "URL_CHOICE="
set /p "URL_CHOICE=%C_BOLD%%C_CYAN%Choose [1-3, default=1]: %C_RESET%"
if "%URL_CHOICE%" equ "" set "URL_CHOICE=1"
if "%URL_CHOICE%" equ "1" goto :save_settings
if "%URL_CHOICE%" equ "2" (
    set "BASE_URL=https://openrouter.ai/api/v1"
    goto :save_settings
)
if "%URL_CHOICE%" equ "3" (
    set "NEW_URL="
    set /p "NEW_URL=%C_YELLOW%Enter full Base URL: %C_RESET%"
    if not "!NEW_URL!" equ "" set "BASE_URL=!NEW_URL!"
)

:save_settings
(
    echo set "BASE_URL=%BASE_URL%"
    echo set "SMART_MODE=%SMART_MODE%"
    echo set "ANTHROPIC_MODE=%ANTHROPIC_MODE%"
    echo set "API_PROTO=%API_PROTO%"
    echo set "FORCE_SEQUENTIAL=%FORCE_SEQUENTIAL%"
    echo set "PARALLEL_COUNT=%PARALLEL_COUNT%"
    echo set "NO_STREAM_MODE=%NO_STREAM_MODE%"
    echo set "TOKENIZER_MODE=%TOKENIZER_MODE%"
    echo set "STRICT_MODE=%STRICT_MODE%"
    echo set "SAVE_JSON=%SAVE_JSON%"
    echo set "UI_ANIMATIONS=%UI_ANIMATIONS%"
    echo set "SAMPLE_COUNT=%SAMPLE_COUNT%"
    echo set "ROUND_COUNT=%ROUND_COUNT%"
    echo set "REQ_TIMEOUT=%REQ_TIMEOUT%"
    echo set "EFFORT_LEVEL=%EFFORT_LEVEL%"
) > "%SETTINGS_FILE%"
exit /b 0

rem ============================================================================
rem Subroutine: Exit Screen
rem ============================================================================

:exit_script
if /i "%UI_ANIMATIONS%" equ "ON" if exist "%BUN_EXE%" if exist "%HELPER_MJS%" (
    "%BUN_EXE%" run "%HELPER_MJS%" pulse "Goodnight from DeadMoon Verifier. Stay safe in the relay cosmos!"
    exit /b 0
)
echo.
echo   %C_PURPLE%Goodnight from DeadMoon Verifier. Stay safe in the relay cosmos!%C_RESET%
exit /b 0

rem ============================================================================
rem Subroutines: Download & Extract Helpers
rem ============================================================================

:download_file
where curl.exe >nul 2>&1
if not errorlevel 1 (
    curl.exe -fL "%~1" -o "%~2"
    exit /b %errorlevel%
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%~1' -OutFile '%~2' -UseBasicParsing"
exit /b %errorlevel%

:extract_zip
where tar.exe >nul 2>&1
if not errorlevel 1 (
    tar.exe -xf "%~1" -C "%~2"
    exit /b %errorlevel%
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%~1' -DestinationPath '%~2' -Force"
exit /b %errorlevel%

:: === BEGIN_HELPER_MJS ===
import fs from "node:fs";
import path from "node:path";
import readline from "node:readline/promises";
import { spawn } from "node:child_process";
import { stdin as input, stdout as output } from "node:process";

const args = process.argv.slice(2);
const mode = args[0] || "";

const C = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
  red: "\x1b[91m",
  green: "\x1b[92m",
  yellow: "\x1b[93m",
  blue: "\x1b[94m",
  purple: "\x1b[95m",
  cyan: "\x1b[96m",
  white: "\x1b[97m",
  gray: "\x1b[90m",
};

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ============================================================================
// 1. Animated DeadMoon ASCII Art & Single-Line Progress Engine
// ============================================================================

function getMoonFrame(frameIdx) {
  const f = frameIdx % 4;

  const nCol1 = f % 2 === 0 ? C.yellow : C.cyan;
  const nCol2 = f % 2 === 0 ? C.purple : C.yellow;
  const s1 = f === 0 ? "*" : f === 1 ? "+" : f === 2 ? "." : "+";
  const s2 = f === 0 ? "." : f === 1 ? "*" : f === 2 ? "+" : ".";

  const topNoteL = f === 1 || f === 2 ? nCol1 + "d~~b" + C.reset : "    ";
  const midNoteL = f === 1 || f === 2 ? nCol1 + "d  b" + C.reset : nCol1 + "d~~b" + C.reset;
  const botNoteL = f === 1 || f === 2 ? "    " : nCol1 + "d  b" + C.reset;

  const topNoteR = f === 2 || f === 3 ? nCol2 + "d~~b" + C.reset : "    ";
  const midNoteR = f === 2 || f === 3 ? nCol2 + "d  b" + C.reset : nCol2 + "d~~b" + C.reset;
  const botNoteR = f === 2 || f === 3 ? "    " : nCol2 + "d  b" + C.reset;

  const lowNote1 = f === 0 || f === 3 ? nCol1 + "d~b" + C.reset : "   ";
  const lowNote2 = f === 0 || f === 3 ? nCol1 + "d b" + C.reset : nCol2 + "d~b" + C.reset;
  const lowNote3 = f === 0 || f === 3 ? "   " : nCol2 + "d b" + C.reset;

  const waveL = f === 0 ? " .--- " : f === 1 ? "(( .--" : f === 2 ? "((( .-" : " ( .--";
  const waveR = f === 0 ? " ---. " : f === 1 ? "--. ))" : f === 2 ? "-. )))" : "--. ) ";
  const midWaveL = f === 1 || f === 2 ? "((    " : " (    ";
  const midWaveR = f === 1 || f === 2 ? "    ))" : "    ) ";

  const eyes = "\\____/    \\____/";
  const mouth = f === 2 ? " .----. " : "  .---. ";

  return [
    "      " + C.cyan + s1 + "   " + topNoteL + "  " + s2 + C.reset + "        " + C.blue + ".================." + C.reset + "        " + C.cyan + s2 + "   " + topNoteR + "   " + s1 + C.reset,
    "   " + C.cyan + s2 + "    " + midNoteL + C.reset + "      " + C.blue + ".==='  " + C.yellow + ".------------." + C.blue + "  '===." + C.reset + "      " + midNoteR + "     " + C.cyan + s2 + C.reset,
    "      " + C.cyan + s1 + " " + botNoteL + C.reset + "    " + C.blue + "/   " + C.yellow + ".-'    .      o    '-." + C.blue + "   \\" + C.reset + "     " + botNoteR + "   " + C.cyan + s1 + C.reset,
    "               " + C.blue + "/  " + C.yellow + ".'   o       .      .   '." + C.blue + "  \\" + C.reset + "        " + C.cyan + s2 + C.reset,
    "    " + C.cyan + s1 + C.reset + "         " + C.blue + "[===]" + C.yellow + "  .    " + C.white + "/        \\" + C.yellow + "    .  " + C.blue + "[===]" + C.reset + "   " + C.cyan + s2 + "       " + s1 + C.reset,
    "        " + C.blue + waveL + "[===]" + C.yellow + "     " + C.white + eyes + C.yellow + "   " + C.blue + "[===]" + waveR + C.reset + "   " + lowNote1,
    "        " + C.blue + midWaveL + "[===]" + C.yellow + "   o     " + C.white + mouth + C.yellow + "     O " + C.blue + "[===]" + midWaveR + C.reset + "   " + lowNote2,
    "    " + C.cyan + s2 + C.reset + "   " + C.blue + " '--- [===]" + C.yellow + "    .    " + C.white + "/      \\" + C.yellow + "   .   " + C.blue + "[===] ---' " + C.reset + "   " + lowNote3,
    "       " + C.cyan + s1 + C.reset + "       " + C.blue + "\\  " + C.yellow + "'.     .            o  .'" + C.blue + "  /" + C.reset + "       " + C.cyan + s1 + C.reset,
    "    " + C.cyan + s2 + C.reset + "           " + C.blue + "'.  " + C.yellow + "'-.    o   .   .  .-'" + C.blue + "  .'" + C.reset + "     " + C.cyan + s2 + "       " + s1 + C.reset,
    "         " + C.cyan + s1 + C.reset + "        " + C.blue + "'===='" + C.yellow + "--------------" + C.blue + "'===='" + C.reset + "          " + C.cyan + s2 + C.reset,
  ].join("\n");
}

async function runBootAnimation() {
  const stages = [
    { pct: 25,  bar: "###---------", color: C.yellow, text: "Tuning frequencies...      " },
    { pct: 25,  bar: "###---------", color: C.yellow, text: "Tuning frequencies...      " },
    { pct: 25,  bar: "###---------", color: C.yellow, text: "Tuning frequencies...      " },
    { pct: 50,  bar: "######------", color: C.cyan,   text: "Loading probability bank..." },
    { pct: 50,  bar: "######------", color: C.cyan,   text: "Loading probability bank..." },
    { pct: 50,  bar: "######------", color: C.cyan,   text: "Loading probability bank..." },
    { pct: 75,  bar: "#########---", color: C.purple, text: "Syncing relay protocols... " },
    { pct: 75,  bar: "#########---", color: C.purple, text: "Syncing relay protocols... " },
    { pct: 75,  bar: "#########---", color: C.purple, text: "Syncing relay protocols... " },
    { pct: 100, bar: "############", color: C.green,  text: "Ready.                     " },
    { pct: 100, bar: "############", color: C.green,  text: "Ready.                     " },
    { pct: 100, bar: "############", color: C.green,  text: "Ready.                     " },
  ];

  output.write("\x1b[2J\x1b[H\x1b[?25l");
  try {
    for (let i = 0; i < stages.length; i++) {
      const st = stages[i];
      const frame =
        "\x1b[H\n" +
        getMoonFrame(i) +
        "\n\n" +
        "  " + C.purple + "============================================================================" + C.reset + "\n" +
        "    " + C.bold + C.white + "D E A D M O O N   U N I V E R S A L   A P I   V E R I F I E R" + C.reset + "\n" +
        "    " + C.cyan + "Powered by Ikaleio/lm-detector [lmfpd] & Oven Bun Runtime" + C.reset + "\n" +
        "  " + C.purple + "============================================================================" + C.reset + "\n\n" +
        "    " + st.color + "[Moonlight Engine] " + C.white + st.text + " " + st.color + "[" + st.bar + "] " + String(st.pct).padStart(3, " ") + "%" + C.reset + "   \n";
      output.write(frame);
      await sleep(150);
    }
  } finally {
    output.write("\x1b[?25h");
  }
}

async function runPulseAnimation(msg) {
  const steps = [
    { pct: 25,  bar: "###---------", note: "d~b  .  * " },
    { pct: 50,  bar: "######------", note: " .  d~~b *" },
    { pct: 75,  bar: "#########---", note: " *   . d~b" },
    { pct: 100, bar: "############", note: "d~~b *  . " },
  ];
  output.write("\n\x1b[?25l");
  try {
    for (const s of steps) {
      output.write(
        "\r  " + C.purple + "( " + C.yellow + s.note + C.purple + " )" + C.reset +
        " " + C.cyan + "[" + s.bar + "] " + String(s.pct).padStart(3, " ") + "%" + C.reset +
        " " + C.white + msg + C.reset + "   "
      );
      await sleep(95);
    }
    output.write("\n");
  } finally {
    output.write("\x1b[?25h");
  }
}

async function runToggleAnimation(label, state) {
  const stateColor = state.toUpperCase() === "ON" ? C.green : C.gray;
  const frames = ["[>...]", "[>>..]", "[>>>.]", "[" + state.toUpperCase() + "]"];
  output.write("\n\x1b[?25l");
  try {
    for (const f of frames) {
      output.write(
        "\r  " + C.yellow + "* [TOGGLE] " + C.white + label + C.reset + " ---> " + stateColor + f + C.reset + "      "
      );
      await sleep(60);
    }
  } finally {
    output.write("\x1b[?25h");
  }
}

// ============================================================================
// 2. API Key Save & Reveal Utilities
// ============================================================================

function saveApiKeyToFile() {
  const filePath = args[1] || "";
  const rawKey = (args[2] || "").trim();
  if (!filePath || !rawKey) return;
  fs.writeFileSync(filePath, rawKey + "\r\n", "utf8");
  console.log(C.green + "[OK] API Key saved locally to " + filePath + C.reset);
}

function viewApiKeyDetails() {
  const baseUrl = args[1] || "";
  const activeKey = (args[2] || "").trim();
  const storageMode = args[3] || "NONE";
  const keyFile = args[4] || "";

  let diskKey = "";
  if (keyFile && fs.existsSync(keyFile)) {
    try {
      diskKey = fs.readFileSync(keyFile, "utf8").trim();
    } catch {
      diskKey = "";
    }
  }

  console.log(C.purple + "============================================================================" + C.reset);
  console.log("  " + C.bold + C.yellow + "DEADMOON API KEY VIEWER" + C.reset);
  console.log(C.purple + "============================================================================" + C.reset);
  console.log("  " + C.gray + "Target Provider URL : " + C.cyan + baseUrl + C.reset);
  console.log("  " + C.gray + "Storage Status      : " + C.green + storageMode + C.reset);
  console.log("  " + C.gray + "Local Vault Path    : " + C.white + keyFile + C.reset);
  console.log(C.purple + "----------------------------------------------------------------------------" + C.reset);

  if (activeKey) {
    console.log("  " + C.bold + C.yellow + "Active Session API Key (" + activeKey.length + " chars):" + C.reset);
    console.log("  " + C.bold + C.green + activeKey + C.reset);
  } else {
    console.log("  " + C.red + "Active Session API Key : [NOT SET]" + C.reset);
  }

  console.log(C.purple + "----------------------------------------------------------------------------" + C.reset);
  if (diskKey) {
    console.log("  " + C.bold + C.yellow + "Saved Disk API Key (" + diskKey.length + " chars):" + C.reset);
    console.log("  " + C.bold + C.cyan + diskKey + C.reset);
  } else {
    console.log("  " + C.gray + "Saved Disk API Key     : [NONE SAVED ON DISK]" + C.reset);
  }
  console.log(C.purple + "============================================================================" + C.reset);
}

// ============================================================================
// 3. Universal Multi-Strategy Model Catalog Fetcher & Fuzzy Search
// ============================================================================

function normalizeBase(url) {
  let trimmed = (url || "").trim();
  while (trimmed.endsWith("/")) {
    trimmed = trimmed.slice(0, -1);
  }
  if (!trimmed) return "https://openrouter.ai/api/v1";
  return trimmed;
}

function getRootAndV1(url) {
  const clean = normalizeBase(url);
  if (clean.endsWith("/v1")) {
    return { root: clean.slice(0, -3), v1: clean };
  }
  return { root: clean, v1: clean + "/v1" };
}

function extractEntriesFromPayload(json) {
  const rawList = Array.isArray(json)
    ? json
    : Array.isArray(json?.data)
    ? json.data
    : Array.isArray(json?.models)
    ? json.models
    : [];
  const out = [];
  for (const item of rawList) {
    if (typeof item === "string") {
      out.push({ id: item, name: "" });
    } else if (item && typeof item === "object") {
      const id = item.id || item.name || item.model || "";
      const name = item.name && item.name !== id ? item.name : item.display_name || "";
      if (id) out.push({ id: String(id), name: String(name) });
    }
  }
  return out;
}

async function fetchModelsUniversal(baseUrl, key) {
  const { root, v1 } = getRootAndV1(baseUrl);
  const catalogMap = new Map();
  const sourcesUsed = [];
  let lastError = "";

  const strategies = [
    {
      label: "OpenAI Bearer",
      url: v1 + "/models",
      headers: key ? { "Authorization": "Bearer " + key, "Accept": "application/json" } : { "Accept": "application/json" },
    },
    {
      label: "OpenAI Bearer [limit=1000]",
      url: v1 + "/models?limit=1000",
      headers: key ? { "Authorization": "Bearer " + key, "Accept": "application/json" } : { "Accept": "application/json" },
    },
    {
      label: "Public Catalog",
      url: v1 + "/models",
      headers: { "Accept": "application/json" },
    },
    {
      label: "Anthropic Native [limit=1000]",
      url: v1 + "/models?limit=1000",
      headers: {
        "x-api-key": key,
        "Authorization": "Bearer " + key,
        "anthropic-version": "2023-06-01",
        "Accept": "application/json",
      },
    },
    {
      label: "Root /models",
      url: root + "/models",
      headers: key ? { "Authorization": "Bearer " + key, "Accept": "application/json" } : { "Accept": "application/json" },
    },
  ];

  for (const strat of strategies) {
    if (catalogMap.size > 30) break;

    try {
      const res = await fetch(strat.url, {
        method: "GET",
        headers: strat.headers,
      });
      const text = await res.text();
      if (!res.ok) {
        lastError = "HTTP " + res.status + " from " + strat.url + ": " + text.slice(0, 180);
        continue;
      }
      const json = JSON.parse(text);
      const entries = extractEntriesFromPayload(json);
      if (entries.length > 0) {
        let added = 0;
        for (const e of entries) {
          if (!catalogMap.has(e.id)) {
            catalogMap.set(e.id, e);
            added++;
          }
        }
        if (added > 0) sourcesUsed.push(strat.label + " [" + entries.length + "]");
      }
    } catch (err) {
      lastError = strat.url + " -> " + err.message;
    }
  }

  if (catalogMap.size === 0) {
    throw new Error(lastError || "Could not fetch /models from provider.");
  }

  const sorted = Array.from(catalogMap.values()).sort((a, b) => a.id.localeCompare(b.id));
  return { models: sorted, sourceSummary: sourcesUsed.join(" + ") };
}

function filterCatalog(models, rawQuery) {
  const q = (rawQuery || "").trim().toLowerCase();
  if (!q || q === "all" || q === "*") {
    return { matched: models, fallbackUsed: false, fallbackToken: "" };
  }

  const tokens = q.split(/[\s,/_\-]+/).filter(Boolean);

  const exactMatches = models.filter((m) => {
    const hay = (m.id + " " + (m.name || "")).toLowerCase();
    const hayNorm = hay.replace(/[/_\-]/g, " ");
    return tokens.every((t) => hay.includes(t) || hayNorm.includes(t));
  });

  if (exactMatches.length > 0) {
    return { matched: exactMatches, fallbackUsed: false, fallbackToken: "" };
  }

  for (const t of tokens) {
    if (t.length < 2) continue;
    const partial = models.filter((m) => {
      const hay = (m.id + " " + (m.name || "")).toLowerCase();
      return hay.includes(t);
    });
    if (partial.length > 0) {
      return { matched: partial, fallbackUsed: true, fallbackToken: t };
    }
  }

  return { matched: [], fallbackUsed: false, fallbackToken: "" };
}

function parseSelection(sel, maxLen) {
  const trimmed = sel.trim().toLowerCase();
  if (!trimmed) return [];
  if (trimmed === "a" || trimmed === "all") {
    return Array.from({ length: maxLen }, (_, i) => i + 1);
  }
  const indices = new Set();
  const parts = trimmed.split(/[\s,]+/);
  for (const part of parts) {
    if (!part) continue;
    if (part.includes("-")) {
      const [startStr, endStr] = part.split("-");
      const start = Number.parseInt(startStr, 10);
      const end = Number.parseInt(endStr, 10);
      if (!Number.isNaN(start) && !Number.isNaN(end)) {
        const lo = Math.max(1, Math.min(start, end));
        const hi = Math.min(maxLen, Math.max(start, end));
        for (let i = lo; i <= hi; i++) indices.add(i);
      }
    } else {
      const num = Number.parseInt(part, 10);
      if (!Number.isNaN(num) && num >= 1 && num <= maxLen) {
        indices.add(num);
      }
    }
  }
  return Array.from(indices);
}

async function runModelsInteractive() {
  const rawBaseUrl = args[1] || "";
  const apiKey = args[2] || "";
  const outFile = args[3] || "";

  console.log(C.cyan + "[INFO] Querying full provider model catalog from " + rawBaseUrl + " ..." + C.reset);
  let result;
  try {
    result = await fetchModelsUniversal(rawBaseUrl, apiKey);
  } catch (err) {
    console.error("\n" + C.red + "[ERROR] Auto-detection failed: " + err.message + C.reset);
    console.error("Tip: Check your Base URL and API Key, or test a model directly with Option [1] or [4].");
    process.exit(1);
  }

  console.log(
    C.green + "[OK] Discovered " + result.models.length + " total models" + C.reset +
    C.gray + " via " + result.sourceSummary + C.reset
  );

  const rl = readline.createInterface({ input, output });
  try {
    let filtered = [];
    while (true) {
      const filterStr = (
        await rl.question(
          "\n" + C.yellow + "Filter models by keyword [e.g., claude, opus, gpt, deepseek, free] or press Enter to show all: " + C.reset
        )
      ).trim();

      const searchRes = filterCatalog(result.models, filterStr);
      filtered = searchRes.matched;

      if (filtered.length === 0) {
        console.log(
          "\n" + C.yellow + "[WARN] No models matched '" + filterStr + "' out of " + result.models.length + " catalog models." + C.reset
        );
        const retry = (await rl.question(C.cyan + "Try another keyword [or type EXIT to cancel]: " + C.reset)).trim();
        if (retry.toLowerCase() === "exit") process.exit(0);
        const retryRes = filterCatalog(result.models, retry);
        if (retryRes.matched.length > 0) {
          filtered = retryRes.matched;
          if (retryRes.fallbackUsed) {
            console.log(
              "\n" + C.cyan + "[SMART SEARCH] No exact match for '" + retry + "', showing " +
              filtered.length + " closest matches for '" + retryRes.fallbackToken + "' instead:" + C.reset
            );
          }
          break;
        }
        continue;
      }

      if (searchRes.fallbackUsed) {
        console.log(
          "\n" + C.cyan + "[SMART SEARCH] No exact match for '" + filterStr + "' on this provider. Showing " +
          filtered.length + " closest matches for '" + searchRes.fallbackToken + "' instead:" + C.reset
        );
      }
      break;
    }

    console.log("\n" + C.purple + "----------------------------------------------------------------------------" + C.reset);
    console.log(C.yellow + " Available Models [" + filtered.length + " shown]:" + C.reset);
    console.log(C.purple + "----------------------------------------------------------------------------" + C.reset);
    filtered.forEach((m, idx) => {
      const num = String(idx + 1).padStart(3, " ");
      const label = m.name ? m.id + C.gray + "  [" + m.name + "]" + C.reset : m.id;
      console.log(" " + C.cyan + "[" + num + "]" + C.reset + " " + label);
    });
    console.log(C.purple + "----------------------------------------------------------------------------" + C.reset);
    console.log(" Selection formats: Single [4] | Multiple [1, 3, 5] | Range [1-5] | All [all]");

    const choice = await rl.question(
      C.cyan + "Enter model number[s] to verify [or press Enter to cancel]: " + C.reset
    );
    const pickedIndices = parseSelection(choice, filtered.length);
    if (pickedIndices.length === 0) {
      console.log("[INFO] Selection canceled.");
      process.exit(0);
    }

    const pickedModels = pickedIndices.map((i) => filtered[i - 1].id);
    fs.writeFileSync(outFile, pickedModels.join("\n") + "\n", "utf8");
    console.log("\n" + C.green + "[OK] Queued " + pickedModels.length + " model[s]: " + pickedModels.join(", ") + C.reset);
  } finally {
    rl.close();
  }
}

// ============================================================================
// 4. Smart Auto-Config & Self-Healing Verification Orchestrator
// ============================================================================

async function quickProbeProtocol(baseUrl, apiKey, model) {
  const { v1 } = getRootAndV1(baseUrl);
  const lowerUrl = baseUrl.toLowerCase();
  const lowerModel = model.toLowerCase();

  if (lowerUrl.includes("openrouter.ai")) {
    return { proto: "cc", reason: "OpenRouter native gateway [-a cc]" };
  }

  if (lowerModel.includes("claude") || lowerModel.includes("anthropic")) {
    try {
      const res = await fetch(v1 + "/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": "Bearer " + apiKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model,
          max_tokens: 4,
          stream: false,
          messages: [{ role: "user", content: "OK" }],
        }),
      });
      if (res.ok) {
        return { proto: "cc", reason: "Pre-flight /v1/chat/completions probe succeeded" };
      }
    } catch {
      // fallback to testing /v1/messages
    }

    try {
      const resMsg = await fetch(v1 + "/messages", {
        method: "POST",
        headers: {
          "x-api-key": apiKey,
          "Authorization": "Bearer " + apiKey,
          "anthropic-version": "2023-06-01",
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model,
          max_tokens: 4,
          stream: false,
          messages: [{ role: "user", content: "OK" }],
        }),
      });
      if (resMsg.ok) {
        return { proto: "message", reason: "Pre-flight /v1/messages [Anthropic native] succeeded" };
      }
    } catch {
      // fallback to cc
    }
  }

  return { proto: "cc", reason: "Standard OpenAI Chat Completions [-a cc]" };
}

function resolveLocalLmfpdEntry(depsDir) {
  try {
    const pkgDir = path.join(depsDir, "node_modules", "lmfpd");
    const pkgJsonPath = path.join(pkgDir, "package.json");
    if (fs.existsSync(pkgJsonPath)) {
      const pkg = JSON.parse(fs.readFileSync(pkgJsonPath, "utf8"));
      const binRel = typeof pkg.bin === "string" ? pkg.bin : pkg.bin?.fpd || pkg.bin?.lmfpd || pkg.main;
      if (binRel) {
        const fullBin = path.join(pkgDir, binRel);
        if (fs.existsSync(fullBin)) return fullBin;
      }
    }
  } catch {
    // ignore and fallback
  }
  return "";
}

function executeLmfpd(bunExe, depsDir, cliArgs) {
  return new Promise((resolve) => {
    let combinedLog = "";
    const localEntry = resolveLocalLmfpdEntry(depsDir);
    const spawnArgs = localEntry
      ? ["run", localEntry, ...cliArgs]
      : ["x", "--cwd", depsDir, "--bun", "lmfpd@latest", ...cliArgs];

    const child = spawn(bunExe, spawnArgs, {
      stdio: ["inherit", "pipe", "pipe"],
      windowsHide: true,
    });

    child.stdout.on("data", (chunk) => {
      const text = chunk.toString();
      combinedLog += text;
      output.write(chunk);
    });

    child.stderr.on("data", (chunk) => {
      const text = chunk.toString();
      combinedLog += text;
      output.write(chunk);
    });

    child.on("close", (code) => {
      resolve({ code: code ?? 0, log: combinedLog });
    });
  });
}

async function runSmartVerify() {
  const baseUrl = args[1] || "";
  const apiKey = args[2] || "";
  const model = args[3] || "";
  const bunExe = args[4] || "bun";
  const depsDir = args[5] || ".";
  const sampleCount = args[6] || "3";
  const roundCount = args[7] || "1";
  const reqTimeout = args[8] || "180";
  const effortLevel = args[9] || "";
  const jsonFile = args[10] || "";

  const lowerModel = model.toLowerCase();
  const isReasoning =
    lowerModel.includes("opus") ||
    lowerModel.includes("r1") ||
    lowerModel.includes("o1") ||
    lowerModel.includes("o3") ||
    lowerModel.includes("qwq") ||
    lowerModel.includes("thinking");

  const smartTimeout = isReasoning && Number(reqTimeout) < 240 ? "240" : reqTimeout;
  const probe = await quickProbeProtocol(baseUrl, apiKey, model);

  const proto = probe.proto;
  const parallel = "1";
  let noStream = false;

  console.log("\n" + C.purple + "============================================================================" + C.reset);
  console.log("  " + C.bold + C.green + "[SMART MODE] Auto-Configured Verification Profile" + C.reset);
  console.log("  " + C.yellow + "Model       : " + C.white + model + C.reset);
  console.log("  " + C.yellow + "Endpoint    : " + C.cyan + baseUrl + C.reset);
  console.log("  " + C.yellow + "Protocol    : " + C.cyan + "-a " + proto + C.gray + " [" + probe.reason + "]" + C.reset);
  console.log("  " + C.yellow + "Protection  : " + C.cyan + "-p " + parallel + " [Sequential Safe] | Timeout: " + smartTimeout + "s" + C.reset);
  if (jsonFile) console.log("  " + C.green + "Report File : " + jsonFile + C.reset);
  console.log(C.purple + "============================================================================" + C.reset + "\n");

  const buildArgs = (pProto, pParallel, pNoStream) => {
    const list = [
      "-b", baseUrl,
      "-k", apiKey,
      "-m", model,
      "-a", pProto,
      "-p", pParallel,
      "--count", sampleCount,
      "-n", roundCount,
      "--timeout", smartTimeout,
    ];
    if (pNoStream) list.push("-ns");
    if (effortLevel) list.push("-e", effortLevel);
    if (jsonFile) list.push("--output", jsonFile);
    return list;
  };

  const res1 = await executeLmfpd(bunExe, depsDir, buildArgs(proto, parallel, noStream));
  const logLower = res1.log.toLowerCase();

  const hasStreamDrop =
    logLower.includes("missing finish status") ||
    logLower.includes("response is not complete") ||
    logLower.includes("unexpected end") ||
    logLower.includes("stream error") ||
    logLower.includes("terminated");

  const hasRateOrPoolError =
    logLower.includes("429") ||
    logLower.includes("402") ||
    logLower.includes("503") ||
    logLower.includes("rate limit") ||
    logLower.includes("temporarily unavailable") ||
    logLower.includes("concurrency");

  const hasProtoError =
    logLower.includes("404") ||
    logLower.includes("unsupported") ||
    logLower.includes("invalid_request_error") ||
    (res1.code !== 0 && !hasStreamDrop && !hasRateOrPoolError);

  if (hasStreamDrop && !noStream) {
    console.log("\n" + C.yellow + "============================================================================" + C.reset);
    console.log("  " + C.bold + C.yellow + "[SMART AUTO-HEAL] Detected dropped SSE stream from relay!" + C.reset);
    console.log("  " + C.cyan + "Action: Switching to Non-Streaming JSON Mode [-ns] & retrying automatically..." + C.reset);
    console.log(C.yellow + "============================================================================" + C.reset + "\n");
    noStream = true;
    await sleep(1200);
    await executeLmfpd(bunExe, depsDir, buildArgs(proto, "1", true));
  } else if (hasRateOrPoolError) {
    const altProto = proto === "cc" && (lowerModel.includes("claude") || lowerModel.includes("anthropic")) ? "message" : proto;
    console.log("\n" + C.yellow + "============================================================================" + C.reset);
    console.log("  " + C.bold + C.yellow + "[SMART AUTO-HEAL] Detected relay rate-limit / upstream pool error!" + C.reset);
    console.log("  " + C.cyan + "Action: Cooling down 2.5s, enabling Non-Streaming [-ns] + protocol [-a " + altProto + "]..." + C.reset);
    console.log(C.yellow + "============================================================================" + C.reset + "\n");
    await sleep(2500);
    await executeLmfpd(bunExe, depsDir, buildArgs(altProto, "1", true));
  } else if (hasProtoError && (lowerModel.includes("claude") || lowerModel.includes("anthropic"))) {
    const altProto = proto === "cc" ? "message" : "cc";
    console.log("\n" + C.yellow + "============================================================================" + C.reset);
    console.log("  " + C.bold + C.yellow + "[SMART AUTO-HEAL] Detected protocol error on -a " + proto + "!" + C.reset);
    console.log("  " + C.cyan + "Action: Switching protocol to -a " + altProto + " + Non-Streaming [-ns] & retrying..." + C.reset);
    console.log(C.yellow + "============================================================================" + C.reset + "\n");
    await sleep(1200);
    await executeLmfpd(bunExe, depsDir, buildArgs(altProto, "1", true));
  }
}

// ============================================================================
// 5. Dual-Protocol Diagnostic Ping
// ============================================================================

async function runDiagnosticPing() {
  const rawBaseUrl = args[1] || "";
  const apiKey = args[2] || "";
  const model = args[3] || "openai/gpt-4o-mini";
  const { v1 } = getRootAndV1(rawBaseUrl);

  console.log(C.purple + "============================================================================" + C.reset);
  console.log(C.yellow + " DEADMOON DIAGNOSTIC PING TEST : " + C.white + model + C.reset);
  console.log(C.purple + "============================================================================" + C.reset);

  const ccUrl = v1 + "/chat/completions";
  console.log("\n" + C.cyan + "[Test 1/2] OpenAI Chat Completions [-a cc] -> POST " + ccUrl + C.reset);
  const t0 = performance.now();
  try {
    const res = await fetch(ccUrl, {
      method: "POST",
      headers: {
        "Authorization": "Bearer " + apiKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        max_tokens: 16,
        stream: false,
        messages: [{ role: "user", content: "Reply with the single word OK." }],
      }),
    });
    const ms = Math.round(performance.now() - t0);
    const bodyText = await res.text();
    console.log("  Status  : HTTP " + res.status + " [" + ms + " ms]");
    if (res.ok) {
      try {
        const data = JSON.parse(bodyText);
        const reply = data?.choices?.[0]?.message?.content ?? "(empty)";
        console.log("  Reported: model='" + (data.model || "unknown") + "' | Reply: " + JSON.stringify(reply).slice(0, 80));
        console.log("  " + C.green + "Verdict : [PASS] OpenAI Chat Completions [-a cc] works for this model!" + C.reset);
      } catch {
        console.log("  Raw Body: " + bodyText.slice(0, 200));
      }
    } else {
      console.log("  " + C.red + "Error   : " + bodyText.slice(0, 250) + C.reset);
    }
  } catch (err) {
    console.log("  " + C.red + "Failed  : " + err.message + C.reset);
  }

  const msgUrl = v1 + "/messages";
  console.log("\n" + C.cyan + "[Test 2/2] Anthropic Messages Mode [-a message] -> POST " + msgUrl + C.reset);
  const t1 = performance.now();
  try {
    const res = await fetch(msgUrl, {
      method: "POST",
      headers: {
        "x-api-key": apiKey,
        "Authorization": "Bearer " + apiKey,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        max_tokens: 16,
        stream: false,
        messages: [{ role: "user", content: "Reply with the single word OK." }],
      }),
    });
    const ms = Math.round(performance.now() - t1);
    const bodyText = await res.text();
    console.log("  Status  : HTTP " + res.status + " [" + ms + " ms]");
    if (res.ok) {
      try {
        const data = JSON.parse(bodyText);
        const reply = data?.content?.[0]?.text ?? "(empty)";
        console.log("  Reported: model='" + (data.model || "unknown") + "' | Reply: " + JSON.stringify(reply).slice(0, 80));
        console.log("  " + C.green + "Verdict : [PASS] Anthropic Messages Mode [-a message] works for this model!" + C.reset);
      } catch {
        console.log("  Raw Body: " + bodyText.slice(0, 200));
      }
    } else {
      console.log("  " + C.red + "Error   : " + bodyText.slice(0, 250) + C.reset);
    }
  } catch (err) {
    console.log("  " + C.red + "Failed  : " + err.message + C.reset);
  }
  console.log(C.purple + "============================================================================" + C.reset);
}

if (mode === "boot") {
  await runBootAnimation();
} else if (mode === "pulse") {
  await runPulseAnimation(args[1] || "Working...");
} else if (mode === "toggle") {
  await runToggleAnimation(args[1] || "Setting", args[2] || "ON");
} else if (mode === "save-key") {
  saveApiKeyToFile();
} else if (mode === "view-key") {
  viewApiKeyDetails();
} else if (mode === "models") {
  await runModelsInteractive();
} else if (mode === "ping") {
  await runDiagnosticPing();
} else if (mode === "smart-verify") {
  await runSmartVerify();
}
:: === END_HELPER_MJS ===
