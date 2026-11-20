<!-- managed:go-test-macos -->
## Go tests on macOS

Prefer `go test` without `-count=1` unless you need a forced rerun. `-count=1` disables the test result cache and makes every run relink a new test binary.

Don't raise `-p` just to use more cores. Fresh test binaries are scanned by macOS on first exec, and that scanner is single-threaded, so extra parallelism can make the machine worse.

Keep darwin-specific and cgo/darwin tests on macOS. Don't move those to a Linux VM or container.
<!-- /managed:go-test-macos -->
