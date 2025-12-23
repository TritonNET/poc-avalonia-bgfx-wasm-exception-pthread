@echo off
setlocal enabledelayedexpansion

call "D:\projects\tritonnet\tritonsim\src\3rdparty\emsdk\emsdk_env.bat"

pushd bgfx
emmake make wasm-debug
popd

emcmake cmake -B buildwasm

pushd buildwasm

emmake make

popd