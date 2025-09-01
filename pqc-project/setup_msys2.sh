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

# Install the necessary toolchains and packages.
#
# - mingw-w64-x86_64-toolchain: Contains the C/C++ compiler (gcc) and other tools
#   needed to build 64-bit Windows applications.
# - git: For cloning the source code from GitHub.
# - cmake: A build system generator required by liboqs.
# - python: Required for the Flask backend application and the attacker script.
# - perl: Required by the OpenSSL configuration script.
# - unzip: For decompressing source archives (like Nginx).
#
# Using --needed will skip installing packages that are already present and up to date.
echo ">>> Installing required packages (gcc, make, git, cmake, python, perl)..."
pacman -S --needed --noconfirm \
    mingw-w64-x86_64-toolchain \
    mingw-w64-x86_64-openssl \
    mingw-w64-x86_64-pcre \
    mingw-w64-x86_64-zlib \
    mingw-w64-x86_64-wireshark-cli \
    git \
    cmake \
    python \
    perl \
    unzip

echo "=============================================================="
echo ">>> Dependency installation complete!"
echo ">>> You are now ready to run the build scripts."
echo "=============================================================="
