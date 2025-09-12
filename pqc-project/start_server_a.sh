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

# Define paths relative to the script's location
ROOT_DIR=$(pwd)
NGINX_DIR="${ROOT_DIR}/server_a/nginx"
NGINX_CONF="${ROOT_DIR}/server_a/nginx.conf"
PID_FILE="${NGINX_DIR}/pids/nginx_a.pid"
APP_PY="${ROOT_DIR}/app/app.py"

# Ensure the pids directory exists
mkdir -p "${NGINX_DIR}/pids"

# Start Nginx in the background
echo ">>> Starting Nginx for Server A..."
# We must run nginx from its own directory so it can find its relative paths
(cd ${NGINX_DIR} && ./sbin/nginx -c ${NGINX_CONF}) &

# Wait a moment for Nginx to start and create the PID file
sleep 2

# Start the Python backend application
echo ">>> Starting Python backend for Server A in 'vulnerable' mode..."
python3 ${APP_PY} \
    --mode vulnerable \
    --port 8080 \
    --nginx-pid-file ${PID_FILE}

# When the python app is killed (Ctrl+C), kill the background nginx process
# The 'pkill' command is a more robust way to find the process if the PID file is stale
echo ">>> Backend stopped. Shutting down Nginx..."
pkill -F ${PID_FILE}
