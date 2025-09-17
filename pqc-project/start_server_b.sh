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

# Get the directory of the pqc-project
PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
NGINX_INSTALL_DIR="${PROJECT_DIR}/server_b/nginx"
NGINX_CONF_PATH="${PROJECT_DIR}/server_b/nginx.conf"
PID_FILE="${NGINX_INSTALL_DIR}/pids/nginx_b.pid"
APP_PY="${PROJECT_DIR}/app/app.py"
VENV_PYTHON="${PROJECT_DIR}/../venv/bin/python3"

# Function to clean up background processes on exit
cleanup() {
    echo ">>> Shutting down Server B..."
    if [ -f "$PID_FILE" ]; then
        kill $(cat ${PID_FILE})
    fi
    # Additional cleanup for any lingering processes
    pkill -f "app.py --mode secure"
}
trap cleanup EXIT

# Start Nginx in the background
echo ">>> Starting Nginx for Server B..."
# The -p flag sets the prefix path.
# The -c flag explicitly tells Nginx which configuration file to use.
${NGINX_INSTALL_DIR}/sbin/nginx -p ${NGINX_INSTALL_DIR}/ -c ${NGINX_CONF_PATH}

# Wait a moment for Nginx to start
sleep 2

# Start the Python backend application
echo ">>> Starting Python backend for Server B in 'secure' mode..."
# We use the full path to the virtual environment's python to ensure correctness.
${VENV_PYTHON} ${APP_PY} \
    --mode secure \
    --port 8081 \
    --nginx-pid-file ${PID_FILE}

echo ">>> Server B stopped."
