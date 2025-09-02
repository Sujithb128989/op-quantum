#!/bin/bash
#
# setup_msys2.sh
#
# This script should be run from an MSYS2 MINGW64 terminal.
# It installs all the necessary packages required to compile the project components,
# including liboqs, OpenSSL, and Nginx.
#

echo ">>> Starting dependency installation for the PQC Demo Project."
echo ">>> This may take a few minutes."

# Ensure the package database is up to date.
# The --noconfirm flag prevents it from asking for confirmation.
echo ">>> Updating package database and base packages..."
pacman -Syu --noconfirm

# Install the necessary toolchains and packages individually to avoid interactive prompts.
echo ">>> Installing required packages..."
pacman -S --needed --noconfirm \
    mingw-w64-x86_64-gcc \
    mingw-w64-x86_64-make \
    mingw-w64-x86_64-openssl \
    mingw-w64-x86_64-pcre \
    mingw-w64-x86_64-zlib \
    mingw-w64-x86_64-wireshark \
    git \
    cmake \
    python \
    perl \
    unzip

echo "=============================================================="
echo ">>> Dependency installation complete!"
echo ">>> You are now ready to run the build scripts."
echo "=============================================================="
