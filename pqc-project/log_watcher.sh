#!/bin/bash
#
# log_watcher.sh
#
# This script monitors an Nginx access log file and kills the
# corresponding Nginx process when the request count reaches a limit.
#
set -eu

# --- Configuration ---
LOG_FILE=$1
PID_FILE=$2
MAX_REQUESTS=500

if [ -z "$LOG_FILE" ] || [ -z "$PID_FILE" ]; then
    echo "Usage: $0 <path_to_access_log> <path_to_pid_file>"
    exit 1
fi

# --- Main Loop ---
while true; do
  # Check if the log file exists yet
  if [ -f "$LOG_FILE" ]; then
    # Get the line count (number of requests)
    # Use awk for efficiency, as it stops after counting
    LINE_COUNT=$(wc -l < "$LOG_FILE" | tr -d ' ')

    if [ "$LINE_COUNT" -ge "$MAX_REQUESTS" ]; then
      echo ">>> Request limit of ${MAX_REQUESTS} reached for ${LOG_FILE}. Shutting down server."
      # Read PID from file and kill the process
      if [ -f "$PID_FILE" ]; then
        kill $(cat "$PID_FILE")
        echo ">>> Shutdown signal sent."
      else
        echo ">>> PID file ${PID_FILE} not found!"
      fi
      break # Exit the watcher script
    fi
  fi
  # Check every 200ms
  sleep 0.2
done
