#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f "llama.cpp/CMakeLists.txt" ]]; then
  echo "llama.cpp directory missing. Re-clone the repository." >&2
  exit 1
fi

if [[ -f "llama.cpp/third_party/nlohmann/json.hpp" ]]; then
  mkdir -p llama.cpp/vendor/nlohmann
  cp -f llama.cpp/third_party/nlohmann/json.hpp llama.cpp/third_party/nlohmann/json_fwd.hpp llama.cpp/vendor/nlohmann/
fi

GOOS="$(go env GOOS)"
GOARCH="$(go env GOARCH)"
TARGET="${GOOS}_${GOARCH}"
OUT_DIR="prebuilt/${TARGET}"

mkdir -p "$OUT_DIR"
find "$OUT_DIR" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec rm -rf {} +

make libbinding.a

cp -f libbinding.a "$OUT_DIR/"
cp -f libcommon.a "$OUT_DIR/"

case "$GOOS" in
  linux)
    if [[ -d build/bin ]]; then
      cp -a build/bin/libllama.so* build/bin/libggml*.so* "$OUT_DIR/"
    else
      cp -f libllama.so libggml.so libggml-base.so libggml-cpu.so "$OUT_DIR/"
    fi
    if [[ -f build/bin/libggml-cuda.so ]]; then
      cp -a build/bin/libggml-cuda.so* "$OUT_DIR/"
    elif [[ -f libggml-cuda.so ]]; then
      cp -f libggml-cuda.so "$OUT_DIR/"
    fi
    ;;
  darwin)
    if [[ -d build/bin ]]; then
      cp -a build/bin/libllama.dylib* build/bin/libggml*.dylib* "$OUT_DIR/"
    else
      cp -f libllama.dylib libggml.dylib libggml-base.dylib libggml-cpu.dylib "$OUT_DIR/"
    fi
    if [[ -f libggml-metal.dylib ]]; then
      cp -f libggml-metal.dylib "$OUT_DIR/"
    fi
    if [[ -f ggml-metal.metal ]]; then
      cp -f ggml-metal.metal "$OUT_DIR/"
    fi
    ;;
  windows)
    # Assume MinGW-style outputs (.dll + import libs)
    if compgen -G "*.dll" > /dev/null; then
      cp -f ./*.dll "$OUT_DIR/"
    fi
    if compgen -G "*.a" > /dev/null; then
      cp -f ./*.a "$OUT_DIR/"
    fi
    ;;
  *)
    echo "Unsupported GOOS: $GOOS" >&2
    exit 1
    ;;
esac

echo "Prebuilt artifacts staged in $OUT_DIR"
