#!/bin/bash
#
# start_server_a.sh
#
# This script starts the standard Nginx server (Server A) and its
# corresponding backend Python application in 'vulnerable' mode.
#

echo "=================================================="
echo ">>> Starting Server A (Standard)"
echo "=================================================="

# Get the directory of the pqc-project
PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
NGINX_INSTALL_DIR="${PROJECT_DIR}/server_a/nginx"
NGINX_CONF_PATH="${PROJECT_DIR}/server_a/nginx.conf"
PID_FILE="${NGINX_INSTALL_DIR}/pids/nginx_a.pid"
APP_PY="${PROJECT_DIR}/app/app.py"
VENV_PYTHON="${PROJECT_DIR}/../venv/bin/python3"

# Function to clean up background processes on exit
cleanup() {
    echo ">>> Shutting down Server A..."
    if [ -f "$PID_FILE" ]; then
        kill $(cat ${PID_FILE})
    fi
    # Additional cleanup for any lingering processes
    pkill -f "app.py --mode vulnerable"
}
trap cleanup EXIT

# --- Pre-flight Checks ---
CERT_FILE="${PROJECT_DIR}/server_a.crt"
KEY_FILE="${PROJECT_DIR}/server_a.key"
if [ ! -f "${CERT_FILE}" ]; then
    echo ">>> Certificate not found. Please run 'generate_certs.sh' first."
    exit 1
fi

# --- Dynamic Nginx Configuration ---
# Create a temporary config file with absolute paths to the certificates
TEMP_NGINX_CONF=$(mktemp)
# Use a different separator for sed to avoid issues with paths containing '/'
sed "s|__CERT_PATH__|${CERT_FILE}|g; s|__KEY_PATH__|${KEY_FILE}|g" "${NGINX_CONF_PATH}" > "${TEMP_NGINX_CONF}"


# Start Nginx in the background
echo ">>> Starting Nginx for Server A..."
# Copy the dynamically generated config file to the location Nginx expects
cp "${TEMP_NGINX_CONF}" "${NGINX_INSTALL_DIR}/conf/nginx.conf"
rm "${TEMP_NGINX_CONF}" # Clean up temp file
# The -p flag sets the prefix path, and Nginx will now find its config by default
${NGINX_INSTALL_DIR}/sbin/nginx -p ${NGINX_INSTALL_DIR}/

# Wait a moment for Nginx to start
sleep 2

# Start the Python backend application
echo ">>> Starting Python backend for Server A in 'vulnerable' mode..."
# We use the full path to the virtual environment's python to ensure correctness.
${VENV_PYTHON} ${APP_PY} \
    --mode vulnerable \
    --port 8080 \
    --nginx-pid-file ${PID_FILE}

echo ">>> Server A stopped."
