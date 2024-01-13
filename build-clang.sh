#!/bin/bash

# Find Clang
CLANG=$(which clang)
CLANGXX=$(which clang++)

if [ -z "$CLANG" ] || [ -z "$CLANGXX" ]; then
    echo "Clang not found."
    exit 1
fi

# Set Clang as the compiler
export CC=$CLANG
export CXX=$CLANGXX

# Create a build directory
mkdir -p build
cd build

# Configure the project with CMake using Ninja
cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release -USE_FORCE_CLANG=ON

# Build the project
ninja

# Return to the original directory
cd ..
