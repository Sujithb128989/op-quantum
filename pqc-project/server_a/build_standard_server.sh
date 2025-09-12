#!/bin/bash
#
# build_standard_server.sh (Linux Version)
#
# This script builds and installs all dependencies into a local directory,
# then builds Nginx against those pre-compiled libraries.
#

set -e # Exit immediately if any command fails

# --- Configuration ---
NGINX_VERSION="1.25.3"
NGINX_URL="https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
OPENSSL_GIT_URL="https://github.com/openssl/openssl.git"
OPENSSL_GIT_TAG="openssl-3.2.0"
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
echo "Starting Standard Server (Server A) Build Process"
echo "=================================================="

# --- 1. Download Sources ---
echo ">>> Step 1: Downloading all source code..."
cd ${SRC_DIR}
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


# --- 4. Build and Install OpenSSL ---
echo ">>> Step 4: Building and installing OpenSSL..."
cd ${BUILD_DIR}
# OpenSSL needs to be built from its source directory
cd ${SRC_DIR}/openssl
./Configure linux-x86_64 --prefix=${INSTALL_DIR} --openssldir=${INSTALL_DIR} no-shared
make -j$(nproc)
make install_sw
echo ">>> OpenSSL installed successfully."


# --- 5. Build and Install Nginx ---
echo ">>> Step 5: Building and installing Nginx..."
cd ${BUILD_DIR}
tar -xzvf ${SRC_DIR}/nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}
# We point configure to our custom installation directory for all dependencies.
# For OpenSSL, PCRE, and Zlib, Nginx needs to be pointed to the *source* directories
# of the dependencies, not their install directories.
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
echo ">>> Nginx installed successfully."

echo "=================================================="
echo "Standard Server (Server A) Build Process COMPLETE"
echo "=================================================="
