FROM alpine:3.16
RUN apk update
RUN apk --no-cache add \
	gcc g++ musl-dev make cmake binutils linux-headers git gperf \
	openssl-dev openssl-libs-static zlib-dev zlib-static
ADD ./deps/td/ /td/
WORKDIR /td
RUN mkdir -p build
WORKDIR /td/build
RUN cmake --version
RUN cmake \
	-DCMAKE_BUILD_TYPE=Release \
	-DOPENSSL_USE_STATIC_LIBS=TRUE \
	-DZLIB_USE_STATIC_LIBS=TRUE \
	-DZLIB_LIBRARY=/lib/libz.a \
	..
RUN cmake --build . --target tdjson -- -j 2
RUN strip libtdjson.so
RUN ldd libtdjson.so
