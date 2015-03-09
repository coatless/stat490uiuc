#!/bin/bash

#############################
## process_airlines.sh
#############################
## James Joseph Balamuta
## james.balamuta@gmail.com
#############################
## Initial Release 1.0 -- 03/06/15
#############################
## The objective of this file is to process the airlines data set available at stat-computing.org
## There are two functions:
## clean_ext - handles data cleaning for years 2004 - 2008
## clean_sm - handles data cleaning for years 1987 - 2003
#############################
## # Obtain Script
## wget https://raw.githubusercontent.com/coatless/stat490uiuc/master/airlines/process_airlines.sh
## chmod u+x process_airlines.sh
## 
## # handles data cleaning for years 2004 - 2008
## ./process_airlines.sh clean_ext
##
## # handles data cleaning for years 1987 - 2003
## ./process_airlines.sh clean_sm


# Global parameters
g_input_file="airlines.csv";
g_output_file="airlines_clean.csv";
 
# Handles data cleaning for years 2004 - 2008
# Removes lines
function clean_ext {
	cut -d "," -f1- | awk -F, `(!/NA/) \
	{ \
		if(length($5)==3 && substr($5,2,2)<=59) { \
			print $1","$2","$3","$4","substr($5,1,1)","$6","$7","$8","$9","$10","$11","$12","$13","$14","$15","$16","$17","$18","$19","$20","$21","$22","$23","$24","$25","$26","$27","$28","$29"\n" \
		} else if(length($5)==4 && substr($5,1,2)<=24 && substr($5,3,2)<=59) { \
			print $1","$2","$3","$4","substr($5,1,2)","$6","$7","$8","$9","$10","$11","$12","$13","$14","$15","$16","$17","$18","$19","$20","$21","$22","$23","$24","$25","$26","$27","$28","$29"\n" \
		} \ 
	}` $g_input_file > $g_output_file
}
 
# Handles data cleaning for years 1987 - 2003
# This function will truncate the non-used variables
function clean_sm {
	cut -d "," -f1-23,25 | awk -F, `(!/NA/) \
	{ \
		if(length($5)==3 && substr($5,2,2)<=59) { \
			print $1","$2","$3","$4","substr($5,1,1)","$6","$7","$8","$9","$10","$11","$12","$13","$14","$15","$16","$17","$18","$19","$20","$21","$22","$23","$24"\n" \
		} else if(length($5)==4 && substr($5,1,2)<=24 && substr($5,3,2)<=59) { \
			print $1","$2","$3","$4","substr($5,1,2)","$6","$7","$8","$9","$10","$11","$12","$13","$14","$15","$16","$17","$18","$19","$20","$21","$22","$23","$24"\n" \
		} \ 
	}` $g_input_file > $g_output_file
}
