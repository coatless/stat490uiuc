#!/usr/bin/env bash

#############################
## ncdc_data.sh
#############################
## This file was provided by GitHub users: rehevkor5 and Alexander-Ignatyev
## The file has been modified so that:
##  default values for year are 1901 and 1910
##  default output folder is all
#############################
## Initial Release 1.0 -- 01/22/15
#############################
## The objective of this file is to download the ncdc weather data directly through NOAA.
## This avoids the use of Amazon's S3 file storage system. 
## Therefore, the script will work on virtual boxes given by HDP, Cloudera, and MapR
#############################
## # Obtain Script
## wget https://raw.githubusercontent.com/coatless/stat490uiuc/master/ncdc/ncdc_data.sh
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
    wget -r -c -q --no-parent -P "$g_tmp_folder" "$source_url";
	echo "Downloading... $1"
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
    gzip -c "$tmp_output_file" >> "$zipped_file"
    echo "Created file: $zipped_file"
 
    hdfs dfs -put $zipped_file gz/$year.gz	
    echo "Put file on hdfs: gz/$year.gz"

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
    create_folder $g_output_folder
 
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