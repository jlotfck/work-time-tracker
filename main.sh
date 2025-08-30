#!/bin/bash

# ========== Setup ==========
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$BASE_DIR/config.sh"
source "$BASE_DIR/functions.sh"

# ========== Main ==========
main() {
    # Get the last 20 log entries for the user and filter by 'console'
    last_output=$(last -s -y -n 50 "$USER" | grep console)

    # Get the date of the last Monday in the format YYYY-MM-DD
    last_monday=$(date -v Mon +%Y-%m-%d)
    # Get the current date in the format YYYY-MM-DD
    current_date=$(date +%Y-%m-%d)

    # Initialize variables
    working_days=0
    work_time_today=0
    work_time_week=0
    last_date="2000-01-01"

    # Loop through each line of the last output
    while IFS= read -r line; do
      # Extract the date from the line (e.g., "19 Mar 2025")
      date=$(echo "$line" | awk '{print $4, $5, $6}')
      # Format the extracted date to YYYY-MM-DD
      formated_date=$(date -j -f "%d %b %Y" "$date" "+%Y-%m-%d")

      # Check if the formatted date is greater than or equal to the last Monday
      if [[ "$formated_date" > "$last_monday" || "$formated_date" == "$last_monday" ]]; then
        adjustment_value=0
        # Only add a working day when the entry is a different date
        if [[ "$last_date" != "$formated_date" ]]; then
          ((working_days++))
          adjustment_value=$(getAdjustment "$formated_date")
        fi

        # set current date to last date to compare in the next iteration
        last_date=$formated_date

        # Extract the seconds of the session from the line
        seconds=$(echo "$line" | awk -F '[()]' '{print $2+0}')

        # If no session time is provided (seconds = 0), use seconds from uptime command
        if [ "$seconds" -eq 0 ]; then
          # Use uptime command to get the work time in seconds
          seconds=$(get_seconds_from_uptime)
        fi

        # Add adjustment value from file to seconds
        seconds=$((seconds + $adjustment_value))

        # Update work time for today when the date is the current date
        if [[ "$formated_date" == "$current_date" ]]; then
          work_time_today=$((seconds + work_time_today))
        fi

        # Add the work time of the day to the total work time
        work_time_week=$((work_time_week + seconds))

      fi
    done <<< "$last_output"

    # Subtract the break time from the work time today
    work_time_today=$(subtract_break $work_time_today)

    # Subtract the break time for each working day from the work time of the week
    for ((i=0; i<working_days; i++)); do
        work_time_week=$(subtract_break "$work_time_week")
    done

    # Calculate the expected working time
    expected_working_time=$((working_days * WORK_TIME_PER_DAY))

    # Calculate the difference between actual and expected working time
    time_difference=$((work_time_week - expected_working_time))

    # Output the total working time
    echo "Arbeitszeit: $(format_time "$work_time_week") ($(format_time "$work_time_today"))"

    # If the difference is positive, set the color to green, otherwise red
    if [ "$time_difference" -ge 0 ]; then
      colour="\033[0;32m"
      current_leave_time=$(date -v -${time_difference}S +"%H:%M")
    else
      colour="\033[0;31m"

      # Convert to positive for display
      time_difference=$(( -time_difference ))
      current_leave_time=$(date -v +${time_difference}S +"%H:%M")
    fi

    # Output the time difference with the appropriate color
    echo -e "Differenz: ${colour}$(format_time $time_difference)\033[0m"

    # Set the normal leave time
    if [ "$work_time_today" -ge 28800 ]; then
      normal_leave_time=$(date -v -$(( work_time_today - 28800 ))S +"%H:%M")
    else
      normal_leave_time=$(date -v +$((28800 - work_time_today))S +"%H:%M")
    fi

    echo "Arbeitszeitende: ${current_leave_time} Uhr (${normal_leave_time} Uhr)"
}

main "$@"
