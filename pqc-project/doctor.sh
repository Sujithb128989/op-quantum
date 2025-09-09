#!/bin/bash
#
# doctor.sh
#
# This script checks the local MSYS2 environment to ensure all necessary
# build tools are installed and available in the system's PATH.
#

echo "=============================================================="
echo ">>> Running PQC Demo Project Environment Doctor"
echo "=============================================================="
echo

# --- Helper Function ---
# A function to check for a command and print its status.
check_command() {
    local cmd_name=$1
    local status="NOT FOUND"
    local path_info=""

    if command -v "$cmd_name" >/dev/null 2>&1; then
        status="OK"
        path_info="($(command -v "$cmd_name"))"
        return 0
    else
        status="ERROR: NOT FOUND"
        return 1
    fi
    printf "%-10s | %-20s | %s\n" "$cmd_name" "$status" "$path_info"
}

# --- Main Checks ---
all_ok=true
printf "%-10s | %-20s | %s\n" "COMMAND" "STATUS" "PATH"
echo "--------------------------------------------------------------"

if ! check_command "gcc"; then all_ok=false; fi
if ! check_command "make"; then all_ok=false; fi
if ! check_command "cmake"; then all_ok=false; fi
if ! check_command "python"; then all_ok=false; fi
if ! check_command "pip"; then all_ok=false; fi
if ! check_command "rustc"; then all_ok=false; fi
if ! check_command "git"; then all_ok=false; fi
if ! check_command "wget"; then all_ok=false; fi
if ! check_command "tar"; then all_ok=false; fi
if ! check_command "unzip"; then all_ok=false; fi
if ! check_command "perl"; then all_ok=false; fi

echo "--------------------------------------------------------------"
echo

# --- PATH Inspection ---
echo ">>> For debugging, here is your current PATH variable:"
echo "$PATH" | tr ":" "\n"
echo
echo "--------------------------------------------------------------"


# --- Summary ---
if [ "$all_ok" = true ]; then
    echo ">>> SUCCESS: Your environment appears to have all necessary tools."
    echo ">>> You should be able to proceed with the setup and build."
else
    echo ">>> ERROR: One or more required commands were not found."
    echo ">>> This indicates that './setup_msys2.sh' did not complete successfully,"
    echo ">>> or you have not restarted your terminal after running it."
    echo ">>> Please ensure the setup script runs without errors, then close and"
    echo ">>> reopen your MSYS2 MINGW64 terminal and run this doctor script again."
fi

echo "=============================================================="
