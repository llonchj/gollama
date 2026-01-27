//go:build darwin && amd64
// +build darwin,amd64

package llama

/*
#cgo LDFLAGS: -L${SRCDIR}/prebuilt/darwin_amd64 -L${SRCDIR} -Wl,-rpath,@loader_path/prebuilt/darwin_amd64 -lbinding -lcommon -lllama -lggml-cpu -lggml-base -lggml -lstdc++ -lm
*/
import "C"
