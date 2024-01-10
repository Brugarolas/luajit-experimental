#!/bin/bash

# Set GCC as the compiler
export CC=gcc
export CXX=g++

# Create a build directory
mkdir -p build
cd build

# Configure the project with CMake using Ninja
cmake -G Ninja ..

# Build the project
ninja

# Return to the original directory
cd ..
