//go:build linux && amd64
// +build linux,amd64

package llama

/*
#cgo LDFLAGS: -L${SRCDIR}/prebuilt/linux_amd64 -L${SRCDIR} -Wl,-rpath,$ORIGIN/prebuilt/linux_amd64 -lbinding -lcommon -lllama -lggml-cpu -lggml-base -lggml -lstdc++ -lm
*/
import "C"
