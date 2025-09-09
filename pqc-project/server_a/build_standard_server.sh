#!/bin/bash
#
# build_standard_server.sh
#
# This script downloads and compiles a standard version of Nginx (Server A).
# It also downloads the required pcre and zlib dependencies and builds them statically.
#

set -e # Exit immediately if any command fails

# --- Configuration ---
MAKE_CMD="mingw32-make"

NGINX_VERSION="1.25.3"
NGINX_URL="https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
PCRE_VERSION="8.45"
# SourceForge links can be unreliable, use a more direct mirror if available
PCRE_URL="https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.43/pcre2-10.43.tar.gz"
# The above is PCRE2, Nginx needs PCRE1. Let's find a better link.
# The official PCRE project has moved. Let's use a reliable source.
PCRE_URL="https://sourceforge.net/projects/pcre/files/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.gz"

ZLIB_VERSION="1.3.1"
ZLIB_URL="https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz"


# --- Directories ---
SRC_DIR="$(pwd)/src"
NGINX_INSTALL_DIR="$(pwd)/nginx"

mkdir -p ${SRC_DIR}

echo "=================================================="
echo "Starting Standard Server (Server A) Build Process"
echo "=================================================="

# --- 1. Download Sources ---
echo ">>> Step 1: Downloading all source code (Nginx, PCRE, Zlib)..."
cd ${SRC_DIR}

# Download Nginx
if [ ! -f "nginx-${NGINX_VERSION}.tar.gz" ]; then wget ${NGINX_URL}; fi
rm -rf nginx-${NGINX_VERSION} && tar -xzvf nginx-${NGINX_VERSION}.tar.gz

# Download PCRE
if [ ! -f "pcre-${PCRE_VERSION}.tar.gz" ]; then wget -O pcre-${PCRE_VERSION}.tar.gz ${PCRE_URL}; fi
rm -rf pcre-${PCRE_VERSION} && tar -xzvf pcre-${PCRE_VERSION}.tar.gz

# Download Zlib
if [ ! -f "zlib-${ZLIB_VERSION}.tar.gz" ]; then wget ${ZLIB_URL}; fi
rm -rf zlib-${ZLIB_VERSION} && tar -xzvf zlib-${ZLIB_VERSION}.tar.gz


echo ">>> Source code downloaded successfully."

# --- 2. Build and Install Nginx ---
echo ">>> Step 2: Building and installing Nginx..."
cd nginx-${NGINX_VERSION}

# We point the configure script to the source directories of its dependencies.
# This creates a static build that does not depend on system-installed libraries.
./configure \
    --prefix=${NGINX_INSTALL_DIR} \
    --with-http_ssl_module \
    --with-pcre=../pcre-${PCRE_VERSION} \
    --with-zlib=../zlib-${ZLIB_VERSION}

${MAKE_CMD} -j$(nproc)
${MAKE_CMD} install
echo ">>> Nginx installed successfully."

echo "=================================================="
echo "Standard Server (Server A) Build Process COMPLETE"
echo "Nginx is installed in: ${NGINX_INSTALL_DIR}"
echo "=================================================="
