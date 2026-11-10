# Dandelion Project Template

A starting point for writing C/C++ functions for the [Dandelion](https://github.com/eth-easl/dandelion) platform. The functions are cross-compiled with the [Dandelion SDK](https://github.com/eth-easl/dandelionSDK) (dsdk) compiler.

## Layout

- `src/main.cpp`: the example function. It reads its sets through the Dandelion runtime API (`dandelion/runtime.h`), upper-cases every input item and writes the result to output set 0.
- `CMakeLists.txt` declares the functions and checks that the dsdk compiler is used.
- `scripts/setup_dsdk.sh` downloads and installs the dsdk compiler.
- `scripts/build_dandelion.sh` cross-compiles the project for Dandelion.

## Building for Dandelion

Requirements: `clang`, `cmake`, `wget`, and optionally `ninja`.

```bash
# fetches the dsdk compiler if -c is not given (all flags are optional)
./scripts/build_dandelion.sh -b <build_dir> -r <Debug|Release> -c <dsdk_compiler_path> \
    -p <debug|kvm|mmu_linux> -v <latest|experimental> -t <cpu_arch>
```

Binaries land in `<build_dir>/bin/` (default `build/bin/`). If you already have a dsdk compiler, for example from another project, pass it with `-c` to skip the download. You can also install one on its own:

```bash
./scripts/setup_dsdk.sh -i <install_dir> -p kvm -v latest
```

## Adding a function

1. Write a source file with a `main()` that reads its inputs with `dandelion_get_input` and adds outputs with `dandelion_add_output` (see `src/main.cpp`).
2. Register it in `CMakeLists.txt`: `dandelion_function(my_function src/my_function.cpp)`.
3. Register it with Dandelion, listing its input and output set names in order. Set index `N` in the code is the `N`-th entry of `inputSets` / `outputSets`.

## Notes

- A non-zero exit code from `main()` marks the invocation as failed.
- Output buffers (data and ident) passed to `dandelion_add_output` must stay alive until the function exits, so allocate them on the heap and don't free them.
- The Dandelion libc has no thread-local storage (`__thread` is defined away).
