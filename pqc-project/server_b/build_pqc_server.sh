#!/bin/bash
#
# build_pqc_server.sh (Linux Version - Corrected Paths)
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
# Get the directory where this script is located
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
SRC_DIR="${SCRIPT_DIR}/src"
BUILD_DIR="${SCRIPT_DIR}/build"
INSTALL_DIR="${SCRIPT_DIR}/install"
NGINX_INSTALL_DIR="${SCRIPT_DIR}/nginx"

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

# --- 4. Build and Install OpenSSL ---
echo ">>> Step 4: Building base OpenSSL..."
cd ${SRC_DIR}/openssl
# Configure without rpath; it will be set manually and robustly with patchelf.
./Configure linux-x86_64 -d --prefix=${INSTALL_DIR} --openssldir=${INSTALL_DIR}/ssl shared
make -j$(nproc)
make install
echo ">>> Base OpenSSL installed successfully."

# --- 5. Patch and Verify OpenSSL Build ---
echo ">>> Step 5: Patching and Verifying OpenSSL build..."
# Use patchelf to forcefully set the rpath. This is the most robust method.
# The $'\044' syntax is ANSI-C Quoting, which guarantees a literal dollar sign.
patchelf --force-rpath --set-rpath $'\044ORIGIN/../lib64' "${INSTALL_DIR}/bin/openssl"
echo ">>> Verifying OpenSSL linkage..."
# Verify that the RPATH/RUNPATH is correctly set.
readelf -d ${INSTALL_DIR}/bin/openssl | grep -E 'RPATH|RUNPATH' || (echo "ERROR: RPATH/RUNPATH not set in openssl binary" && exit 1)
# Verify that the dynamic linker finds the correct libraries.
ldd ${INSTALL_DIR}/bin/openssl | grep "libssl.so.3 => ${INSTALL_DIR}" || (echo "ERROR: openssl not linked to custom libssl" && exit 1)
echo ">>> OpenSSL build verified successfully."


# --- 6. Build and Install liboqs ---
echo ">>> Step 6: Building liboqs..."
cd ${BUILD_DIR}
mkdir -p liboqs && cd liboqs
# Point to lib64 where the libraries are actually installed.
cmake -G "Ninja" -DOPENSSL_ROOT_DIR=${INSTALL_DIR} -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -S ${SRC_DIR}/liboqs
ninja
ninja install
echo ">>> liboqs installed successfully."

# --- 7. Build and Install OQS Provider ---
echo ">>> Step 7: Building oqs-provider..."
cd ${BUILD_DIR}
mkdir -p oqs-provider && cd oqs-provider
liboqs_DIR=${INSTALL_DIR}/lib/cmake/liboqs cmake -G "Ninja" -DOPENSSL_ROOT_DIR=${INSTALL_DIR} -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -S ${SRC_DIR}/oqs-provider
ninja
ninja install
echo ">>> Manually copying oqsprovider.so to fix installation issue..."
cp lib/oqsprovider.so ${INSTALL_DIR}/lib64/ossl-modules/
echo ">>> oqs-provider installed successfully."

# --- 8. Configure OpenSSL for OQS Provider ---
echo ">>> Step 8: Configuring OpenSSL for OQS Provider..."
OPENSSL_CNF_PATH="${INSTALL_DIR}/ssl/openssl.cnf"
# Add the oqsprovider to the provider list
sed -i 's/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g' ${OPENSSL_CNF_PATH}
# Add the oqsprovider section and activate it
sed -i "s#\[provider_sect\]#\[provider_sect\]\n\n\[oqsprovider_sect\]\nactivate = 1\nmodule = ${INSTALL_DIR}/lib64/ossl-modules/oqsprovider.so#g" ${OPENSSL_CNF_PATH}
echo ">>> OpenSSL configured for OQS Provider."


# --- 9. Build and Install Nginx ---
echo ">>> Step 9: Building and installing Nginx..."
cd ${BUILD_DIR}
tar -xzvf ${SRC_DIR}/nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}
# Do NOT use --with-openssl. Point to the installed libs directly.
./configure \
    --prefix=${NGINX_INSTALL_DIR} \
    --with-cc-opt="-I${INSTALL_DIR}/include" \
    --with-ld-opt="-L${INSTALL_DIR}/lib64 -Wl,-rpath,${INSTALL_DIR}/lib64 -Wl,--enable-new-dtags" \
    --with-http_ssl_module \
    --with-pcre=${BUILD_DIR}/pcre-${PCRE_VERSION} \
    --with-zlib=${BUILD_DIR}/zlib-${ZLIB_VERSION}

make -j$(nproc)
make install
echo ">>> Nginx with PQC support installed successfully."

echo "=================================================="
echo "PQC Server (Server B) Build Process COMPLETE"
echo "=================================================="
