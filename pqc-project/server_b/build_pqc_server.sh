#!/bin/bash
#
# build_pqc_server.sh (Linux Version)
#
# This script builds and installs all dependencies into a local directory,
# then builds Nginx against those pre-compiled libraries.
#

set -e # Exit immediately if any command fails

# --- Configuration ---
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

# Clean up previous builds
rm -rf ${BUILD_DIR} ${INSTALL_DIR} ${NGINX_INSTALL_DIR}
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
if [ ! -f "pcre-${PCRE_VERSION}.tar.gz" ]; then wget -O pcre-${PCRE_VERSION}.tar.gz ${PCRE_URL}; fi
if [ ! -f "zlib-${ZLIB_VERSION}.tar.gz" ]; then wget ${ZLIB_URL}; fi
echo ">>> Source code downloaded successfully."

# --- 2. Build and Install Zlib ---
echo ">>> Step 2: Building and installing zlib..."
cd ${BUILD_DIR}
tar -xzvf ${SRC_DIR}/zlib-${ZLIB_VERSION}.tar.gz
cd zlib-${ZLIB_VERSION}
./configure --prefix=${INSTALL_DIR}
make -j$(nproc)
make install
echo ">>> zlib installed successfully."

# --- 3. Build and Install PCRE ---
echo ">>> Step 3: Building and installing pcre..."
cd ${BUILD_DIR}
tar -xzvf ${SRC_DIR}/pcre-${PCRE_VERSION}.tar.gz
cd pcre-${PCRE_VERSION}
./configure --prefix=${INSTALL_DIR} --enable-static
make -j$(nproc)
make install
echo ">>> pcre installed successfully."

# --- 4. Build and Install OpenSSL (PQC-Patched) ---
# This is a multi-step process to create an OpenSSL that is PQC-aware.
echo ">>> Step 4: Building PQC-enabled OpenSSL..."

# 4a. Build liboqs (the PQC library)
echo ">>> Step 4a: Building liboqs..."
cd ${BUILD_DIR}
mkdir -p liboqs && cd liboqs
cmake -G "Ninja" -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -S ${SRC_DIR}/liboqs
ninja
ninja install
echo ">>> liboqs installed successfully."

# 4b. Build and patch OpenSSL
echo ">>> Step 4b: Building and patching OpenSSL..."
cd ${BUILD_DIR}
mkdir -p openssl && cd openssl
# Note: oqs-provider requires a shared-library build of OpenSSL
${SRC_DIR}/openssl/Configure linux-x86_64 -d --prefix=${INSTALL_DIR} --openssldir=${INSTALL_DIR} shared
make -j$(nproc)
make install_sw
echo ">>> Base OpenSSL installed successfully."

# 4c. Build oqs-provider to link liboqs and OpenSSL
echo ">>> Step 4c: Building oqs-provider..."
cd ${BUILD_DIR}
mkdir -p oqs-provider && cd oqs-provider
cmake -G "Ninja" -DOPENSSL_ROOT_DIR=${INSTALL_DIR} -S ${SRC_DIR}/oqs-provider
ninja
ninja install
echo ">>> oqs-provider installed successfully. OpenSSL is now PQC-enabled."


# --- 5. Build and Install Nginx ---
echo ">>> Step 5: Building and installing Nginx..."
cd ${BUILD_DIR}
tar -xzvf ${SRC_DIR}/nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}
# Point configure to our custom PQC-enabled OpenSSL and other dependencies
./configure \
    --prefix=${NGINX_INSTALL_DIR} \
    --with-cc-opt="-I${INSTALL_DIR}/include" \
    --with-ld-opt="-L${INSTALL_DIR}/lib" \
    --with-http_ssl_module \
    --with-pcre=../pcre-${PCRE_VERSION} \
    --with-zlib=../zlib-${ZLIB_VERSION} \
    --with-openssl=${SRC_DIR}/openssl

make -j$(nproc)
make install
echo ">>> Nginx with PQC support installed successfully."

echo "=================================================="
echo "PQC Server (Server B) Build Process COMPLETE"
echo "=================================================="
