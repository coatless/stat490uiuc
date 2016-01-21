#!/usr/bin/env bash

#############################
## ncdc_data.sh
#############################
## This file was provided by GitHub users: rehevkor5 and Alexander-Ignatyev
## The file has been modified so that:
##  default values for year are 1901 and 1910
##  default output folder is all
#############################
## Initial Release 1.0 -- 01/22/15 by James Balamuta
## Version 1.1 -- 01/08/16 by Darren Glosemeyer
##	- script changed to not automatically overwrite existing parent data directory; 
##	  this avoids removal of existing files from years not included in the range of years;
##	  existing directories can be quickly manually deleted if desired
##	- changed process_data to remove existing year.zip file before adding to it;
##	  this avoids duplication of data that already exists;
##	  the assumption is that if a user has asked for that year's data they want a 
##	  fresh download of the files
##	- changed the code to use curl -O instead of wget because wget is not available
##	  in the new container being used
#############################
## The objective of this file is to download the ncdc weather data directly through NOAA.
## This avoids the use of Amazon's S3 file storage system. 
## Therefore, the script will work on virtual boxes given by HDP, Cloudera, and MapR
## The script mimics the default processing by the book without using hadoop.
#############################
## # Obtain Script
## curl -O https://raw.githubusercontent.com/coatless/stat490uiuc/master/ncdc/image/ncdc_data.sh
## chmod u+x ncdc_data.sh
## 
## # Run the script
## ./ncdc_data.sh <start year> <end year> 

# Global parameters
g_tmp_folder="ncdc_tmp";
g_output_folder="all";
 
g_remote_host="ftp.ncdc.noaa.gov";
g_remote_path="pub/data/noaa";
 
 
# $1: folder_path
function create_folder {
    if [ -d "$1" ]; then
        rm -rf "$1";
    fi
    mkdir "$1"
}
 
# $1: year to download
function download_data {
    local source_url="ftp://$g_remote_host/$g_remote_path/$1"
    local currentdir=$(pwd)
## Note the directory creation and changing is used so the curl'ed files are placed in 
## the directory expected by the processing code. If wget is available on the system,
## everything from
##  	local currentdir=...
## through 
##	cd $currentdir 
## can be replaced with
##	wget -r -c -q --no-parent -P "$g_tmp_folder" "$source_url";
##
     	mkdir -p $g_tmp_folder/$g_remote_host/$g_remote_path/$year
	cd $g_tmp_folder/$g_remote_host/$g_remote_path/$year
	echo "Downloading... $1"
# Following replacement for recursive wget is based on suggestion by quanta on
# http://serverfault.com/questions/326852/curl-ftp-ssl-to-grab-all-files-in-remote-directory
	curl -s $source_url/ | grep -e '^-' | awk '{ print $9 }' |
	  while read f; 
		do curl -s -o $f $source_url/$f;
	  done
	cd $currentdir
}
 
# $1: year to process
function process_data {
    local year="$1"
    local local_path="$g_tmp_folder/$g_remote_host/$g_remote_path/$year"
    local tmp_output_file="$g_tmp_folder/$year"
    for file in $local_path/*; do
        gunzip -c $file >> "$tmp_output_file"
    done
    zipped_file="$g_output_folder/$year.gz"
    # if the zip file already exists, remove it to avoid duplicating data
    rm -f $zipped_file
    gzip -c "$tmp_output_file" >> "$zipped_file"
    echo "Created file: $zipped_file"

	rm -rf "$local_path"
    rm "$tmp_output_file"
}
 
# $1 - start year
# $2 - finish year
function main {
    local start_year=1901
    local finish_year=1910
 
    if [ -n "$1" ]; then
        start_year=$1
    fi
 
    if [ -n "$2" ]; then
        finish_year=$2
    fi
 
    create_folder $g_tmp_folder
    
    if [ -d "$g_output_folder" ]; then
        echo "Parent directory already exists."
        else
        echo "Creating parent directory."
        create_folder $g_output_folder
    fi
    
    for year in `seq $start_year $finish_year`; do
        download_data $year
        local download_status=$?
        if [ $download_status -eq 0 ]; then
            process_data $year
        else
            >&2 echo "Could not download data for year $year. Status code: $download_status"
        fi
    done
 
    rm -rf "$g_tmp_folder"
}
 
main $1 $2
