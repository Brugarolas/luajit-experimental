#!/bin/bash

# Set the path to your MinGW-w64 installation
MINGW_PATH="/path/to/mingw-w64"

# Find Clang
CLANG=$(which clang)
CLANGXX=$(which clang++)

if [ -z "$CLANG" ] || [ -z "$CLANGXX" ]; then
    echo "Clang not found."
    exit 1
fi

# Set Clang and MinGW for cross-compilation
export CC=$CLANG
export CXX=$CLANGXX
export CMAKE_C_COMPILER_TARGET=x86_64-w64-mingw32
export CMAKE_CXX_COMPILER_TARGET=x86_64-w64-mingw32
export CMAKE_SYSROOT=$MINGW_PATH

# Create a build directory
mkdir -p build-windows
cd build-windows

# Configure the project with CMake using Ninja for Windows cross-compilation
cmake -G Ninja -DCMAKE_SYSTEM_NAME=Windows ..

# Build the project
ninja

# Return to the original directory
cd ..
