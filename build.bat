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

call emmake make wasm-debug BGFX_CONFIG_EXAMPLES=0 BGFX_CONFIG_TOOLS=0
if errorlevel 1 (
    echo [WARN] BGFX build failed. Continuing...
)

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

REM call emmake make
call cmake --build .
popd

REM ============================================================
REM Done
REM ============================================================
echo.
echo ===== Build script finished =====
echo.

endlocal
exit /b 0
