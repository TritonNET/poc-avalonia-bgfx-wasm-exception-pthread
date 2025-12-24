cmake_minimum_required(VERSION 3.10)

set(CMAKE_TOOLCHAIN_FILE "$ENV{EMSDK}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" CACHE STRING "Emscripten toolchain file")

message(STATUS "WebAssembly build enabled")
message(STATUS "CMAKE_TOOLCHAIN_FILE='${CMAKE_TOOLCHAIN_FILE}'")

project(bgfx-poc)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_COMPILE_WARNING_AS_ERROR ON)

set(BGFX_DIR ${CMAKE_SOURCE_DIR}/bgfx)

include_directories(${BGFX_DIR}/include)
include_directories(${CMAKE_SOURCE_DIR}/bx/include)
include_directories(${CMAKE_SOURCE_DIR}/bimg/include)

add_definitions(-DBX_CONFIG_DEBUG)

add_executable(bgfx-poc main.cpp)

# Install shaders for all platforms
file(INSTALL DESTINATION ${CMAKE_BINARY_DIR}
    TYPE FILE
    FILES ${BGFX_DIR}/examples/runtime/shaders/glsl/vs_cubes.bin
    ${BGFX_DIR}/examples/runtime/shaders/glsl/fs_cubes.bin)

set(CMAKE_CXX_FLAGS "-s MIN_WEBGL_VERSION=2 \
        -s MAX_WEBGL_VERSION=2 \
        -pthread \
        --preload-file vs_cubes.bin \
        --preload-file fs_cubes.bin \
        --bind \
        --use-preload-plugins \
        -Wall \
        -Wextra \
        -Werror=return-type \
        -s ASSERTIONS=1 \
        -w \
        -g4 \
        -s DISABLE_EXCEPTION_CATCHING=1 \
        -Os \
        -s USE_GLFW=3 \
        --no-heap-copy \
        -s GL_ENABLE_GET_PROC_ADDRESS \
        -static \
        -s ALLOW_MEMORY_GROWTH=1 \
        -s EXIT_RUNTIME=1")

target_link_libraries(bgfx-poc
    ${BGFX_DIR}/.build/wasm/bin/bgfxDebug.bc
    ${BGFX_DIR}/.build/wasm/bin/bxDebug.bc
    ${BGFX_DIR}/.build/wasm/bin/bimgDebug.bc)

file(INSTALL DESTINATION ${CMAKE_BINARY_DIR}
    TYPE FILE
    FILES ${CMAKE_SOURCE_DIR}/index.html)