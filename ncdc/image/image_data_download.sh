#!/bin/sh
#############################
## hdp_setup.sh
#############################
## James Joseph Balamuta
## james.balamuta@gmail.com
#############################
## Initial Release 1.0 -- 01/23/15
#############################
## Objective:
## Download the weather data from NOAA
## Process the data using ncdc_data.sh
## Put the data onto hdfs
## Observe locations on hdfs
#############################


# Change directory
cd ~/workspace/input/ncdc

# Download the following script
wget https://raw.githubusercontent.com/coatless/stat490uiuc/master/ncdc/image/ncdc_data.sh

# Allow the script the ability to run.
chmod u+x ncdc_data.sh

# We will use this script to:
# Download a weather dataset from the National Climatic Data Center (NCDC, http://www .ncdc.noaa.gov/). 
# Prepare it for examples of "Hadoop: The Definitive Guide" book by Tom White.
# The weather period we are interested in is from 1901 to 1910
./ncdc_data.sh 1901 1910

# We now need to put the files on HDFS
hdfs dfs -put ~/workspace/input/ncdc/all /user/rstudio/gz/	

# We will now interact with the Hadoop Distributed File System (HDFS)
# Commands for HDFS are available at:
# http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/FileSystemShell.html

# Let's see the directory contents
hdfs dfs -ls

hdfs dfs -ls /user/rstudio

# By default, hdfs will place files in your home directory (e.g. /user/rstudio)
# If you add a /, this will place the files in root directory (e.g. /)!

# Note, the files we recently downloaded are here!
hdfs dfs -ls /user/rstudio/gz