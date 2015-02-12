#!/bin/sh
#############################
## centos_python_clean_build.sh
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
## wget https://raw.githubusercontent.com/coatless/stat490uiuc/master/install_scripts/patches/centos_python_clean_build.sh
## chmod u+x centos_python_clean_build.sh
## 
## # Launch Script
## ./centos_python_clean_build.sh

# Install all of the development tools to combat the _curses issue
yum groupinstall -y development

# Missing python libs
yum install -y zlib-devel bzip2-devel openssl-devel xz-libs wget python-imaging ncurses-devel ncurses

# Upgrade the kernel... This breaks something.
# yum upgrade -y kernel

# Remove old python bin.
sudo rm -rf /usr/bin/python
sudo rm -rf /usr/bin/pip  
sudo rm -rf /usr/bin/easy_install  
sudo rm -rf /usr/bin/python  

# Download the latest version of python
wget https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tar.xz

# Extract python
tar xvf Python-2.7.9.tar.xz

# Switch into the python directory
cd Python-2.7.9  

# Run the configure script
sudo ./configure  

# Perform all the make operations
make
make install 
make clean
make distclean

# Create a symbolic link
sudo ln -s /usr/local/bin/python2.7 /usr/bin/python

# Install easy_setup
wget https://bootstrap.pypa.io/ez_setup.py
python ez_setup.py
sudo ln -s /usr/local/bin/easy_install /usr/bin/easy_install

# Install pip
easy_install pip
sudo ln -s /usr/local/bin/pip /usr/bin/pip  

# Verify new version is installed
python --version

# Old vs. New Python
line_old='python'
line_new='python2.6'

# Replace config so yum doesn't complain
sudo sed -i "0,/$line_old/s//$line_new/" /usr/bin/yum  

# Resolves the sh load module error
sudo pip install websocket-client
sudo pip install --user sh