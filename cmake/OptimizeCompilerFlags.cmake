set(BUILD_TYPE "Release")
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)

message(STATUS "Build type: ${BUILD_TYPE}")

## Set build type
option(NATIVE_OPTIMIZATIONS "Enable native optimizations" ON)
option(AGGRESSIVE_OPTIMIZATIONS "Enable aggresive optimizations" ON)
option(UNSAFE_OPTIMIZATIONS "Enable aggresive optimizations" OFF)

message(STATUS "Native optimizations: ${NATIVE_OPTIMIZATIONS}")
message(STATUS "Aggressive optimizations: ${AGGRESSIVE_OPTIMIZATIONS}")
message(STATUS "Unsafe optimizations: ${UNSAFE_OPTIMIZATIONS}")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mbmi")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mbmi")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mavx")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mavx")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mavx2")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mavx2")

## Set GCC optimization flags
if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    ## Aggressive optimizations
	if (AGGRESSIVE_OPTIMIZATIONS)
        ## Unsafe optimizations
		if (UNSAFE_OPTIMIZATIONS)
			set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Ofast")
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Ofast")

			set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fstrict-aliasing")
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fstrict-aliasing")

			set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -funsafe-math-optimizations")
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -funsafe-math-optimizations")

            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffast-math")
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ffast-math")
		else()
            ## Safe optimizations
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3")
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
		endif()

        ## LTO optimizations
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -flto")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -flto")

        ## Loop optimizations
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fomit-frame-pointer")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fomit-frame-pointer")

        ## Loop parallellization optimizations
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -floop-parallelize-all")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -floop-parallelize-all")

        ## Vectorization optimizations
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ftree-vectorize")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ftree-vectorize")

        ## Inline optimizations
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -finline-functions")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -finline-functions")

        ## Native optimizations
		if (NATIVE_OPTIMIZATIONS)
			set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=native")
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")
		endif()
	else ()
        ## Safe optimizations
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")

        ## LTO optimizations
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -flto")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -flto")

        ## Loop optimizations
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -funroll-loops")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -funroll-loops")

        ## Vectorization optimizations
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ftree-vectorize")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ftree-vectorize")

        ## Inline optimizations (small functions only)
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -finline-small-functions")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -finline-small-functions")

        ## Native optimizations
		if (NATIVE_OPTIMIZATIONS)
			set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=native")
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")
		endif()
	endif()

    # Some extra optimizations
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -flive-range-shrinkage")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -flive-range-shrinkage")

    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fira-algorithm=priority")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fira-algorithm=priority")

    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fira-region=all")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fira-region=all")

    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fipa-pta")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fipa-pta")

    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fipa-icf")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fipa-icf")

    # Sample test source file to test ISL support
    set(TEST_SOURCE "${CMAKE_BINARY_DIR}/test_isl_support.c")
    file(WRITE ${TEST_SOURCE} "int main() { return 0; }")

    # Try to compile with ISL-specific flags
    include(CheckCCompilerFlag)
    check_c_compiler_flag("-floop-nest-optimize" COMPILER_SUPPORTS_ISL)

    if(COMPILER_SUPPORTS_ISL)
        message(STATUS "GCC is built with ISL support.")

        # Add the ISL-dependent flags to your project
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -floop-nest-optimize -ftree-loop-linear -floop-strip-mine -floop-block")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -floop-nest-optimize -ftree-loop-linear -floop-strip-mine -floop-block")

        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fgraphite-identity")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fgraphite-identity")
    else()
        message(STATUS "GCC is not built with ISL support. Skipping certain optimizations.")
    endif()

    # More extra optimizations
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ftree-loop-if-convert -ftree-loop-distribution -ftree-loop-distribute-patterns -floop-interchange")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ftree-loop-if-convert -ftree-loop-distribution -ftree-loop-distribute-patterns -floop-interchange")

    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ftree-loop-ivcanon -fivopts")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ftree-loop-ivcanon -fivopts")

    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fweb -fuse-linker-plugin -fstdarg-opt")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fweb -fuse-linker-plugin -fstdarg-opt")

    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fweb -fuse-linker-plugin -fstdarg-opt")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fweb -fuse-linker-plugin -fstdarg-opt")
endif()

## Set Clang optimization flags
if ("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
    # Use -Ofast or -O3 optimization
    if (AGGRESSIVE_OPTIMIZATION)
        if(UNSAFE_OPTIMIZATIONS)
            set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -Ofast")
            set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -Ofast")

            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fstrict-aliasing")
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fstrict-aliasing")

			set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -funsafe-math-optimizations")
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -funsafe-math-optimizations")

            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffast-math")
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ffast-math")
        else()
            set(CMAKE_C_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")
            set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")
        endif()

        ## These optimizations depends on wether if LLVM is built with Polly support or Polly support is installed per separate
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fvectorize -fslp-vectorize -finline-all-functions")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvectorize -fslp-vectorize -finline-all-functions")
        # set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -floop-parallelize-all -floop-unroll-and-jam -fvectorize -fslp-vectorize -finline-functions")
        # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -floop-parallelize-all -floop-unroll-and-jam -fvectorize -fslp-vectorize -finline-functions")

        ## FLTO optimizations
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -funroll-loops -flto=thin")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -funroll-loops -flto=thin")

        ## These optimizations depends on wether if LLVM is built with Polly support or Polly support is installed per separate
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Xclang -load -Xclang LLVMPolly.so -mllvm -polly")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mllvm -polly-vectorizer=stripmine")
        # set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mllvm -polly")
        # set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mllvm -polly-vectorizer=stripmine")
        # set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mllvm -polly-parallel")

        ## These optimizations depends on wether if LLVM is built with Polly support or Polly support is installed per separate
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Xclang -load -Xclang LLVMPolly.so -mllvm -polly")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mllvm -polly-vectorizer=stripmine")
        # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mllvm -polly")
        # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mllvm -polly-vectorizer=stripmine")
        # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mllvm -polly-parallel")

        # Native optimization
        if (NATIVE_OPTIMIZATION)
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=native")
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")
        endif()
    else()
        set(CMAKE_C_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")
        set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")

        ## These optimizations depends on wether if LLVM is built with Polly support or Polly support is installed per separate
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fvectorize -fslp-vectorize -finline-functions")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvectorize -fslp-vectorize -finline-functions")
        # set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -floop-parallelize-all -floop-unroll-and-jam -fvectorize -fslp-vectorize -finline-functions")
        # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -floop-parallelize-all -floop-unroll-and-jam -fvectorize -fslp-vectorize -finline-functions")

        ## FLTO optimizations
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -funroll-loops -flto=thin")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -funroll-loops -flto=thin")

        ## These optimizations depends on wether if LLVM is built with Polly support or Polly support is installed per separate
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Xclang -load -Xclang LLVMPolly.so -mllvm -polly")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mllvm -polly-vectorizer=stripmine")
        # set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mllvm -polly")
        # set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mllvm -polly-vectorizer=stripmine")
        # set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mllvm -polly-parallel")

        ## These optimizations depends on wether if LLVM is built with Polly support or Polly support is installed per separate
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Xclang -load -Xclang LLVMPolly.so -mllvm -polly")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mllvm -polly-vectorizer=stripmine")
        # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mllvm -polly")
        # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mllvm -polly-vectorizer=stripmine")
        # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mllvm -polly-parallel")

        # Native optimization
        if (NATIVE_OPTIMIZATION)
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=native")
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")
        endif()
    endif()

    if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/default.profraw")
        execute_process(COMMAND llvm-profdata merge -o default.profdata default.profraw)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fprofile-instr-use=default.profdata")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-instr-use=default.profdata")
    endif()
endif()