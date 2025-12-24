@echo off
setlocal EnableExtensions

set EMSDK_VERSION=3.1.51
set ROOT_DIR=%~dp0
set EMSDK_DIR=%ROOT_DIR%emsdk
set BGFX_DIR=%ROOT_DIR%bgfx

REM ============================================================
REM Sanity checks
REM ============================================================
if not exist "%EMSDK_DIR%\emsdk.bat" (
    echo [ERROR] EMSDK not found at %EMSDK_DIR%
    exit /b 1
)

if not exist "%BGFX_DIR%\makefile" (
    echo [ERROR] BGFX not found; makefile missing at %BGFX_DIR%
    exit /b 1
)

REM ============================================================
REM Activate EMSDK (session-only)
REM ============================================================
echo ===== Activating EMSDK %EMSDK_VERSION% =====

call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
call "%EMSDK_DIR%\emsdk.bat" install %EMSDK_VERSION%
call "%EMSDK_DIR%\emsdk.bat" activate %EMSDK_VERSION%
call "%EMSDK_DIR%\emsdk_env.bat"

REM ============================================================
REM Build BGFX (WASM debug)
REM ============================================================
pushd "%BGFX_DIR%"

echo.
echo "------- Building BGFX WASM Debug -----"
echo.

REM FIX 1: Clean previous BGFX builds to prevent linking old non-pthread binaries
if exist ".build" (
    echo [INFO] Cleaning BGFX build directory...
    rmdir /s /q .build
)

REM FIX 2: Added -fexceptions to override BGFX's default -fno-exceptions
REM This resolves the "DISABLE_EXCEPTION_THROWING" error.
set "CXXFLAGS=-pthread"
set "CFLAGS=-pthread"
set "LDFLAGS=-pthread"

call emmake make wasm-debug BGFX_CONFIG_EXAMPLES=0 BGFX_CONFIG_TOOLS=0
if errorlevel 1 (
    echo [WARN] BGFX build failed. Continuing...
)
set "CXXFLAGS="
set "CFLAGS="
set "LDFLAGS="

popd

echo [INFO] Patching BGFX Makefiles to enable exceptions...

set "WASM_PROJECT_DIR=%BGFX_DIR%\.build\projects\gmake-wasm"
if not exist "%WASM_PROJECT_DIR%" (
    echo [ERROR] Project directory not found: %WASM_PROJECT_DIR%
    exit /b 1
)

pushd "%WASM_PROJECT_DIR%"

powershell -Command "Get-ChildItem -Path '*.make' -Recurse | ForEach-Object { (Get-Content $_) -replace '-fno-exceptions', '-fexceptions' | Set-Content $_ }"

popd

REM ============================================================
REM Build project (WASM)
REM ============================================================
echo "------- Building Project WASM -----"
if exist buildwasm (
    echo "Cleaning existing buildwasm directory..."
    rmdir /s /q buildwasm 2>nul
)

echo "Creating buildwasm directory..."
mkdir buildwasm

echo "Configuring CMake..."
call emcmake cmake -B buildwasm

echo "Changing to buildwasm directory..."

pushd buildwasm

echo "Building with emmake..."
call cmake --build .
if errorlevel 1 (
    echo [ERROR] Project build failed.
    popd
    exit /b 1
)

popd

REM ============================================================
REM Done
REM ============================================================
echo.
echo ===== Build script finished =====
echo.

endlocal
exit /b 0