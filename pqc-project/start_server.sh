#!/bin/bash
#
# start_server.sh
#
# This script starts the specified server (A or B) and its
# corresponding backend Python application.
#
set -euo pipefail

# --- Script Usage ---
if [ "$#" -ne 1 ] || ! [[ "$1" =~ ^[ab]$ ]]; then
    echo "Usage: $0 <a|b>"
    echo "  a: Start Server A (Standard)"
    echo "  b: Start Server B (PQC-Hardened)"
    exit 1
fi

# --- Configuration based on input ---
SERVER_ID=$1
if [ "$SERVER_ID" == "a" ]; then
    SERVER_NAME="Server A (Standard)"
    SERVER_DIR="server_a"
    APP_MODE="vulnerable"
    APP_PORT="8080"
else
    SERVER_NAME="Server B (PQC-Hardened)"
    SERVER_DIR="server_b"
    APP_MODE="secure"
    APP_PORT="8081"
fi

echo "=================================================="
echo ">>> Starting ${SERVER_NAME}"
echo "=================================================="

# --- Paths ---
PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
NGINX_INSTALL_DIR="${PROJECT_DIR}/${SERVER_DIR}/nginx"
NGINX_CONF_PATH="${PROJECT_DIR}/${SERVER_DIR}/nginx.conf"
APP_PY="${PROJECT_DIR}/app/app.py"
VENV_PYTHON="${PROJECT_DIR}/../venv/bin/python3"

# --- Pre-flight Checks ---
CERT_FILE="${PROJECT_DIR}/${SERVER_DIR}/server_${SERVER_ID}.crt"
KEY_FILE="${PROJECT_DIR}/${SERVER_DIR}/server_${SERVER_ID}.key"
if [ ! -f "${CERT_FILE}" ] || [ ! -f "${KEY_FILE}" ]; then
    echo ">>> Certificate/Key not found for Server ${SERVER_ID}. Please run 'generate_certs.sh' first."
    exit 1
fi

# --- Dynamic Nginx Configuration ---
# Generate the final nginx.conf file with the correct, absolute certificate paths.
FINAL_NGINX_CONF="${NGINX_INSTALL_DIR}/conf/nginx.conf"
sed "s|__CERT_PATH__|${CERT_FILE}|g; s|__KEY_PATH__|${KEY_FILE}|g" "${NGINX_CONF_PATH}" > "${FINAL_NGINX_CONF}"

# --- Start Nginx ---
echo ">>> Starting Nginx for ${SERVER_NAME}..."
# The config file is now in the correct location, so Nginx will find it automatically
# when using the -p prefix path flag.
${NGINX_INSTALL_DIR}/sbin/nginx -p ${NGINX_INSTALL_DIR}/ -g 'daemon off;' &
NGINX_PID=$!

# --- Cleanup ---
trap 'echo ">>> Shutting down ${SERVER_NAME}..."; kill ${NGINX_PID};' EXIT

# --- Start Python Backend ---
echo ">>> Starting Python backend for ${SERVER_NAME} in '${APP_MODE}' mode..."
exec ${VENV_PYTHON} ${APP_PY} \
    --mode ${APP_MODE} \
    --port ${APP_PORT}
