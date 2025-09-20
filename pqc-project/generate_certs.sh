#!/bin/bash
#
# generate_certs.sh
#
# This script generates the self-signed TLS certificates for both servers.
# - Server A gets a standard RSA 2048-bit certificate.
# - Server B gets a certificate signed with the PQC algorithm Dilithium3.
#

set -e

echo "=================================================="
echo "Generating TLS Certificates"
echo "=================================================="

# Get the directory where this script is located
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
SERVER_A_DIR="${SCRIPT_DIR}/server_a"
SERVER_B_DIR="${SCRIPT_DIR}/server_b"

# --- Server A: Standard RSA Certificate ---
echo ">>> Generating standard RSA certificate for Server A..."
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
    -keyout ${SERVER_A_DIR}/server_a.key \
    -out ${SERVER_A_DIR}/server_a.crt \
    -subj "/CN=localhost"
echo ">>> Server A certificate created successfully."


# --- Server B: PQC-Hybrid Certificate ---
echo ">>> Generating PQC-signed certificate for Server B..."

# Define paths to our custom PQC-enabled OpenSSL and the provider module
PQC_OPENSSL="${SERVER_B_DIR}/install/bin/openssl"
PROVIDER_MODULE_PATH="${SERVER_B_DIR}/install/lib64/ossl-modules"
PROVIDER_MODULE_NAME="oqsprovider"

if [ ! -f "${PQC_OPENSSL}" ]; then
    echo "ERROR: PQC-enabled OpenSSL not found at '${PQC_OPENSSL}'"
    echo "Please run the build script in '${SERVER_B_DIR}/' first."
    exit 1
fi

if [ ! -f "${PROVIDER_MODULE_PATH}/${PROVIDER_MODULE_NAME}.so" ]; then
    echo "ERROR: OQS Provider module not found at '${PROVIDER_MODULE_PATH}/${PROVIDER_MODULE_NAME}.so'"
    echo "Please ensure the Server B build completed successfully."
    exit 1
fi

# Force OpenSSL to use our custom-built libraries to prevent contamination
# from the system's libraries. This is the definitive fix for the build issues.
export LD_LIBRARY_PATH="${SERVER_B_DIR}/install/lib64"

# Generate a key using the Dilithium3 PQC signature algorithm.
# We use -provider-path and -provider to explicitly load our custom module.
${PQC_OPENSSL} req -x509 -newkey dilithium3 -nodes -days 365 -rand /dev/urandom \
    -provider-path ${PROVIDER_MODULE_PATH} \
    -provider ${PROVIDER_MODULE_NAME} \
    -keyout ${SERVER_B_DIR}/server_b.key \
    -out ${SERVER_B_DIR}/server_b.crt \
    -subj "/CN=localhost"

echo ">>> Server B certificate created successfully."

echo "=================================================="
echo "Certificate generation complete."
echo "=================================================="
