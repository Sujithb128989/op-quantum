#!/bin/bash
#
# build_standard_server.sh
#
# This script downloads and compiles a standard version of Nginx (Server A).
# It links against the default OpenSSL library available in the MSYS2 environment.
# It must be run from within the 'pqc-project/server_a/' directory.
#

set -e # Exit immediately if any command fails

# --- Pre-flight Checks ---
echo ">>> Verifying build environment..."
command -v make >/dev/null 2>&1 || { echo >&2 "ERROR: 'make' not found. Please run the main setup script from the project root first."; exit 1; }
command -v gcc >/dev/null 2>&1 || { echo >&2 "ERROR: 'gcc' not found. Please run the main setup script from the project root first."; exit 1; }
echo ">>> Environment checks passed."

# --- Configuration ---
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
# We do NOT specify --with-openssl, so Nginx will find the system default.
# The setup_msys2.sh script must have installed the 'mingw-w64-x86_64-openssl' package.
./configure \
    --prefix=${NGINX_INSTALL_DIR} \
    --with-http_ssl_module

make -j$(nproc)
make install
echo ">>> Nginx installed successfully."

echo "=================================================="
echo "Standard Server (Server A) Build Process COMPLETE"
echo "Nginx is installed in: ${NGINX_INSTALL_DIR}"
echo "=================================================="
