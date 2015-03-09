#!/bin/sh
#############################
## airlines_data.sh
#############################
## James Joseph Balamuta
## james.balamuta@gmail.com
#############################
## Initial Release 1.0 -- 03/06/15
#############################
## The objective of this file is to download the airlines data set through stat-computing.org
## The script will inflate the .bz2 archive.
## Furthermore, the script will create a master archive called airlines.csv containing all years requested.
#############################
## # Obtain Script
## wget https://raw.githubusercontent.com/coatless/stat490uiuc/master/airlines/airlines_data.sh
## chmod u+x airlines_data.sh
## 
## # Run the script
## ./airlines_data.sh <start year> <end year> 

# Global parameters
g_tmp_folder="airlines_tmp";
g_output_file="airlines.csv";

g_file_format=".csv";
g_zip_format=".bz2";
 
g_remote_host="http://stat-computing.org";
g_remote_path="dataexpo/2009";
 
 
# $1: folder_path
function create_folder {
    if [ -d "$1" ]; then
        rm -rf "$1";
    fi
    mkdir "$1"
}
 
# $1: year to download
function download_data {
    local source_url="$g_remote_host/$g_remote_path/$1"
	echo "Downloading... $1"
    wget "$source_url" -P "$g_tmp_folder";
}

# $1: year to unzip, append
function process_data {

	echo "Unzipping... $1"

	# unzip the files
	bzip2 -d $g_tmp_folder/$1$g_file_format$g_zip_format
	
	echo "Appending... $1 to $g_output_file"
	# Obtain the headers (creates new file)
	if [ $1 -eq $start_year ]; then
		head -1 $g_tmp_folder/$1$g_file_format > $g_output_file
	fi
	
	# Append data after the header (e.g. start on line 2)
	tail --lines=+2 -q $g_tmp_folder/$1$g_file_format >> $g_output_file
}
 
# $1 - start year
# $2 - finish year
function main {
    local start_year=1987
    local finish_year=2008
 
    if [ -n "$1" ]; then
        start_year=$1
    fi
 
    if [ -n "$2" ]; then
        finish_year=$2
    fi

	# store downloaded folder
    create_folder $g_tmp_folder
 
	# Download the data and append the data
	for year in `seq $start_year $finish_year`; do
        
		# Download the data
		download_data $year$g_file_format$g_zip_format
        local download_status=$?
        if [ $download_status -ne 0 ]; then
            >&2 echo "Could not download data for year $year. Status code: $download_status"
        fi
		
		# Append Data
		process_data $year
    done
	
	# Delete 
	rm -rf $g_tmp_folder
}
 
main $1 $2
