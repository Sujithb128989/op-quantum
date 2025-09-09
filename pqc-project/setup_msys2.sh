#!/bin/bash
#
# setup_msys2.sh
#
# This script should be run from an MSYS2 MINGW64 terminal.
# It installs all the necessary packages required to compile the project components.
#

echo ">>> Starting dependency installation for the PQC Demo Project."
echo ">>> This may take a few minutes."

# Update package database and upgrade the system.
# The --noconfirm flag prevents it from asking for confirmation.
echo ">>> Updating package database and base packages..."
pacman -Syu --noconfirm --needed

# Install the necessary toolchains and packages individually to avoid interactive prompts.
echo ">>> Installing required packages..."
pacman -S --noconfirm --needed \
    mingw-w64-x86_64-gcc \
    mingw-w64-x86_64-make \
    mingw-w64-x86_64-openssl \
    mingw-w64-x86_64-pcre \
    mingw-w64-x86_64-zlib \
    mingw-w64-x86_64-wireshark \
    git \
    cmake \
    python \
    mingw-w64-x86_64-python-pip \
    perl \
    unzip

echo "=============================================================="
echo ">>> Dependency installation complete!"
echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!! IMPORTANT !!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!!                                                      !!!"
echo "!!! You MUST close and reopen this MSYS2 terminal now    !!!"
echo "!!! for the newly installed programs to be available.    !!!"
echo "!!!                                                      !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
echo ">>> After restarting, you will be ready to run the build scripts."
echo "=============================================================="
