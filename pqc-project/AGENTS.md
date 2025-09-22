# Agent Instructions for `op-quantum`

This document provides critical information for any AI agent working on this project. It summarizes the key architectural components and the fixes that have been implemented for recurring or non-obvious bugs.

## 1. Core Architecture

- The project consists of two servers, **Server A** (standard) and **Server B** (PQC-hardened), which are fronted by Nginx web servers.
- The backend is a single Flask application (`app/app.py`) that runs in two different modes (`vulnerable` or `secure`).
- Server configurations are in `server_a/` and `server_b/`.
- All Python-based work **must** be done within a Python virtual environment.

### Environment Setup

To set up the required environment, run the following commands from the `op-quantum` root directory:
```bash
# Create the virtual environment
python3 -m venv venv

# Activate the environment
source venv/bin/activate

# Install all required packages
pip install -r pqc-project/app/requirements.txt
pip install -r pqc-project/attacker/requirements.txt
```
**Note:** The `source venv/bin/activate` command must be run in any new terminal session.

## 2. Key Bug Fixes and Solutions

This project had several complex, interdependent bugs. The following solutions have been implemented and should be preserved.

### 2.1. Server Startup Hang (`start_server_*.sh`)

- **Problem:** The `start_server_a.sh` and `start_server_b.sh` scripts would hang after starting Nginx, requiring a `Ctrl+C` to proceed.
- **Root Cause:** The Nginx process was being called without being forked to the background. With the `daemon off;` directive in `nginx.conf` (which is required for this type of process management), this blocks the script.
- **Solution:** The Nginx command in both `start_server_a.sh` and `start_server_b.sh` has been modified to run in the background by appending an ampersand (`&`).
  - **Example:** `${NGINX_INSTALL_DIR}/sbin/nginx -p ${NGINX_INSTALL_DIR}/ &`

### 2.2. Server B Nginx Startup Failure (`ee key too small`)

- **Problem:** Server B's Nginx would fail to start, citing an `ee key too small` error.
- **Root Cause:** The default OpenSSL security level (`SECLEVEL=2`) is too high for the PQC certificate (`dilithium3`). Attempts to lower this via `ssl_conf_command` in `nginx.conf` were ineffective.
- **Solution:** The security level is now set globally for the custom OpenSSL build used by Server B. The file `pqc-project/server_b/openssl.cnf.template` was modified to include a `system_default` section that sets the `CipherString` to `DEFAULT@SECLEVEL=1`. This requires Server B to be rebuilt with `bash pqc-project/server_b/build_pqc_server.sh` if this template is ever changed.

### 2.3. Flask `TypeError` on Server B

- **Problem:** When viewing messages on Server B, the Flask application would crash with `TypeError: Object of type bytes is not JSON serializable`.
- **Root Cause:** The `encrypted_key` field, which contains raw bytes from the database, was being passed directly to `jsonify`.
- **Solution:** In `pqc-project/app/app.py`, within the `get_messages` function, the `encrypted_key` bytes are now encoded into a Base64 string before the JSON response is created. This makes the data serializable.

### 2.4. `sql_injector.py` False Negatives

- **Problem:** The SQL injection attack script reported failure against Server A, even when it was working.
- **Root Cause:** The script was parsing the server's HTML response looking for `<li>` tags, but the new UI uses `<div>` tags with specific classes (`user-item`, `user-name`, `user-status`).
- **Solution:** The script `pqc-project/attacker/sql_injector.py` has been updated to use `soup.select()` with the correct CSS selectors to find the new `div` structure and correctly parse the results.

## 3. Firewall Configuration for External Access

- To run the attacker scripts from a different machine (e.g., a Windows host attacking a WSL instance), a firewall rule is necessary.
- On Windows, open "Windows Defender Firewall with Advanced Security" and create a new **Inbound Rule** for **TCP Ports `8443` and `9443`**, set to "Allow the connection".
