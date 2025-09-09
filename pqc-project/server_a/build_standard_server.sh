#!/bin/bash
#
# build_standard_server.sh
# Version 1.1
#
# This script downloads and compiles a standard version of Nginx (Server A).
# It must be run from within the 'pqc-project/server_a/' directory.
#

set -e # Exit immediately if any command fails

# --- Configuration ---
# Using an absolute path for 'make' to bypass potential user PATH issues.
MAKE_CMD="/mingw64/bin/make"

NGINX_VERSION="1.25.3"
NGINX_URL="https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"

# --- Directories ---
SRC_DIR="$(pwd)/src"
NGINX_INSTALL_DIR="$(pwd)/nginx"

mkdir -p ${SRC_DIR}

echo "=================================================="
echo "Starting Standard Server (Server A) Build Process"
echo "=================================================="

# --- 1. Download Nginx ---
echo ">>> Step 1: Downloading Nginx source code..."
cd ${SRC_DIR}

if [ ! -f "nginx-${NGINX_VERSION}.tar.gz" ]; then
    wget ${NGINX_URL}
fi
# Remove old directory to ensure a clean build
rm -rf nginx-${NGINX_VERSION}
tar -xzvf nginx-${NGINX_VERSION}.tar.gz

echo ">>> Source code downloaded successfully."

# --- 2. Build and Install Nginx ---
echo ">>> Step 2: Building and installing Nginx..."
cd nginx-${NGINX_VERSION}

# We run configure from within the source directory. This is a more robust method.
./configure \
    --prefix=${NGINX_INSTALL_DIR} \
    --with-http_ssl_module

${MAKE_CMD} -j$(nproc)
${MAKE_CMD} install
echo ">>> Nginx installed successfully."

echo "=================================================="
echo "Standard Server (Server A) Build Process COMPLETE"
echo "Nginx is installed in: ${NGINX_INSTALL_DIR}"
echo "=================================================="
