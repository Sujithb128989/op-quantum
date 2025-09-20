#!/bin/bash
#
# run_full_setup.sh
#
# This master script runs the entire setup and build process for the
# PQC Demonstration Suite from start to finish.
# It will stop immediately if any command fails.
#
# Run this from the root of the 'op-quantum' repository.
#
set -e

echo "=================================================="
echo ">>> Starting Full Project Setup..."
echo "=================================================="

# --- Get the project directory ---
PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# --- Step 1: Install System Dependencies ---
echo
echo ">>> STEP 1 of 6: Installing system dependencies..."
bash ${PROJECT_DIR}/setup_kali.sh

# --- Step 2: Make Scripts Executable ---
echo
echo ">>> STEP 2 of 6: Making all scripts executable..."
chmod +x ${PROJECT_DIR}/*.sh \
         ${PROJECT_DIR}/server_a/*.sh \
         ${PROJECT_DIR}/server_b/*.sh
echo ">>> Scripts are now executable."

# --- Step 3: Build Server A ---
echo
echo ">>> STEP 3 of 6: Building Server A (Standard)..."
bash ${PROJECT_DIR}/server_a/build_standard_server.sh
echo ">>> Server A build complete."

# --- Step 4: Build Server B ---
echo
echo ">>> STEP 4 of 6: Building Server B (PQC-Hardened)..."
bash ${PROJECT_DIR}/server_b/build_pqc_server.sh
echo ">>> Server B build complete."

# --- Step 5: Set Up Python Environment ---
echo
echo ">>> STEP 5 of 6: Setting up Python virtual environment and packages..."
# Download the oqs-python source to a temporary location
if [ ! -f "/tmp/liboqs-python-0.10.0.zip" ]; then
    echo ">>> Downloading oqs-python source..."
    wget https://github.com/open-quantum-safe/liboqs-python/archive/refs/tags/0.10.0.zip -O /tmp/liboqs-python-0.10.0.zip
fi
python3 -m venv venv
source venv/bin/activate
echo ">>> Installing Python packages. This may take a while..."
# Point pip to the liboqs we already built for Nginx to avoid re-downloading
export OQS_LIB_DIR="${PROJECT_DIR}/server_b/install/lib64"
export OQS_INCLUDE_DIR="${PROJECT_DIR}/server_b/install/include"
# Install oqs from the local zip file, forcing it to build against our liboqs
pip install /tmp/liboqs-python-0.10.0.zip
# Install the rest of the requirements
pip install -r ${PROJECT_DIR}/app/requirements.txt
pip install -r ${PROJECT_DIR}/attacker/requirements.txt
deactivate
echo ">>> Python environment setup complete."

# --- Step 6: Generate Certificates & Database ---
echo
echo ">>> STEP 6 of 6: Generating certificates and initializing database..."
bash ${PROJECT_DIR}/generate_certs.sh
python3 ${PROJECT_DIR}/database_setup.py
echo ">>> Certificates and database are ready."


echo
echo "=================================================="
echo ">>> FULL PROJECT SETUP COMPLETE!"
echo ">>> You are now ready to run the demonstration."
echo "=================================================="
