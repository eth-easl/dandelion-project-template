cmake_minimum_required(VERSION 3.16)
project(dandelion_project C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

# Emit compile_commands.json (gitignored) for clangd / editors.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Put all function binaries in <build_dir>/bin.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# ---------------------------------------------------------------------------
#  The functions only build with the dsdk compiler (target triple
#  <arch>-unknown-dandelion), see scripts/build_dandelion.sh.
# ---------------------------------------------------------------------------
execute_process(
  COMMAND ${CMAKE_CXX_COMPILER} -dumpmachine
  OUTPUT_VARIABLE COMPILER_TARGET_TRIPLE
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
if(NOT COMPILER_TARGET_TRIPLE MATCHES "-dandelion$")
  message(FATAL_ERROR "Expected the Dandelion SDK compiler, got target '${COMPILER_TARGET_TRIPLE}'. "
                      "Build with scripts/build_dandelion.sh.")
endif()
message(STATUS "Compiler target: ${COMPILER_TARGET_TRIPLE}")

# The Dandelion libc headers use the C99 keyword 'restrict' as a parameter
# name, which is invalid in C++ (e.g. when including <semaphore.h>). Map it
# to Clang's __restrict qualifier.
add_compile_definitions(restrict=__restrict)

# Transparent object-file cache (no-op if ccache isn't installed).
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
  set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
  set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
endif()

# Drop unreferenced code/data to keep the function binaries small.
add_compile_options(-ffunction-sections -fdata-sections)
add_link_options("-Wl,--gc-sections")

# ---------------------------------------------------------------------------
#  dandelion_function(<name> <sources>...)
#   Builds one function binary from the given sources.
# ---------------------------------------------------------------------------
function(dandelion_function name)
  add_executable(${name} ${ARGN})
  target_include_directories(${name} PRIVATE ${CMAKE_SOURCE_DIR}/src)
endfunction()

# ---------------------------------------------------------------------------
#  Functions
# ---------------------------------------------------------------------------
dandelion_function(example src/main.cpp)
