#!/bin/bash

NDKCROSS=/opt/android-sdk/ndk/21.2.6472646/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-
NDKCC=/opt/android-sdk/ndk/21.2.6472646/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang
SYSROOTX=/opt/android-sdk/ndk/21.2.6472646/toolchains/llvm/prebuilt/linux-x86_64/sysroot
make HOST_CC="gcc -m64" CROSS=$NDKCROSS \
     STATIC_CC=$NDKCC DYNAMIC_CC="$NDKCC -fPIC" \
     TARGET_LD=$NDKCC \
     TARGET_CFLAGS="-I${SYSROOTX}/usr/include -I${SYSROOTX}/usr/include/aarch64-linux-android"



