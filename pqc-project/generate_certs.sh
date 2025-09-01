#!/bin/bash
#
# generate_certs.sh
#
# This script generates the self-signed TLS certificates for both servers.
# - Server A gets a standard RSA 2048-bit certificate.
# - Server B gets a certificate signed with the PQC algorithm Dilithium3.
#
# This script should be run from the root of the 'pqc-project/' directory.
#

set -e

echo "=================================================="
echo "Generating TLS Certificates"
echo "=================================================="

# --- Server A: Standard RSA Certificate ---
echo ">>> Generating standard RSA certificate for Server A..."
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
    -keyout server_a/server_a.key \
    -out server_a/server_a.crt \
    -subj "/CN=localhost"
echo ">>> Server A certificate created successfully."


# --- Server B: PQC-Hybrid Certificate ---
echo ">>> Generating PQC-signed certificate for Server B..."

# Define the path to our custom PQC-enabled OpenSSL executable
PQC_OPENSSL="server_b/install/bin/openssl"

if [ ! -f "$PQC_OPENSSL" ]; then
    echo "ERROR: PQC-enabled OpenSSL not found at '$PQC_OPENSSL'"
    echo "Please run the build script in 'pqc-project/server_b/' first."
    exit 1
fi

# Generate a key using the Dilithium3 PQC signature algorithm.
# The 'req' command will then create a self-signed certificate using this key.
${PQC_OPENSSL} req -x509 -newkey dilithium3 -nodes -days 365 \
    -keyout server_b/server_b.key \
    -out server_b/server_b.crt \
    -subj "/CN=localhost"

echo ">>> Server B certificate created successfully."

echo "=================================================="
echo "Certificate generation complete."
echo "=================================================="
