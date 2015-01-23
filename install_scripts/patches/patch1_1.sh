#!/bin/sh
#############################
## patch1_1.sh
#############################
## James Joseph Balamuta
## james.balamuta@gmail.com
#############################
## Patch 1.1 for Image 1.0 -- 01/23/15
#############################
## Objective: 
## Patch the image to export environmental variables
## Added UIUC_IMAGE_VERSION variable
## Added SSH support for rstudio
## Remove hdp_setup script and patch1_1 script once done.
#############################
## # Instructions
## # Log into the image as root and run...
## # Obtain Script
## wget https://raw.githubusercontent.com/coatless/stat490uiuc/master/install_scripts/patches/patch1_1.sh
## chmod u+x patch1_1.sh
## 
## # Launch Script
## ./patch1_1.sh

echo "Starting Patch1_1 for UIUC HDP Image"

# Is the image version string set?
if [ -z ${UIUC_IMAGE_VERSION+x} ]; then 

	echo "Patching UIUC_IMAGE_VERSION version 1.0 .... "

	echo "Adding UIUC_IMAGE_VERSION environmental variable .... "
	# Add in a new environmental variable to indicate image version
	echo "UIUC_IMAGE_VERSION='STAT490 Image Version: 1.1'" >> $(R RHOME)/etc/Renviron
	echo "export UIUC_IMAGE_VERSION='STAT490 Image Version: 1.1'" >> /etc/profile

	echo "Modifying /etc/profile variables to be prefixed with export .... "
	
	# Modify environmental variables in /etc/profile to be exported
	# Finds the first instance of each variable and replaces it with export prefixed to variable name
	sed -i "0,/RLIB_HOME/s/RLIB_HOME/export RLIB_HOME/" /etc/profile
	sed -i "0,/HADOOP_STREAMING/s/HADOOP_STREAMING/export HADOOP_STREAMING/" /etc/profile
	sed -i "0,/HADOOP_CMD/s/HADOOP_CMD/export HADOOP_CMD/" /etc/profile
	sed -i "0,/HADOOP_CONF/s/HADOOP_CONF/export HADOOP_CONF/" /etc/profile
	sed -i "0,/HADOOP_EXAMPLES/s/HADOOP_EXAMPLES/export HADOOP_EXAMPLES/" /etc/profile
	sed -i "0,/JAVAC_HADOOP_PATH/s/JAVAC_HADOOP_PATH/export JAVAC_HADOOP_PATH/" /etc/profile
	sed -i "0,/JAVA_TOOLS/s/JAVA_TOOLS/export JAVA_TOOLS/" /etc/profile

	echo "Adding rstudio user to the allowed SSH user file ... "
	# Add user to SSH file
	echo -e "\n# SSH for rstudio" >> /etc/ssh/sshd_config
	echo "AllowUsers rstudio" >> /etc/ssh/sshd_config
	
	echo "Removing the hdp_setup.sh script ..."
	# Remove the hdp_setup.sh script
	rm -rf hdp_setup.sh
else 
	echo 'This patch is only meant to modify UIUC_IMAGE_VERSION="STAT490 Image Version: 1.0"'; 
fi

echo "Tidying up by removing the patch1_1.sh script ..."

# Remove the patch1_1.sh script
rm -rf patch1_1.sh

echo 'Congratulations! You have been upgraded to UIUC_IMAGE_VERSION="STAT490 Image Version: 1.1"'