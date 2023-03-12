#!/bin/bash

## use: bash run_files.sh file1.sh file2.sh

# Loop through each argument passed in
for file in "$@"
do
    # Check if the file exists
    if [ -f "$file" ]; then
        # Make the file executable
        chmod +x "$file"
        # Execute the file
        "./$file"
    else
        echo "File $file not found"
    fi
done
