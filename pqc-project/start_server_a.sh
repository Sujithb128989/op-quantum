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
PID_FILE="${NGINX_INSTALL_DIR}/pids/nginx_a.pid"
APP_PY="${PROJECT_DIR}/app/app.py"

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

# Start Nginx in the background
echo ">>> Starting Nginx for Server A..."
# The -p flag sets the prefix, which makes all paths in nginx.conf relative to it.
${NGINX_INSTALL_DIR}/sbin/nginx -p ${NGINX_INSTALL_DIR}/

# Wait a moment for Nginx to start
sleep 2

# Start the Python backend application
echo ">>> Starting Python backend for Server A in 'vulnerable' mode..."
python3 ${APP_PY} \
    --mode vulnerable \
    --port 8080 \
    --nginx-pid-file ${PID_FILE}

echo ">>> Server A stopped."
