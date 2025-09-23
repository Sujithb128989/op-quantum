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
    LINE_COUNT=$(wc -l < "$LOG_FILE" | tr -d ' ')

    if [ "$LINE_COUNT" -ge "$MAX_REQUESTS" ]; then
      echo "server crashed"
      # Kill the parent process (start_server.sh), which will trigger the
      # trap and clean up everything gracefully. This is like sending Ctrl+C.
      kill $PPID
      break # Exit the watcher script
    fi
  fi
  # Check every 200ms
  sleep 0.2
done
