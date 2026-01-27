Prebuilt llama.cpp libraries live in platform folders:

- linux_amd64
- linux_arm64
- darwin_amd64
- darwin_arm64
- windows_amd64

Each folder should contain:

- libbinding.a
- libcommon.a
- libllama (shared library)
- libggml, libggml-base, libggml-cpu (shared libraries)

On macOS, include the .dylib variants. On Linux, include .so variants.
On Windows, include the .dll files plus any import libraries produced by your toolchain.

Use scripts/build-prebuilt.sh to build and stage the current platform's artifacts.
