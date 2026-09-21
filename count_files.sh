#!/bin/bash

# Test comment

read -r -p "Enter the path to the directory [/etc]: " TARGET_DIR

TARGET_DIR="${TARGET_DIR:-/etc}"

if [ ! -d "$TARGET_DIR" ]; then
	echo "Error: directory $TARGET_DIR does not exist"
	exit 1
fi

count_items() {
	local dir=$1
	local type=$2
	local extension=$3

	if [ "$type" = "f" ] && [ -n "$extension" ]; then
		find "$dir" -type f -name "*.$extension" 2>/dev/null | wc -l
	else 
		find "$dir" -type "$type" 2>/dev/null | wc -l
	fi
}

total_size=$(find "$TARGET_DIR" -type f -name "*.*" -printf '%s\n' 2>/dev/null | awk '{sum += $1 / 1024} END {printf "%.2f", sum}')

files=$(count_items "$TARGET_DIR" "f")
dirs=$(count_items "$TARGET_DIR" "d")
links=$(count_items "$TARGET_DIR" "l")
extension=$(count_items "$TARGET_DIR" "f" "txt")

echo "Statistics for directory $TARGET_DIR:"
echo "Regular files: $files"
echo "Directories: $((dirs - 1))"
echo "Symbolic links: $links"
echo "FIles with extension conf: $extension"
echo "-------------------------"
echo "Total count (files only): $files"
echo "Total size: $total_size KB"

exit 0
