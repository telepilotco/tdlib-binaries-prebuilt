if ! [ -x "$(command -v apk)" ]; then
  export TZ=Europe/Berlin
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
  apt-get update
  apt-get install -y -q \
    gcc g++ musl-dev make cmake binutils git gperf \
    libssl-dev zlib1g-dev
else
  apk update
  apk --no-cache add \
    gcc g++ musl-dev make cmake binutils linux-headers git gperf \
    openssl openssl-dev openssl-libs-static zlib-dev zlib-static
fi

mkdir -p /rep/deps/td/build
cd /rep/deps/td/
git config --global --add safe.directory /rep/deps/td
git rev-parse HEAD
cd build
# Currently, cmake in this image should be 3.22.2
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DOPENSSL_USE_STATIC_LIBS=TRUE \
  -DZLIB_USE_STATIC_LIBS=TRUE \
  ..
cmake --build . --target tdjson -- -j 2
strip libtdjson.so
cd ..
cp -L build/libtdjson.so ../../prebuilds/lib/libtdjson.so

cd ..
touch ../prebuilds/lib/info.txt
git rev-parse HEAD >> ../prebuilds/lib/info.txt
cd ../prebuilds/lib

ldd libtdjson.so

sha256sum libtdjson.so >> info.txt
cmake --version >> info.txt
gcc --version | grep -i gcc >> info.txt
getconf GNU_LIBC_VERSION 2>&1 >> info.txt || true; ldd --version 2>&1 >> info.txt || true
openssl version >> info.txt
sed -n 's/#define ZLIB_VERSION "\([^"]*\)"/zlib version: \1/p' /usr/include/zlib.h >> info.txt
