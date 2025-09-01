#!/bin/bash
#
# build_standard_server.sh
#
# This script downloads and compiles a standard version of Nginx (Server A).
# It links against the default OpenSSL library available in the MSYS2 environment.
# It must be run from within the 'pqc-project/server_a/' directory.
#

set -e # Exit immediately if any command fails

# --- Configuration ---
NGINX_VERSION="1.25.3"
NGINX_URL="https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"

# --- Directories ---
SRC_DIR="$(pwd)/src"
BUILD_DIR="$(pwd)/build"
NGINX_INSTALL_DIR="$(pwd)/nginx"

mkdir -p ${SRC_DIR} ${BUILD_DIR}

echo "=================================================="
echo "Starting Standard Server (Server A) Build Process"
echo "=================================================="

# --- 1. Download Nginx ---
echo ">>> Step 1: Downloading Nginx source code..."
cd ${SRC_DIR}

if [ ! -f "nginx-${NGINX_VERSION}.tar.gz" ]; then
    wget ${NGINX_URL}
    tar -xzvf nginx-${NGINX_VERSION}.tar.gz
fi

echo ">>> Source code downloaded successfully."

# --- 2. Build and Install Nginx ---
echo ">>> Step 2: Building and installing Nginx..."
cd ${BUILD_DIR}
# We create a new nginx build directory to avoid conflicts if run in the same root
mkdir -p nginx-build
cd nginx-build

# We do NOT specify --with-openssl, so Nginx will find the system default.
# The setup_msys2.sh script must have installed the 'mingw-w64-x86_64-openssl' package.
${SRC_DIR}/nginx-${NGINX_VERSION}/configure \
    --prefix=${NGINX_INSTALL_DIR} \
    --with-http_ssl_module

make -j$(nproc)
make install
echo ">>> Nginx installed successfully."

echo "=================================================="
echo "Standard Server (Server A) Build Process COMPLETE"
echo "Nginx is installed in: ${NGINX_INSTALL_DIR}"
echo "=================================================="
