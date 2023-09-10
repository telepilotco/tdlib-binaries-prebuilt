UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
LIB_FILE = libtdjson.dylib
ARCH ?= $(shell uname -m)
LIBC ?= unknown
endif

ifeq ($(UNAME), Linux)
LIB_FILE = libtdjson.so
ARCH ?= $(shell uname -m)
LIBC ?= glibc
endif

ifeq ($(ARCH), x86_64)
ARCH ?= x64
endif

DOCKER_IMAGE_GLIBC = ubuntu:20.04
DOCKER_IMAGE_MUSL = alpine:3.16

DOCKER_PLATFORM_ARM64 = arm64
DOCKER_PLATFORM_X64 = amd64

TGZ_NAME = $(shell uname | tr '[:upper:]' '[:lower:]')-$(ARCH)-$(LIBC).tar.gz

.ONESHELL:

init:
	pnpm install
ifeq ($(UNAME), Darwin)
	curl -sL https://github.com/nodejs/node-gyp/raw/main/macOS_Catalina_acid_test.sh | bash
	xcode-select --install
	brew install gperf openssl zlib #macos-only
endif
ifeq ($(UNAME), Linux)
#see https://tdlib.github.io/deps/td/build.html?language=JavaScript
	sudo apt-get update
	sudo apt-get install make git zlib1g-dev libssl-dev gperf php-cli cmake g++ -y
	sudo apt-get install npm docker.io -y
endif


clean: clean-lib clean-prebuilds clean-archives

build:
	build-lib

run:
	bash run.sh

publish:
	npm publish

clean-lib:
	rm -rf deps/td/build/

clean-prebuilds:
	rm -rf prebuilds/

clean-archives:
	rm -rf *.tar.gz
	rm -rf prebuilds/*.tar.gz

build-lib-native: build-lib-native-compile build-lib-archive

build-lib-docker-linux-arm64-glibc:
	mkdir -p prebuilds/lib
	docker run \
	 -v `pwd`:/rep \
	 --platform linux/$(DOCKER_PLATFORM_ARM64) \
	 $(DOCKER_IMAGE_GLIBC) \
	 sh /rep/prebuilt-tdlib-docker.sh

build-lib-docker-linux-arm64-musl:
	mkdir -p prebuilds/lib
	docker run \
	 -v `pwd`:/rep \
	 --platform linux/$(DOCKER_PLATFORM_ARM64) \
	 $(DOCKER_IMAGE_MUSL) \
	 sh /rep/prebuilt-tdlib-docker.sh

build-lib-docker-linux-x64-glibc:
	mkdir -p prebuilds/lib
	docker run \
	 -v `pwd`:/rep \
	 --platform linux/$(DOCKER_PLATFORM_X64) \
	 $(DOCKER_IMAGE_GLIBC) \
	 sh /rep/prebuilt-tdlib-docker.sh

build-lib-docker-linux-x64-musl:
	mkdir -p prebuilds/lib
	docker run \
	 -v `pwd`:/rep \
	 --platform linux/$(DOCKER_PLATFORM_X64) \
	 $(DOCKER_IMAGE_MUSL) \
	 sh /rep/prebuilt-tdlib-docker.sh


build-lib-native-compile:
	mkdir -p prebuilds/lib
	rm -rf deps/td/build
	mkdir -p deps/td/build
ifeq ($(UNAME), Linux)
	cd deps/td/build ; cmake -DCMAKE_BUILD_TYPE=Release -DOPENSSL_USE_STATIC_LIBS=TRUE -DZLIB_USE_STATIC_LIBS=TRUE ..
endif
ifeq ($(UNAME), Darwin)
	cd deps/td/build ; cmake -DCMAKE_BUILD_TYPE=Release \
	 -DOPENSSL_ROOT_DIR=/opt/homebrew/opt/openssl@1.1 \
	 -DZLIB_INCLUDE_DIR=/opt/homebrew/opt/zlib/include \
	 -DZLIB_LIBRARY=/opt/homebrew/opt/zlib/lib/libz.a \
	 -DOPENSSL_USE_STATIC_LIBS=TRUE -DZLIB_USE_STATIC_LIBS=TRUE \
	 ..
endif
	cd deps/td/build ; cmake --build . --target tdjson -- -j 32
ifeq ($(UNAME), Darwin)
	cd deps/td/ ; otool -L build/libtdjson.dylib
endif
ifeq ($(UNAME), Linux)
	stat -L libtdjson.so
endif
	cp deps/td/build/$(LIB_FILE) prebuilds/lib/$(LIB_FILE)

build-lib-archive:
	cd prebuilds && tar -czvf $(TGZ_NAME) lib/* && cp $(TGZ_NAME) ..
