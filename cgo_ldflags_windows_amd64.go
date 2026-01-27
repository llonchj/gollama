//go:build windows && amd64
// +build windows,amd64

package llama

/*
#cgo LDFLAGS: -L${SRCDIR}/prebuilt/windows_amd64 -L${SRCDIR} -lbinding -lcommon -lllama -lggml-cpu -lggml-base -lggml -lstdc++ -lm
*/
import "C"
