#!/bin/bash

NDKCROSS=/opt/android-sdk/ndk/21.2.6472646/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-
NDKCC=/opt/android-sdk/ndk/21.2.6472646/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi16-clang
SYSROOTX=/opt/android-sdk/ndk/21.2.6472646/toolchains/llvm/prebuilt/linux-x86_64/sysroot
make HOST_CC="gcc -m32" CROSS=$NDKCROSS \
     STATIC_CC=$NDKCC DYNAMIC_CC="$NDKCC -fPIC" \
     TARGET_LD=$NDKCC \
     TARGET_CFLAGS="-I${SYSROOTX}/usr/include -I${SYSROOTX}/usr/include/arm-linux-androideabi"



