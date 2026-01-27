//go:build darwin && arm64
// +build darwin,arm64

package llama

/*
#cgo LDFLAGS: -L${SRCDIR}/prebuilt/darwin_arm64 -L${SRCDIR} -Wl,-rpath,@loader_path/prebuilt/darwin_arm64 -lbinding -lcommon -lllama -lggml-cpu -lggml-base -lggml -lstdc++ -lm
*/
import "C"
