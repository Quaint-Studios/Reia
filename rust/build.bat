@echo off
setlocal enabledelayedexpansion

:: Set Defaults
set BUILD_TYPE=debug
set CARGO_ARGS=
set TARGET_DIR=debug

:: Parse Arguments
if /I "%~1"=="release" (
    set BUILD_TYPE=release
    set CARGO_ARGS=--release
    set TARGET_DIR=release
) else if /I "%~1"=="--release" (
    set BUILD_TYPE=release
    set CARGO_ARGS=--release
    set TARGET_DIR=release
)

echo ===================================================
echo Building Reia's Rust Backend in !BUILD_TYPE! mode...
echo ===================================================

:: 3. Run Cargo Build
cargo build !CARGO_ARGS!
if %ERRORLEVEL% NEQ 0 (
    echo Cargo build failed!
    exit /b %ERRORLEVEL%
)

:: Setup Output Directory
set OUT_DIR=..\godot\build\bin
if not exist "%OUT_DIR%" (
    echo Creating directory: %OUT_DIR%
    mkdir "%OUT_DIR%"
)

:: Copy and Rename the DLL
echo Copying binary to %OUT_DIR%\reia_backend.!BUILD_TYPE!.dll...
copy /Y "target\!TARGET_DIR!\reia_backend.dll" "%OUT_DIR%\reia_backend.!BUILD_TYPE!.dll" >nul

if %ERRORLEVEL% NEQ 0 (
    echo Failed to copy DLL! Ensure Godot is not currently locking the file.
    exit /b %ERRORLEVEL%
)

echo Build and deployment complete!
