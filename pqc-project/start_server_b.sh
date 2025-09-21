#!/bin/bash
set -euo pipefail

echo "=================================================="
echo ">>> Starting Server B (PQC-Hardened)"
echo "=================================================="

PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
NGINX_INSTALL_DIR="${PROJECT_DIR}/server_b/nginx"
NGINX_CONF_PATH="${PROJECT_DIR}/server_b/nginx.conf"
DEST_CONF="${NGINX_INSTALL_DIR}/conf/nginx.conf"
PID_FILE="${NGINX_INSTALL_DIR}/pids/nginx_b.pid"
APP_DIR="${PROJECT_DIR}/app"
VENV="${PROJECT_DIR}/../venv"
VENV_PYTHON="${VENV}/bin/python3"
VENV_PIP="${VENV}/bin/pip"
VENV_GUNICORN="${VENV}/bin/gunicorn"

export LD_LIBRARY_PATH="${PROJECT_DIR}/server_b/install/lib64"
export OPENSSL_MODULES="${PROJECT_DIR}/server_b/install/lib64/ossl-modules"
export OPENSSL_CONF="${PROJECT_DIR}/server_b/install/ssl/openssl.cnf"

mkdir -p "${NGINX_INSTALL_DIR}/conf" "${NGINX_INSTALL_DIR}/logs" "${NGINX_INSTALL_DIR}/pids"

cleanup() {
  echo ">>> Shutting down Server B..."
  if [ -f "$PID_FILE" ]; then
    kill "$(cat "$PID_FILE")" || true
    sleep 1
  fi
  pkill -f "gunicorn.*127.0.0.1:8081" || true
}
trap cleanup EXIT

echo ">>> Preparing nginx.conf for Server B..."
cp "${NGINX_CONF_PATH}" "${DEST_CONF}"
# Normalize proxy_pass to plain URI and ensure pid directive in main context
sed -i 's#proxy_pass \\[http://127\\.0\\.0\\.1:8081\\](http://127\\.0\\.0\\.1:8081);#proxy_pass http://127.0.0.1:8081;#g' "${DEST_CONF}"
grep -qE '^[[:space:]]*pid[[:space:]]+pids/nginx_b\\.pid;' "${DEST_CONF}" || \
  sed -i '1s;^;pid pids/nginx_b.pid;\n;' "${DEST_CONF}"

echo ">>> Starting Nginx for Server B..."
"${NGINX_INSTALL_DIR}/sbin/nginx" -t -p "${NGINX_INSTALL_DIR}/"
"${NGINX_INSTALL_DIR}/sbin/nginx" -p "${NGINX_INSTALL_DIR}/"

echo ">>> Ensuring backend dependencies..."
${VENV_PIP} install -r "${APP_DIR}/requirements.txt"

echo ">>> Starting Flask backend (gunicorn) on 127.0.0.1:8081..."
cd "${APP_DIR}"
exec "${VENV_GUNICORN}" -w 2 -b 127.0.0.1:8081 app:app
