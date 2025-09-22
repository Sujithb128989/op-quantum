#!/bin/bash
#
# setup_ubuntu.sh
#
# This script should be run on a Debian-based Linux distribution (like Ubuntu).
# It installs all the necessary packages required to compile the project components.
#

echo ">>> Starting dependency installation for the PQC Demo Project on Debian/Ubuntu."
echo ">>> This may require sudo privileges to install packages."

# Update package database
sudo apt-get update

# Install all necessary build tools and libraries
sudo apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    git \
    python3-venv \
    python3-pip \
    libssl-dev \
    unzip \
    wget \
    perl

echo "=============================================================="
echo ">>> Dependency installation complete!"
echo ""
echo ">>> You are now ready to run the build scripts."
echo "=============================================================="
