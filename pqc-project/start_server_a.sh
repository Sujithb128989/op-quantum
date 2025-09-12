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

# Define paths relative to the project root directory where this script lives
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
NGINX_DIR="${ROOT_DIR}/server_a/nginx"
NGINX_CONF="${ROOT_DIR}/server_a/nginx.conf"
PID_FILE="${NGINX_DIR}/pids/nginx_a.pid"
APP_PY="${ROOT_DIR}/app/app.py"

# Ensure the pids directory exists
mkdir -p "${NGINX_DIR}/pids"

# Start Nginx in the background
echo ">>> Starting Nginx for Server A..."
# We must run nginx from the project root so it can find the relative server_a paths
${NGINX_DIR}/sbin/nginx -c ${NGINX_CONF} -p ${ROOT_DIR}

# Wait a moment for Nginx to start and create the PID file
sleep 2

# Start the Python backend application
echo ">>> Starting Python backend for Server A in 'vulnerable' mode..."
python3 ${APP_PY} \
    --mode vulnerable \
    --port 8080 \
    --nginx-pid-file ${PID_FILE}

# When the python app is killed (Ctrl+C), kill the background nginx process
echo ">>> Backend stopped. Shutting down Nginx..."
kill $(cat ${PID_FILE})
