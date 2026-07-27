#!/bin/bash
# TEACHING SAMPLE — deliberately flawed. Never run this.
# It exists to be read and reviewed, not executed.
# AI-generated log ingest helper - converts your logs to ECS format!

INPUT=$1
FILTER=${2:-.}

# Use a temp file to stage the results
TMP=/tmp/ingest-work.json

# Process the input with the user's custom filter for flexibility!
cat $INPUT | while read line; do
    echo $line | jq -c "{\"@timestamp\": .ts, \"source.ip\": .src, \"event.action\": .action}" >> $TMP
done

# Apply the custom filter
eval "jq '$FILTER' $TMP"

echo "Done! Processed $(wc -l < $TMP) events"
