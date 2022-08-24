#!/bin/bash

#################
#    CONSTANTS
#################

hash_list=$(mktemp)
hash_duplicates=$(mktemp)
temp_duplicates=$(mktemp)

#################
#    FUNCTIONS
#################

# Each line would be like 
#   854756a168777a8becc9d906f34b541b7f79047f  ./XXX/XXX/XXX.JPG
get_hash_list() {
	find . | while read file; do 
		if [[ ! -d $file ]]; then
			sha1sum "$file"
		fi
	done
}

get_duplicates() {
	cat $1 | cut -d ' ' -f 1 | sort | uniq -c | grep -Ev '^ * 1 ' | rev | cut -d ' ' -f 1 | rev 
} 

delete_duplicates() {
	deleted_files=0

	while read dup; do
		count=1
		grep "$dup" $1 > $temp_duplicates
		
		while read file_hash; do
			if [[ $count -eq 1 ]]; then
				count=$((count + 1))
				continue
			else 
				file="$(echo "$file_hash" | cut -d ' ' -f 3-)"
				rm "$file"
				if [[ $? != 0 ]]; then 
					echo "Error deleting the file $file"
					exit 1
				fi
				deleted_files=$((deleted_files + 1))
			fi
		done < $temp_duplicates
	done < $2

	echo "${deleted_files} files have been deleted"
}

delete_empty_dirs() {
	deleted_dirs=0
	

	while [[ $(find . -type d -empty | wc -l) -gt 0 ]]; do
		find . -type d -empty > $temp_duplicates
		while read d; do
			rmdir "$d"
			if [[ $? != 0 ]]; then 
				echo "Error deleting the directory $d"
				exit 2
			fi
			deleted_dirs=$((deleted_dirs + 1))
		done < $temp_duplicates
	done

	echo "${deleted_dirs} empty directories have been deleted"
}

clean_tmp() {
	rm -f hash_list
	rm -f hash_duplicates
	rm -f temp_duplicates
}

###############
#    MAIN
###############

get_hash_list > $hash_list

get_duplicates $hash_list > $hash_duplicates

delete_duplicates $hash_list $hash_duplicates

delete_empty_dirs

clean_tmp

exit 0
