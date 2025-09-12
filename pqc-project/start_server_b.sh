#!/bin/bash
#
# start_server_b.sh
#
# This script starts the PQC-enabled Nginx server (Server B) and its
# corresponding backend Python application in 'secure' mode.
#

echo "=================================================="
echo ">>> Starting Server B (PQC-Hardened)"
echo "=================================================="

# Define paths relative to the project root directory where this script lives
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
NGINX_DIR="${ROOT_DIR}/server_b/nginx"
NGINX_CONF="${ROOT_DIR}/server_b/nginx.conf"
PID_FILE="${NGINX_DIR}/pids/nginx_b.pid"
APP_PY="${ROOT_DIR}/app/app.py"

# Ensure the pids directory exists
mkdir -p "${NGINX_DIR}/pids"

# Start Nginx in the background
echo ">>> Starting Nginx for Server B..."
# We must run nginx from the project root so it can find the relative server_b paths
${NGINX_DIR}/sbin/nginx -c ${NGINX_CONF} -p ${ROOT_DIR}

# Wait a moment for Nginx to start and create the PID file
sleep 2

# Start the Python backend application
echo ">>> Starting Python backend for Server B in 'secure' mode..."
python3 ${APP_PY} \
    --mode secure \
    --port 8081 \
    --nginx-pid-file ${PID_FILE}

# When the python app is killed (Ctrl+C), kill the background nginx process
echo ">>> Backend stopped. Shutting down Nginx..."
kill $(cat ${PID_FILE})
