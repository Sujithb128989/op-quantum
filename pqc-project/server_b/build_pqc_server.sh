#!/bin/bash
#
# build_pqc_server.sh
#
# This script downloads and compiles all components for the PQC-enabled server (Server B).
#

set -e # Exit immediately if any command fails

# --- Configuration ---
MAKE_CMD="mingw32-make"
CMAKE_CMD="cmake"

# Using specific commits/tags for reproducibility and compatibility.
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

mkdir -p ${SRC_DIR} ${BUILD_DIR} ${INSTALL_DIR}

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
rm -rf nginx-${NGINX_VERSION} && tar -xzvf nginx-${NGINX_VERSION}.tar.gz
if [ ! -f "pcre-${PCRE_VERSION}.tar.gz" ]; then wget -O pcre-${PCRE_VERSION}.tar.gz ${PCRE_URL}; fi
rm -rf pcre-${PCRE_VERSION} && tar -xzvf pcre-${PCRE_VERSION}.tar.gz
if [ ! -f "zlib-${ZLIB_VERSION}.tar.gz" ]; then wget ${ZLIB_URL}; fi
rm -rf zlib-${ZLIB_VERSION} && tar -xzvf zlib-${ZLIB_VERSION}.tar.gz
echo ">>> Source code downloaded successfully."

# --- 2. Build and Install liboqs ---
echo ">>> Step 2: Building and installing liboqs..."
cd ${BUILD_DIR}
rm -rf liboqs && mkdir -p liboqs && cd liboqs
${CMAKE_CMD} -G "MinGW Makefiles" -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} ${SRC_DIR}/liboqs
${MAKE_CMD} -j$(nproc) && ${MAKE_CMD} install
echo ">>> liboqs installed successfully."

# --- 3. Build and Install OpenSSL ---
echo ">>> Step 3: Building and installing OpenSSL..."
cd ${BUILD_DIR}
rm -rf openssl && mkdir -p openssl && cd openssl
${SRC_DIR}/openssl/Configure mingw64 --prefix=${INSTALL_DIR} --openssldir=${INSTALL_DIR}
${MAKE_CMD} -j$(nproc) && ${MAKE_CMD} install
echo ">>> OpenSSL installed successfully."

# --- 4. Build and Install OQS Provider ---
echo ">>> Step 4: Building and installing oqs-provider..."
cd ${BUILD_DIR}
rm -rf oqs-provider && mkdir -p oqs-provider && cd oqs-provider
${CMAKE_CMD} -G "MinGW Makefiles" -DOPENSSL_ROOT_DIR=${INSTALL_DIR} -DCMAKE_PREFIX_PATH=${INSTALL_DIR} ${SRC_DIR}/oqs-provider
${MAKE_CMD} -j$(nproc) && ${MAKE_CMD} install
echo ">>> oqs-provider installed successfully."

# --- 5. Build and Install Nginx ---
echo ">>> Step 5: Building and installing Nginx..."
cd ${SRC_DIR}/nginx-${NGINX_VERSION}
./configure \
    --prefix=${NGINX_INSTALL_DIR} \
    --with-http_ssl_module \
    --with-openssl=${SRC_DIR}/openssl \
    --with-pcre=../pcre-${PCRE_VERSION} \
    --with-zlib=../zlib-${ZLIB_VERSION} \
    --with-ld-opt="-L${INSTALL_DIR}/lib" \
    --with-cc-opt="-I${INSTALL_DIR}/include"
${MAKE_CMD} -j$(nproc) && ${MAKE_CMD} install
echo ">>> Nginx installed successfully."

echo "=================================================="
echo "PQC Server (Server B) Build Process COMPLETE"
echo "=================================================="
