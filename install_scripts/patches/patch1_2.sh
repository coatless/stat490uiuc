#!/bin/sh
#############################
## patch1_2.sh
#############################
## James Joseph Balamuta
## james.balamuta@gmail.com
#############################
## Initial Release 1.0 -- 02/11/15
#############################
## Objective: Install Python 2.7.9 on CentOS 6.6 + pip and easy_install
#############################
## Warning: This may cause system instability. 
## This removes the core dependencies as being python 2.6.6 and install 2.7.9 in its place. 
## Note: yum is still using 2.6.6, however, we are removing the bin location of 2.6.6 when we insert 2.7.9 (which was installed locally).
#############################
## # Obtain Script
## wget https://raw.githubusercontent.com/coatless/stat490uiuc/master/install_scripts/patches/patch1_2.sh
## chmod u+x patch1_2.sh
## 
## # Launch Script
## ./patch1_2.sh

if [[ -n ${UIUC_IMAGE_VERSION+x} && "$UIUC_IMAGE_VERSION" == "STAT490 Image Version: 1.1" ]]; then 
	
	echo "Changing into user home directory to install..."

	cd ~/
	
	echo "Installing development tools to compile python with..."
	# Install all of the development tools to combat the _curses issue
	yum groupinstall -y -q development

	echo "Installing Modules required to compile python..."
	# Missing python libs
	yum install -y -q zlib-devel bzip2-devel openssl-devel xz-libs wget python-imaging ncurses-devel ncurses

	# Upgrade the kernel... This breaks something.
	# yum upgrade -y kernel

	echo 'Removing the old python installs in bin...' 

	# Remove old python bin.
	sudo rm -rf /usr/bin/python
	sudo rm -rf /usr/bin/pip  
	sudo rm -rf /usr/bin/easy_install  

	# Download the latest version of python
	wget -q https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tar.xz

	# Extract python
	tar -xf Python-2.7.9.tar.xz

	# Switch into the python directory
	cd ~/Python-2.7.9  

	echo 'Configuring python ssssssssssssssssss...' 

	# Run the configure script
	sudo ./configure  

	# Perform all the make operations
	echo 'Making files...' 

	make -s
	
	echo 'Making installing the made files...' 

	make -s install 

	echo 'Cleaning the made files...' 

	make -s clean
	
	echo 'Cleaning the dist made files...' 

	make -s distclean

	echo 'Creating a symbolic link for python in /usr/bin/ for shell access...' 

	# Create a symbolic link
	sudo ln -s /usr/local/bin/python2.7 /usr/bin/python

	echo 'Installing easy_setup and placing a symbolic link...' 

	# Install easy_setup
	wget -q https://bootstrap.pypa.io/ez_setup.py
	python ez_setup.py
	sudo ln -s /usr/local/bin/easy_install /usr/bin/easy_install

	echo 'Installing pip using easy_setup and placing a symbolic link...' 

	# Install pip
	easy_install -q pip
	sudo ln -s /usr/local/bin/pip /usr/bin/pip  

	echo 'Checking to see if new python version is installed...' 

	# Verify new version is installed
	python --version

	# Old vs. New Python
	line_old='python'
	line_new='python2.6'

	echo 'Modifying yum to use python v2.6.6 instead of v2.7.9...' 

	# Replace config so yum doesn't complain
	sudo sed -i "0,/$line_old/s//$line_new/" /usr/bin/yum  

	echo 'Installing ImportError: no module sh error fix...'
		
	# Resolves the sh load module error
	sudo pip install -q websocket-client
	sudo pip install -q --user sh
	
	echo 'Updating UIUC_IMAGE_VERSION to v1.2'; 

	sudo sed -i "s/UIUC_IMAGE_VERSION='STAT490 Image Version: 1.1'/UIUC_IMAGE_VERSION='STAT490 Image Version: 1.2'/g" $(R RHOME)/etc/Renviron
	sudo sed -i "s/UIUC_IMAGE_VERSION='STAT490 Image Version: 1.1'/UIUC_IMAGE_VERSION='STAT490 Image Version: 1.2'/g" /etc/profile
	
	echo "Changing into user home directory to remove install files..."

	cd ~/
	
	echo "Removing python install files and install directory..."

	rm -rf ~/Python-2.7.9.tar.xz
	rm -rf ~/Python-2.7.9
	
	echo 'Congratulations! You have been upgraded to UIUC_IMAGE_VERSION="STAT490 Image Version: 1.2"'

else 
	echo 'This patch is only meant to modify UIUC_IMAGE_VERSION="STAT490 Image Version: 1.1"'
	echo 'Please upgrade to 1.1 from 1.0 before trying to patch this version'
fi

echo "Tidying up by removing the patch1_2.sh script ..."

# Remove the patch1_2.sh script
rm -rf patch1_2.sh

