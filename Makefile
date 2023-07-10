UNAME := $(shell uname)
ifeq ($(UNAME), Darwin)
LIB_FILE = `uname -s | tr '[:upper:]' '[:lower:]'`-`uname -m`.dylib
ARCH = `uname -m`
endif
ifeq ($(UNAME), Linux)
LIB_FILE = `uname -s | tr '[:upper:]' '[:lower:]'`-`uname -m`.so
ARCH = `hostnamectl  |  grep 'Architecture' | awk '/Architecture:/{print $$2}'`
endif

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
	sudo sudo apt-get install make git zlib1g-dev libssl-dev gperf php-cli cmake g++ -y
endif

clean:
	clean-lib
	clean-local-n8n
	clean-prebuilds
	clean-archives

build:
	build-lib

run:
	bash run.sh

publish:
	npm publish

clean-lib:
	rm -rf deps/td/build/

clean-local-n8n:
	rm -rf ~/.n8n/nodes/

clean-prebuilds:
	rm -rf prebuilds/

clean-archives:
	rm -rf *.tar.gz

test:
	cd td
	ls

build-lib:
	rm -rf prebuilds/lib/* ; mkdir -p prebuilds/lib
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
	cd deps/td/build ; cmake --build . --target tdjson -- -j 3
ifeq ($(UNAME), Darwin)
	cd deps/td/ ; otool -L build/libtdjson.dylib
endif
ifeq ($(UNAME), Linux)
	stat -L libtdjson.so
endif
	cd ../../../ ; mkdir -p prebuilds/lib/
ifeq ($(UNAME), Darwin)
	cp deps/td/build/libtdjson.dylib prebuilds/lib/$(LIB_FILE)
	cd prebuilds && tar -czvf darwin-$(ARCH)-unknown.tar.gz lib/$(LIB_FILE) && cp darwin-$(ARCH)-unknown.tar.gz ..
	npm pack --dry-run
endif
ifeq ($(UNAME), Linux)
	cp deps/td/build/libtdjson.so prebuilds/lib/$(LIB_FILE)
	cd prebuilds && tar -czvf linux-$(ARCH)-glibc.tar.gz lib/$(LIB_FILE) && cp linux-$(ARCH)-glibc.tar.gz ..
	cd .. ; npm pack --dry-run
endif


build-lib-musl-arm64:
	rm -rf deps/td/build && mkdir -p deps/td/build
	rm -rf prebuilds/lib/* ; mkdir -p prebuilds/lib

	docker build -t build-lib -f Dockerfile-musl . ### use arm64 Dockerfile
	docker rm dummy
	docker create --name dummy build-lib

	docker cp -L dummy:/td/build/libtdjson.so prebuilds/lib/linux-aarch64.so
	cd prebuilds && tar -czvf linux-arm64-musl.tar.gz lib/linux-aarch64.so && cp linux-arm64-musl.tar.gz ..
	cd .. ; npm pack --dry-run
