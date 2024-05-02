#ifndef _LJ_INTRIN_H_
#define _LJ_INTRIN_H_

#include "lj_arch.h"

#if LUAJIT_TARGET == LUAJIT_ARCH_X64 /***** x86_64 AVX2/BMI2 intrinsics *****/

#if LJ_TARGET_WINDOWS
#include <immintrin.h>
#else
#include <x86intrin.h>
#endif

/* # of contiguous low 0 bits */
#define tzcount32(x) (unsigned)_tzcnt_u32(x)
#define tzcount64(x) (unsigned)_tzcnt_u64(x)

/* x & (x - 1) */
#define reset_lowest32(x) (uint32_t)_blsr_u32(x)
#define reset_lowest64(x) (uint64_t)_blsr_u64(x)

/* x ^ (x - 1) */
#define mask_lowest32(x) (uint32_t)_blsmsk_u32(x)
#define mask_lowest64(x) (uint64_t)_blsmsk_u64(x)

/* x & ~y */
#define and_not32(x, y) (uint32_t)_andn_u32(y, x)
#define and_not64(x, y) (uint64_t)_andn_u64(y, x)

#define popcount64(x) (unsigned)_mm_popcnt_u64(x)

/* 256 bit SIMD */
#define LJ_SIMD_256 1
#define I256_ZERO(o) o = _mm256_setzero_si256()
#define I256_ONES(o) o = _mm256_cmpeq_epi64(_mm256_setzero_si256(), _mm256_setzero_si256()) // vpxor a, a, a; vpcmpeqq a, a, a sets all bits to 1
#define I256_BCAST_8(o, v) o = _mm256_set1_epi8((char)v)
#define I256_BCAST_32(o, v) o = _mm256_set1_epi32((int)v)
#define I256_NEQ_64_MASK(x, y) ((uint64_t)_mm256_movemask_pd(_mm256_castsi256_pd(_mm256_cmpeq_epi64(x, y))) ^ 0xF)
#define I256_EQ_64_MASK(x, y) (uint64_t)_mm256_movemask_pd(_mm256_castsi256_pd(_mm256_cmpeq_epi64(x, y)))
#define I256_EQ_32_MASK(x, y) (uint64_t)_mm256_movemask_ps(_mm256_castsi256_ps(_mm256_cmpeq_epi32(x, y)))
#define I256_AND(o, x, y) o = _mm256_and_si256(x, y)
#define I256_XOR(o, x, y) o = _mm256_xor_si256(x, y)
#define I256_OR(o, x, y) o = _mm256_or_si256(x, y)
#define I256_ANDNOT(o, x, y) o = _mm256_andnot_si256(y, x) /* x & ~y */
#define I256_SHL_64(o, x, n) o = _mm256_slli_epi64(x, n)
#define I256_SHUFFLE_64(o, x, mask) o = _mm256_castpd_si256(_mm256_permute_pd(_mm256_castsi256_pd(x), mask))
#define I256_LOADA(o, ptr) o = _mm256_load_si256((__m256i *)(ptr))
#define I256_STOREA(ptr, v) _mm256_store_si256((__m256i *)(ptr), v)
#define I256_EXTRACT(x, n) (uint64_t)_mm256_extract_epi64(x, n)

/* Generic platform agnostic SIMD operators */
#define _simd_bits 256
typedef __m256i _simd_default_type;

#define _simd_zero I256_ZERO
#define _simd_ones I256_ONES
#define _simd_bcast8 I256_BCAST_8
#define _simd_bcast32 I256_BCAST_32
#define _simd_neq64_mask I256_NEQ_64_MASK
#define _simd_eq32_mask I256_EQ_32_MASK
#define _simd_eq64_mask I256_EQ_64_MASK
#define _simd_and I256_AND
#define _simd_xor I256_XOR
#define _simd_or I256_OR
#define _simd_andnot I256_ANDNOT
#define _simd_shl64 I256_SHL_64
#define _simd_shuffle64 I256_SHUFFLE_64
#define _simd_loada I256_LOADA
#define _simd_storea I256_STOREA
#define _simd_extract I256_EXTRACT

#elif LUAJIT_TARGET == LUAJIT_ARCH_ARM64 /***** ARM Neon intrinsics *****/

#include <arm_neon.h>
#include "libpopcnt.h"

/* # of contiguous low 0 bits */
#define tzcount32(x) (31 - __builtin_clz(x))
#define tzcount64(x) (63 - __builtin_clzll(x))

/* x & (x - 1) */
#define reset_lowest32(x) (vget_lane_u32(vbic_u32(vdup_n_u32(x), vsub_u32(vdup_n_u32(x), vdup_n_u32(1))), 0))
#define reset_lowest64(x) (vget_lane_u64(vbic_u64(vdup_n_u64(x), vsub_u64(vdup_n_u64(x), vdup_n_u64(1))), 0))

/* x ^ (x - 1) */
#define mask_lowest32(x) ((uint32_t)veor_u32(vdup_n_u32(x), vdup_n_u32(x - 1)))
#define mask_lowest64(x) ((uint64_t)veor_u64(vdup_n_u64(x), vdup_n_u64(x - 1)))

/* x & ~y */
#define and_not32(x, y) (vget_lane_u32(vbic_u32(vdup_n_u32(y), vdup_n_u32(x)), 0))
#define and_not64(x, y) (vget_lane_u64(vbic_u64(vdup_n_u64(y), vdup_n_u64(x)), 0))

static inline unsigned _popcount64(uint64_t x) {
    return popcnt(&x, sizeof(x));
}
#define popcount64(x) _popcount64(x)

/* 128 SIMD */
#define LJ_SIMD_128 1
#define NEON128_ZERO(o) (o = vdupq_n_u32(0))
#define NEON128_ONES(o) (o = vmovq_n_u32(0xFFFFFFFF))
#define NEON128_BCAST_8(o, v) (o = vdupq_n_u8(v))
#define NEON128_BCAST_32(o, v) (o = vdupq_n_u32(v))
#define NEON128_HELPER_MOVEMASK_U64(v) (uint64_t)((vgetq_lane_u64(v, 0) & 1) | ((vgetq_lane_u64(v, 1) & 1) << 1)) // Define the equivalent of _mm256_movemask_pd for ARM Neon for 64-bit comparisons
#define NEON128_HELPER_MOVEMASK_U32(v) (uint32_t)((vgetq_lane_u32(v, 0) & 1) | ((vgetq_lane_u32(v, 1) & 1) << 1) | ((vgetq_lane_u32(v, 2) & 1) << 2) | ((vgetq_lane_u32(v, 3) & 1) << 3)) // Same for 32-bit comparisons
#define NEON128_NEQ_64_MASK(v1, v2) (~(NEON128_HELPER_MOVEMASK_U64(vceqq_u64(v1, v2))) & 0x3)  // Assuming 2 elements, mask with 0x3
#define NEON128_EQ_32_MASK(v1, v2) (NEON128_HELPER_MOVEMASK_U32(vceqq_u32(v1, v2)))
#define NEON128_EQ_64_MASK(v1, v2) (NEON128_HELPER_MOVEMASK_U64(vceqq_u64(v1, v2)))
#define NEON128_AND(o, v1, v2) (o = vandq_u32(v1, v2))
#define NEON128_XOR(o, v1, v2) (o = veorq_u32(v1, v2))
#define NEON128_OR(o, v1, v2) (o = vorrq_u32(v1, v2))
#define NEON128_ANDNOT(o, v1, v2) (o = vbicq_u32(v2, v1))
#define NEON128_SHL_64(o, v, n) (o = vshlq_n_u64(v, n))
#define NEON128_SHUFFLE_64(o, v, mask) (o = vextq_u64(v, v, mask))
#define NEON128_LOADA(o, ptr) (o = vld1q_u32((const uint32_t*)(ptr)))
#define NEON128_STOREA(ptr, v) (vst1q_u32((uint32_t*)(ptr), v))
#define NEON128_EXTRACT(v, n) (vgetq_lane_u64(v, n))
#define NEON128_COMBINE(t, x) (t = vcombine_u64(vextq_u64(t, 1), vextq_u64(x, 0)))

/* Generic platform agnostic SIMD operators */
#define _simd_bits 128
typedef uint32x4_t _simd_default_type; // or int32x4_t

#define _simd_zero NEON128_ZERO
#define _simd_ones NEON128_ONES
#define _simd_bcast8 NEON128_BCAST_8
#define _simd_bcast32 NEON128_BCAST_32
#define _simd_neq64_mask NEON128_NEQ_64_MASK
#define _simd_eq32_mask NEON128_EQ_32_MASK
#define _simd_eq64_mask NEON128_EQ_64_MASK
#define _simd_and NEON128_AND
#define _simd_xor NEON128_XOR
#define _simd_or NEON128_OR
#define _simd_andnot NEON128_ANDNOT
#define _simd_shl64 NEON128_SHL_64
#define _simd_shuffle64 NEON128_SHUFFLE_64
#define _simd_loada NEON128_LOADA
#define _simd_storea NEON128_STOREA
#define _simd_extract NEON128_EXTRACT
#define _simd_combine NEON128_COMBINE

#else /***** Fallback scalar implementations *****/

static inline unsigned _tzcount32(uint32_t x) {
    unsigned count = 0;
    while (!(x & 1)) {
        x >>= 1;
        count++;
    }
    return count;
}

static inline unsigned _tzcount64(uint64_t x) {
    unsigned count = 0;
    while (!(x & 1)) {
        x >>= 1;
        count++;
    }
    return count;
}

/* # of contiguous low 0 bits */
#define tzcount32(x) _tzcount32(x)
#define tzcount64(x) _tzcount64(x)

/* x & (x - 1) */
#define reset_lowest32(x) ((uint32_t)(x) & ((uint32_t)(x) - 1))
#define reset_lowest64(x) ((uint64_t)(x) & ((uint64_t)(x) - 1))

/* x ^ (x - 1) */
#define mask_lowest32(x) ((uint32_t)((x & -x) ^ ((x - 1) & -x)))
#define mask_lowest64(x) ((uint64_t)((x & -x) ^ ((x - 1) & -x)))

/* x & ~y */
#define and_not32(x, y) ((uint32_t)(x) & ~(uint32_t)(y))
#define and_not64(x, y) ((uint64_t)(x) & ~(uint64_t)(y))

unsigned _popcount64(uint64_t x) {
    x = x - ((x >> 1) & 0x5555555555555555ULL);
    x = (x & 0x3333333333333333ULL) + ((x >> 2) & 0x3333333333333333ULL);
    x = (x + (x >> 4)) & 0x0F0F0F0F0F0F0F0FULL;
    x = x + (x >> 8);
    x = x + (x >> 16);
    x = x + (x >> 32);
    return x & 0xFF;
}

#define popcount64(x) _popcount64(x)

#define _simd_bits 64
typedef uint64_t _simd_default_type;

// Basic operations using uint64_t
#define _simd_zero(o) (o = 0)
#define _simd_ones(o) (o = ~((uint64_t)0))
#define _simd_bcast8(o, v) (o = (uint64_t)(0x0101010101010101ULL * (uint8_t)(v)))
#define _simd_bcast32(o, v) (o = (uint64_t)(v) | ((uint64_t)(v) << 32))
#define _simd_and(o, x, y) (o = x & y)
#define _simd_xor(o, x, y) (o = x ^ y)
#define _simd_or(o, x, y) (o = x | y)
#define _simd_andnot(o, x, y) (o = x & ~y)
#define _simd_shl64(o, x, n) (o = x << n)
#define _simd_extract(x, n) (x)  // n is ignored for scalar, returns x itself

// Emulate comparison masks
#define _simd_eq64_mask(x, y) ((x == y) ? 1 : 0)
#define _simd_eq32_mask(x, y) (((x & 0xFFFFFFFF) == (y & 0xFFFFFFFF) ? 1 : 0) | ((x >> 32 == y >> 32) ? 2 : 0))

// Load and Store are direct memory operations
#define _simd_loada(o, ptr) (o = *(const uint64_t *)(ptr))
#define _simd_storea(ptr, v) (*(uint64_t *)(ptr) = v)

// Since there's no 64-bit NEQ mask directly, invert the EQ mask for a single 64-bit comparison
#define _simd_neq64_mask(x, y) (~_simd_eq64_mask(x, y) & 0x1)

#endif

#endif
