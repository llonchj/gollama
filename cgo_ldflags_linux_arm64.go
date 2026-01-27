//go:build linux && arm64
// +build linux,arm64

package llama

/*
#cgo LDFLAGS: -L${SRCDIR}/prebuilt/linux_arm64 -L${SRCDIR} -Wl,-rpath,$ORIGIN/prebuilt/linux_arm64 -lbinding -lcommon -lllama -lggml-cpu -lggml-base -lggml -lstdc++ -lm
*/
import "C"
