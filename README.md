# Work Time Tracker

A simple macOS-oriented shell script that summarizes your weekly and daily working time based on login sessions ("last"/"uptime") and allows manual corrections via per‑day adjustment files.

## Prerequisites
- macOS (uses BSD date flags like `-v` and the `last` command)
- zsh (default shell on modern macOS)

## Make the main script executable
If you just cloned or downloaded the repository, ensure the main script has execute permissions:

```
chmod +x ./main.sh
```

You can then run it with:

```
./main.sh
```

## Optional: Create a handy alias in your zshrc
To run the tracker from anywhere, add an alias to your `~/.zshrc`:

1. Open your zsh config file:
   
   ```
   nano ~/.zshrc
   ```

2. Add an alias line pointing to the absolute path of this repository's `main.sh`:
   
   ```
   alias wtt="/absolute/path/to/work-time-tracker/main.sh"
   ```
   
   Replace `/absolute/path/to/work-time-tracker` with the real path on your machine.

3. Reload your shell configuration:
   
   ```
   source ~/.zshrc
   ```

Now you can run the tracker from any directory with:

```
wtt
```

## Correcting a wrongly tracked time (Adjustments)
If you notice that the automatically calculated time for a specific day is wrong, you can correct it by creating a file named exactly as that date under the `adjustments` directory. The file content should be the difference you want to apply, expressed as time. This difference is added to that day's raw seconds before breaks are subtracted.

- Directory: `./adjustments/`
- File name: `YYYY-MM-DD` (e.g., `2025-08-30`)
- File content: a time difference, which can be positive or negative

### Supported time formats
The adjustment accepts several formats and converts them to seconds:
- `H:MM` (e.g., `1:30` for 1 hour 30 minutes)
- `H:MMh` (e.g., `1:30h`)
- `Hh` (e.g., `2h`)
- `Mmin` (e.g., `45min`)
- `Mm` (e.g., `45m`)
- Plain number of seconds (e.g., `900`)

You can prefix with `+` or `-` to add or subtract time:
- `+15m` means add 15 minutes to that day
- `-30min` means subtract 30 minutes from that day

### Example
Suppose the automatically calculated time for 2025-08-30 is off by minus 20 minutes. Create:

- File: `./adjustments/2025-08-30`
- Content: `-20m`

Or if you need to add 1 hour 15 minutes:

- File: `./adjustments/2025-08-30`
- Content: `+1:15`

The script will automatically read and apply the adjustment during its next run.

## How it works
- Reads recent login sessions for the current user via `last` and filters for console sessions.
- Aggregates per-day seconds for the current week (starting Monday).
- For each day, adds any matching adjustment from `./adjustments/YYYY-MM-DD`.
- Subtracts the configured break time per working day (default 30 minutes).
- Compares total weekly time against expected time (working days × 8h by default) and prints the difference and suggested leave time.

## Configuration
Edit `config.sh` to adjust work and break times (values are in seconds):
- `WORK_TIME_PER_DAY=28800` (8 hours)
- `BREAK_TIME_PER_DAY=1800` (30 minutes)

## Notes
- The tool expects BSD `date` flags (e.g., `-v`) available on macOS.
- Adjustment files should not have an extension—use the date only as the filename.
- Whitespace in adjustment files is trimmed; a blank or invalid value is treated as 0.

## Troubleshooting
- If `./main.sh` doesn’t run, ensure it’s executable and that your shell is zsh or bash on macOS.
- If your alias doesn’t work, check that the path in your `~/.zshrc` is correct and reload with `source ~/.zshrc`.
- To verify an adjustment is being read, ensure the filename matches the date exactly (`YYYY-MM-DD`) and the file resides under the `adjustments` folder at the repository root.
