# tdlib-node-pre-gyp

Intention of this plugin is to distribute binary prebuilds of `tdlib` to environments, where compilation is not desired
or not possible and to support following architectuers:

 - linux-x64-glibc
 - linux-x64-musl
 - linux-arm64-glibc
 - linux-arm64-musl
 - macos-arm64
 - macos-x64

## Building

To build native `tdlib` module, use:
```
	make build-lib
```
