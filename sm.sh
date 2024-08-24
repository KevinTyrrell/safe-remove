#!/bin/bash

# A safer alternative to 'rm' in Bash
# Copyright (C) 2024  Kevin Tyrrell
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# ======================================
# User-configurable variables
# ======================================

# Number of days before items are purged from the recycle bin
# Note: Items are only purged upon this program being called
EXPIRATION_WINDOW_DAYS=30
# When enabled (1), prompts & warns the user which files will be deleted
SAFE_MODE=0

# ======================================
# End of user-configurable variables
# ======================================

show_help() {
  cat <<EOF
Usage: $(basename "$0") [options] [arguments]

A safer alternative to 'rm' in Bash.
Moves files to your Recycle Bin (/recycle) in \$HOME.
Removes files through 'rm' once they have expired.

Options:
  -h, --help    Show this help message and exit
  -n, --no-op	Runs without performing operations on the parameters

Arguments:
  file1 file2 ...  Files to be recycled

Example:
  $(basename "$0") file1.txt file2.txt
  
Author: Kevin Tyrrell
EOF
}

NO_OP=false  # Optional flag to run program without an operation taking place.

check_params() {
	for arg; do
		# Switched to 'printf' instead of echo to avoid '-n' recognized as newline.
		local lc=$(printf '%s' "$arg" | tr '[:upper:]' '[:lower:]')
		if [ "$lc" = "--help" ] || [ "$lc" = "-h" ]; then
			show_help; exit 0; fi
		if [ "$lc" = "--no-op" ] || [ "$lc" = "-n" ]; then
			NO_OP=true; fi  # Perform no operation this runtime.
	done
}

# Logs a message of a specified severity, terminating the program if severe
log() {
	local PROG_NAME="Safe Remove"
	local levels=("info" "warning" "fatal")
	local severity="$1"
	local format="$2"
	shift 2  # Allow varargs to be used by removing the first two params
	printf "[$PROG_NAME] ${levels[$severity]}: $format\n" "$@"
	[ "$severity" -gt 1 ] && exit 1 # Fatal errors are non-recoverable
}

# Ensures Recycle Bin is instantiated and path is valid
load_recycle() {
	local home="$(eval echo ~)"
	local recycle="$home/recycle"
	if [ ! -e "$recycle" ]; then
		log 0 "Recycle DNE -- Creating: %s" "$recycle/"
		mkdir "$recycle"
		[ ! -d "$recycle" ] && log 2 "failed to create directory: %s" "$recycle/"
	elif [ -f "$recycle" ]; then
		log 2 "path already exists: %s" "$recycle/"
	fi
	
	recycle_path="$recycle"
}

declare -A db_ts_by_file  # Create an associative array [filename]->[timestamp]

# Iterates through the database, recording key/value pairs
read_db() {
    while IFS= read -r line; do
        # Split the line by the character "/"
        IFS="/" read -ra parts <<< "$line"
		db_ts_by_file[${parts[0]}]=${parts[1]}
    done < "$db_file"
}

# Cleans the DB of any stale entries
clean_db() {
	# Edge Case: Capitalization in the NTFS, FAT32, etc file systems.
	# Some file systems are case-insensitive, partically Windows.
	# 'A.txt' and 'a.txt' could both exist at the same time in the DB,
	# yet both point to the same file. At best this would cause a stale
	# reference in the DB, and at worst it may lead to an unexepcted deletion.
	# Therefore, we have to go to lengths to ensure case-specific accuracy.
	declare -A files
	shopt -s dotglob  # Enable iteration of hidden files
	for file in "$recycle_path"/*; do
		local base="$(basename "$file")"
		if [[ ! -v files["$base"] ]]; then  # Should always be true
			files["$base"]=1; fi  # Set, value is always 1
	done
	shopt -u dotglob  # Disable iteration of hidden files
	
	for base in "${!db_ts_by_file[@]}"; do
		# Instead of checking the directory itself (case insensitive),
		# check the associative array if file exists (case sensitive).
		if [[ ! -v files["$base"] ]]; then
			# If file no longer exists, remove the stale entry.
			# Note: omitting character \" causes files with apostrophe to fail to be unset.
			unset "db_ts_by_file[\"$base\"]"
		fi
	done
}

# Checks recycle for files which were not added by this program
update_db() {
	shopt -s dotglob  # Enable iteration of hidden files
	for file in "$recycle_path"/*; do
		local base="$(basename "$file")"  
		if [ "$base" != ".recycle_db" ]; then  # .recycle_db is reserved
			if [[ ! -v  db_ts_by_file["$base"] ]]; then
				db_ts_by_file["$base"]=$ts_now
			fi
		fi
	done
	shopt -u dotglob  # Disable iteration of hidden files
}

# Creates or loads the database in which file metadata is stored
load_db() {
	local db=".recycle_db"
	db_file="$recycle_path/$db"
	
	if [ ! -e "$db_file" ]; then
		log 0 "DB DNE -- Creating: %s" "$db_file"
		touch "$db_file"
		[ ! -f "$db_file" ] && log 2 "failed to create DB: %s" "$db_file"
	else
		read_db
		clean_db
	fi
	update_db
}

# Saves the database to the recycle's metadata file
save_db() {
	if [ ! -d "$recycle_path" ]; then  # This should never happen
		load_recycle; fi  # Instead of fail-fast, attempt to recover
	#echo > "$db_file"  # Erase all content in the database
	printf "" > "$db_file"  # Erase all content in the database
	for base in "${!db_ts_by_file[@]}"; do
		local ts="${db_ts_by_file[$base]}"
		#log 0 "Saving [key=%s,value=%d] to db" "$base" $ts
		echo "$base/$ts/" >> "$db_file"
	done
}

# Determines if it is safe to remove files from the recycle
check_safety() {
	local death_row=("$@")
	if [ $SAFE_MODE -eq 1 ]; then  # Safe mode is enabled
		for base in "${death_row[@]}"; do
			log 1 "file scheduled for deletion: %s" "$recycle_path/$base"
		done

		read -p ">>> Purge all of the above files from the recycle? (y/n): " confirm
		if [[ ! "$confirm" =~ ^[Yy]$ ]]; then return; fi
	fi
	SAFE_MODE=0  # Double-dip on the variable to return 0
}

# Deletes a file from the recycle
erase_file() {
	local base=$1
	local file="$recycle_path/$base"
	rm --preserve-root -r "$file"
	if [ ! -e "$file" ]; then
		unset "db_ts_by_file[$base]"  # Remove file from database
	else log 1 "deletion failed: %s" "$file"; fi
}

# Removes elements from the storage medium which are past their expiration
purge() {
	local death_row=()  # Filenames which are to-be purged
	for base in "${!db_ts_by_file[@]}"; do
		ts="${db_ts_by_file[$base]}"
		if [ ! $ts -gt $ts_expire ]; then  # File is past its expiration date
			death_row+=("$base"); fi  # Mark file for deletion
	done
	
	if [ ! "${#death_row[@]}" -eq 0 ]; then
		check_safety "${death_row[@]}"  # Pass ALL elements of the list to funct
		if [ ! $SAFE_MODE -eq 1 ]; then
			for base in "${death_row[@]}"; do
				erase_file "$base"
			done
		else log 1 "purge was canceled by user."; fi
	fi
}

# Returns a new name for a specified file, avoiding name conflicts
rename() {
	local base="$(basename "$1")"
	local name="${base%.*}"
	local ext=".${base##*.}"
	[ "$base" == "$name" ] && ext=""  # No extension detected
	
	# Check if filename already is of the form: Name (#)
	local proto_name; local counter
	if [[ "$name" =~ ^(.+)(\(([0-9]+)\))$ ]]; then
		proto_name="${BASH_REMATCH[1]}"
		counter="${BASH_REMATCH[3]}"
	else
		proto_name="$name"
		counter=0
	fi
	
	while true; do
		((counter++))  # Keep trying names until availability is found
		name="$proto_name($counter)$ext"
		if [[ ! -v  db_ts_by_file["$name"] ]]; then
			echo "$name"; return 0; fi
	done
}

# Moves the specified file into the recycle
put() {
	local file_path="$1"
	if [ -e "$file_path" ]; then
		local base="$(basename "$1")"
		if [[ -v db_ts_by_file["$base"] ]]; then
			base=$(rename "$file_path"); fi  # Resolve name conflict
		mv "$file_path" "$recycle_path/$base"
		if [ -e "$recycle_path/$base" ]; then
			db_ts_by_file["$base"]=$ts_now
		else log 1 "file was unable to be moved to recycle: %s" "$file_path"; fi
	else log 1 "file path is invalid: %s" "$file_path"; fi
}

main() {
	ts_now=$(date +%s)  # Unix Timestamps, now & max limit for purge
	ts_expire=$((ts_now - $EXPIRATION_WINDOW_DAYS * 24 * 60 * 60))

	check_params "$@"
	load_recycle
	load_db
	
	purge
	if ! $NO_OP; then  # Perform no operation if flag is set
		put "$1"; fi  # TODO: Allow for varargs
	save_db
}

main "$@"
exit 0
