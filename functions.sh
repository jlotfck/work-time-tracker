#!/bin/bash

# Format the time in seconds to a human readable format (hh:mm)
format_time() {
  hours=$(($1 / 3600))
  minutes=$((($1 % 3600) / 60))

  echo "${hours}:$(printf "%02d" $minutes)h"
}

# Get the seconds from the uptime command
get_seconds_from_uptime() {
  # Calculate uptime and extract hours and minutes
  time=$(uptime | awk -F' up ' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')

  # Initialize hours and minutes with 0
  hours=0
  minutes=0

  # Check if the format is like "1:30"
  if [[ "$time" =~ ^[0-9]+:[0-9]+$ ]]; then
    hours=$(echo "$time" | cut -d':' -f1)
    minutes=$(echo "$time" | cut -d':' -f2)

  # Check if the format is like  "8hrs"
  elif [[ "$time" =~ ^[0-9]+hrs$ ]]; then
    hours="${time//hrs/}"

  # Check if the format is like  "45mins"
  elif [[ "$time" =~ ^[0-9]+mins$ ]]; then
    minutes="${time//mins/}"
  fi

  # Convert to decimal
  minutes=$((10#$minutes))

  # Convert into seconds
  seconds=$(( hours * 3600 + minutes * 60))

  echo "$seconds"
}

# Subtract the break time from the given time in seconds
subtract_break() {
  time="$1"
  # Only subtract the break if the work time today is greater than the break
  if [[ "$time" -gt "$BREAK_TIME_PER_DAY" ]]; then
    # Subtract break time
    time=$((time - BREAK_TIME_PER_DAY))
  fi

  echo "$time"
}

# Get adjustment value in seconds from adjustment file with given filename
getAdjustment() {
  local filename="$1"

  # Check if filename parameter is provided
  if [[ -z "$filename" ]]; then
    echo "Error: Filename parameter is required" >&2
    return 1
  fi

  # Construct the file path
  adjustment_file="$BASE_DIR/adjustments/${filename}"

  # Check if the file exists
  if [[ -f "$adjustment_file" ]]; then
    # Read the content of the file and trim whitespace
    local content=$(cat "$adjustment_file" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Convert time string to seconds
    local seconds=$(parse_time_to_seconds "$content")
    echo "$seconds"
  else
    # Return 0 if file doesn't exist
    echo "0"
  fi
}

# Parse time string to seconds (supports various formats)
parse_time_to_seconds() {
  local time_str="$1"
  local seconds=0
  local sign=1

  # Check for negative or positive sign
  if [[ "$time_str" == -* ]]; then
    sign=-1
    time_str="${time_str#-}"
  elif [[ "$time_str" == +* ]]; then
    sign=1
    time_str="${time_str#+}"
  fi

  # Format: h:mm or h:mm:ss (e.g., "1:30", "0:30")
  if [[ "$time_str" =~ ^[0-9]+:[0-9]+$ ]]; then
    local hours=$(echo "$time_str" | cut -d':' -f1)
    local minutes=$(echo "$time_str" | cut -d':' -f2)
    seconds=$((hours * 3600 + minutes * 60))

  # Format: h:mmh (e.g., "1:30h")
  elif [[ "$time_str" =~ ^[0-9]+:[0-9]+h$ ]]; then
    local time_part="${time_str%h}"
    local hours=$(echo "$time_part" | cut -d':' -f1)
    local minutes=$(echo "$time_part" | cut -d':' -f2)
    seconds=$((hours * 3600 + minutes * 60))

  # Format: Xh (e.g., "1h", "2h")
  elif [[ "$time_str" =~ ^[0-9]+h$ ]]; then
    local hours="${time_str%h}"
    seconds=$((hours * 3600))

  # Format: Xmin (e.g., "30min", "45min")
  elif [[ "$time_str" =~ ^[0-9]+min$ ]]; then
    local minutes="${time_str%min}"
    seconds=$((minutes * 60))

  # Format: Xm (e.g., "30m", "2m")
  elif [[ "$time_str" =~ ^[0-9]+m$ ]]; then
    local minutes="${time_str%m}"
    seconds=$((minutes * 60))

  # Format: plain number (assume seconds)
  elif [[ "$time_str" =~ ^[0-9]+$ ]]; then
    seconds="$time_str"

  else
    # Invalid format, return 0
    seconds=0
  fi

  # Apply sign and return
  echo $((sign * seconds))
}
