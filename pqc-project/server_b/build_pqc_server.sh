#!/bin/bash
#
# build_pqc_server.sh
#
# This script uses the "pre-compile dependencies" method. It first builds
# and installs all dependencies into a local directory, then builds Nginx
# against those pre-compiled libraries. This is the most robust method.
#

set -e # Exit immediately if any command fails

# --- Configuration ---
MAKE_CMD="make"
CMAKE_CMD="cmake"

LIBOQS_GIT_URL="https://github.com/open-quantum-safe/liboqs.git"
LIBOQS_GIT_TAG="0.10.0"
OQSPROVIDER_GIT_URL="https://github.com/open-quantum-safe/oqs-provider.git"
OQSPROVIDER_GIT_TAG="0.6.0"
OPENSSL_GIT_URL="https://github.com/openssl/openssl.git"
OPENSSL_GIT_TAG="openssl-3.2.0"
NGINX_VERSION="1.25.3"
NGINX_URL="https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
PCRE_VERSION="8.45"
PCRE_URL="https://sourceforge.net/projects/pcre/files/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.gz"
ZLIB_VERSION="1.3.1"
ZLIB_URL="https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz"

# --- Directories ---
SRC_DIR="$(pwd)/src"
BUILD_DIR="$(pwd)/build"
INSTALL_DIR="$(pwd)/install"
NGINX_INSTALL_DIR="$(pwd)/nginx"

mkdir -p ${SRC_DIR} ${BUILD_DIR}
mkdir -p ${INSTALL_DIR}/include ${INSTALL_DIR}/lib ${INSTALL_DIR}/bin

echo "=================================================="
echo "Starting PQC Server (Server B) Build Process"
echo "=================================================="

# --- 1. Download Sources ---
echo ">>> Step 1: Downloading all source code..."
cd ${SRC_DIR}
if [ ! -d "liboqs" ]; then git clone --depth 1 --branch ${LIBOQS_GIT_TAG} ${LIBOQS_GIT_URL}; fi
if [ ! -d "oqs-provider" ]; then git clone --depth 1 --branch ${OQSPROVIDER_GIT_TAG} ${OQSPROVIDER_GIT_URL}; fi
if [ ! -d "openssl" ]; then git clone --depth 1 --branch ${OPENSSL_GIT_TAG} ${OPENSSL_GIT_URL}; fi
if [ ! -f "nginx-${NGINX_VERSION}.tar.gz" ]; then wget ${NGINX_URL}; fi
if [ ! -f "pcre-${PCRE_VERSION}.tar.gz" ]; then wget -O pcre-${PCRE_VERSION}.tar.gz ${PCRE_URL}; fi
if [ ! -f "zlib-${ZLIB_VERSION}.tar.gz" ]; then wget ${ZLIB_URL}; fi
echo ">>> Source code downloaded successfully."

# --- 2. Build and Install Zlib ---
echo ">>> Step 2: Building and installing zlib..."
cd ${BUILD_DIR}
rm -rf zlib && mkdir zlib && cd zlib
tar -xzvf ${SRC_DIR}/zlib-${ZLIB_VERSION}.tar.gz --strip-components=1
${MAKE_CMD} -f win32/Makefile.gcc
cp zlib.h zconf.h ${INSTALL_DIR}/include
cp zlib1.dll ${INSTALL_DIR}/bin
cp libz.a ${INSTALL_DIR}/lib
cp libz.dll.a ${INSTALL_DIR}/lib
echo ">>> zlib installed successfully."

# --- 3. Build and Install PCRE ---
echo ">>> Step 3: Building and installing pcre..."
cd ${BUILD_DIR}
rm -rf pcre && mkdir pcre && cd pcre
tar -xzvf ${SRC_DIR}/pcre-${PCRE_VERSION}.tar.gz --strip-components=1
./configure --prefix=${INSTALL_DIR} --enable-static --disable-shared --disable-dependency-tracking
${MAKE_CMD} -j$(nproc) && ${MAKE_CMD} install
echo ">>> pcre installed successfully."

# --- 4. Build and Install OpenSSL (Standard) ---
echo ">>> Step 4: Building and installing OpenSSL..."
cd ${BUILD_DIR}
rm -rf openssl && mkdir -p openssl && cd openssl
${SRC_DIR}/openssl/Configure mingw64 --prefix=${INSTALL_DIR} --openssldir=${INSTALL_DIR} no-shared
${MAKE_CMD} -j$(nproc) && ${MAKE_CMD} install_sw
echo ">>> OpenSSL installed successfully."

# --- 5. Build and Install liboqs ---
echo ">>> Step 5: Building and installing liboqs..."
cd ${BUILD_DIR}
rm -rf liboqs && mkdir -p liboqs && cd liboqs
${CMAKE_CMD} -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DBUILD_SHARED_LIBS=OFF -DCMAKE_EXE_LINKER_FLAGS="-lws2_32" ${SRC_DIR}/liboqs
${MAKE_CMD} -j$(nproc) && ${MAKE_CMD} install
echo ">>> liboqs installed successfully."

# --- 6. Build and Install OQS Provider ---
echo ">>> Step 6: Building and installing oqs-provider..."
cd ${BUILD_DIR}
rm -rf oqs-provider && mkdir -p oqs-provider && cd oqs-provider
${CMAKE_CMD} -G "Unix Makefiles" -DOPENSSL_ROOT_DIR=${INSTALL_DIR} -DCMAKE_PREFIX_PATH=${INSTALL_DIR} -DCMAKE_POLICY_VERSION_MINIMUM=3.5 ${SRC_DIR}/oqs-provider
${MAKE_CMD} -j$(nproc) && ${MAKE_CMD} install
echo ">>> oqs-provider installed successfully. OpenSSL is now PQC-enabled."

# --- 7. Build and Install Nginx ---
echo ">>> Step 7: Building and installing Nginx..."
cd ${BUILD_DIR}
rm -rf nginx && mkdir nginx && cd nginx
tar -xzvf ${SRC_DIR}/nginx-${NGINX_VERSION}.tar.gz --strip-components=1
# We point configure to our custom installation directory for all dependencies.
# We point configure to our custom installation directory for all dependencies.
# We also have to explicitly point to the source directories for Nginx to find them.
./configure \
    --prefix=${NGINX_INSTALL_DIR} \
    --with-cc-opt="-I${INSTALL_DIR}/include" \
    --with-ld-opt="-L${INSTALL_DIR}/lib" \
    --with-http_ssl_module \
    --with-pcre=${BUILD_DIR}/pcre \
    --with-zlib=${BUILD_DIR}/zlib \
    --with-openssl=${SRC_DIR}/openssl
${MAKE_CMD} -j$(nproc)
${MAKE_CMD} install
echo ">>> Nginx installed successfully."

echo "=================================================="
echo "PQC Server (Server B) Build Process COMPLETE"
echo "=================================================="
