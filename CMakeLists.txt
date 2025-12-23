cmake_minimum_required(VERSION 3.10)

# If the EMSDK environment variable is set, configure the toolchain file.
if(DEFINED ENV{EMSDK})
    set(CMAKE_TOOLCHAIN_FILE "$ENV{EMSDK}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" CACHE STRING "Emscripten toolchain file")
    message(STATUS "WebAssembly build enabled")
    message(STATUS "CMAKE_TOOLCHAIN_FILE='${CMAKE_TOOLCHAIN_FILE}'")
else()
    if(WIN32)
        message(STATUS "Native Windows build enabled (NMake/MSVC).")
    else()
        message(STATUS "Native Linux/Unix build enabled.")
    endif()
endif()

project(bgfx-glfw-wasm-3dcube-template-starting-point)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_COMPILE_WARNING_AS_ERROR ON)

set(BGFX_DIR ${CMAKE_SOURCE_DIR}/bgfx)

# Native dependencies (Windows/Linux)
if(NOT DEFINED ENV{EMSDK})
    find_package(glfw3 REQUIRED)
    find_package(OpenGL REQUIRED)
endif()

include_directories(${BGFX_DIR}/include)
include_directories(${CMAKE_SOURCE_DIR}/bx/include)
include_directories(${CMAKE_SOURCE_DIR}/bimg/include)

add_definitions(-DBX_CONFIG_DEBUG)

add_executable(bgfx-glfw-wasm-3dcube-template-starting-point main.cpp)

# Install shaders for all platforms
file(INSTALL DESTINATION ${CMAKE_BINARY_DIR}
    TYPE FILE
    FILES ${BGFX_DIR}/examples/runtime/shaders/glsl/vs_cubes.bin
    ${BGFX_DIR}/examples/runtime/shaders/glsl/fs_cubes.bin)

# --- WebAssembly Configuration ---
if(DEFINED ENV{EMSDK})
    set(CMAKE_CXX_FLAGS "-s MIN_WEBGL_VERSION=2 \
        -s MAX_WEBGL_VERSION=2 \
        -s EXCEPTION_DEBUG \
        -fexceptions \
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
        -s DISABLE_EXCEPTION_CATCHING=0 \
        -Os \
        -s USE_GLFW=3 \
        --no-heap-copy \
        -s GL_ENABLE_GET_PROC_ADDRESS \
        -static \
        -s ALLOW_MEMORY_GROWTH=1 \
        -s EXIT_RUNTIME=1")

    target_link_libraries(bgfx-glfw-wasm-3dcube-template-starting-point
        ${BGFX_DIR}/.build/wasm/bin/bgfxDebug.bc
        ${BGFX_DIR}/.build/wasm/bin/bxDebug.bc
        ${BGFX_DIR}/.build/wasm/bin/bimgDebug.bc)

    file(INSTALL DESTINATION ${CMAKE_BINARY_DIR}
        TYPE FILE
        FILES ${CMAKE_SOURCE_DIR}/index.html)

# --- Native Configuration ---
else()
    if(WIN32)
        # WINDOWS CONFIGURATION
        # Assumes BGFX was built using the default genie vs2022 script
        # If you used vs2019 or similar, change 'win64_vs2022' below.
        set(BGFX_WIN_DIR ${BGFX_DIR}/.build/win64_vs2022/bin)

        target_link_libraries(bgfx-glfw-wasm-3dcube-template-starting-point
            glfw
            OpenGL::GL
            # Link static libs or import libs for Windows
            ${BGFX_WIN_DIR}/bgfxDebug.lib
            ${BGFX_WIN_DIR}/bimgDebug.lib
            ${BGFX_WIN_DIR}/bxDebug.lib
            # Required Windows System Libraries
            kernel32 user32 gdi32 psapi)
            
        # Optional: If you are linking against DLLs, un-comment below to copy them
        # file(COPY ${BGFX_WIN_DIR}/bgfxDebug.dll DESTINATION ${CMAKE_BINARY_DIR})
        
    else()
        # LINUX CONFIGURATION
        target_link_libraries(bgfx-glfw-wasm-3dcube-template-starting-point
            glfw
            OpenGL::GL
            ${BGFX_DIR}/.build/linux64_gcc/bin/libbgfx-shared-libDebug.so)
    endif()
endif()