#!/bin/bash

# Find GCC
GCC=$(which gcc)
GXX=$(which g++)

if [ -z "$GCC" ] || [ -z "$GXX" ]; then
    echo "Clang not found."
    exit 1
fi

# Set GCC as the compiler
export CC=$GCC
export CXX=$GXXss

# Create a build directory
mkdir -p build
cd build

# Configure the project with CMake using Ninja
cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release -USE_FORCE_GCC=ON

# Build the project
ninja

# Return to the original directory
cd ..
