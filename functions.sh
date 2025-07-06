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