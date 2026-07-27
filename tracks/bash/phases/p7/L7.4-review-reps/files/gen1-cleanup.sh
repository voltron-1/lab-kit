#!/bin/bash
# TEACHING SAMPLE — deliberately flawed. Never run this.
# It exists to be read and reviewed, not executed.
# Disk cleanup script - keeps your log partition healthy!

LOG_DIR=$1
KEEP_DAYS=14

# Go to the log directory
cd $LOG_DIR

# Remove old rotated archives to free up space
rm -rf $OLD_DIR/*.gz

# Also clear anything older than the retention window
find . -name "*.log" -mtime +$KEEP_DAYS -delete

echo "Cleanup finished for $LOG_DIR"
