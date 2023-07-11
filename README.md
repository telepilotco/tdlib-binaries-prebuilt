[![Build TDLib binaries](https://github.com/telepilotco/tdlib-binaries-prebuilt/actions/workflows/build-binaries.yml/badge.svg)](https://github.com/telepilotco/tdlib-binaries-prebuilt/actions/workflows/build-binaries.yml)

# tdlib-node-pre-gyp

Intention of this plugin is to distribute binary prebuilds of `tdlib` to environments, where compilation is not desired
or not possible and to support following architectuers:

 - linux-x64-glibc
 - linux-x64-musl (x86-64/x86_64 -> x64)
 + linux-arm64-glibc (aarch64 -> arm64)
 + linux-arm64-musl (aarch64 -> arm64)
 + macos-arm64
 - macos-x64

## Building

To build native `tdlib` module, use:
```
	make build-lib
```
