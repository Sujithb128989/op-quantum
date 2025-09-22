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

# Define path to our custom PQC-enabled OpenSSL
PQC_OPENSSL="${SERVER_B_DIR}/install/bin/openssl"

if [ ! -f "${PQC_OPENSSL}" ]; then
    echo "ERROR: PQC-enabled OpenSSL not found at '${PQC_OPENSSL}'"
    echo "Please run the build script in '${SERVER_B_DIR}/' first."
    exit 1
fi

# Generate a key using the Dilithium3 PQC signature algorithm.
# The custom openssl.cnf created by the build script will automatically
# load the required default and OQS providers.
${PQC_OPENSSL} req -x509 -newkey dilithium3 -nodes -days 365 \
    -keyout ${SERVER_B_DIR}/server_b.key \
    -out ${SERVER_B_DIR}/server_b.crt \
    -subj "/CN=localhost"

echo ">>> Server B certificate created successfully."

echo "=================================================="
echo "Certificate generation complete."
echo "=================================================="
