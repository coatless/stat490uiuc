#!/bin/sh
#############################
## hdp_setup.sh
#############################
## James Joseph Balamuta
## james.balamuta@gmail.com
#############################
## Initial Release 1.1 -- 01/23/15
#############################
## Examples Uses
#############################
## # Obtain Script
## wget https://raw.githubusercontent.com/coatless/stat490uiuc/master/install_scripts/hdp_setup.sh
## chmod u+x hdp_setup.sh
## 
## # Default Setup
## ./hdp_setup.sh --rinstall --viminstall --rstudio --createuser --sudouser --sshuser --hpaths --rhadoop --rhpc
## # Installs R and RStudio Server (manual check needed for new releases)
## # Creates a new user: rstudio with password: rstudio
## # Sets up hadoop paths and install RHadoop (latest)
##
## # Complex Setup
## ./hdp_setup.sh --ssuite --rstudio --rstudio-port=8008 --rstudio-address=127.0.0.1 --createuser --user=james --user-pw=nottelling --sudouser --sshuser --hpaths --rhadoop
## # All of the default actions
## # Changes RStudio Server config to different values
## # Different user account is created 
##
## # Terminal R Only (No R Studio) with non-default user
## ./hdp_setup.sh --createuser --user=james --user-pw=nottelling --sudouser --sshuser --hpaths --rhadoop

# List of supported options with default values

# EMR Install?
EMRINSTALL=false

# For installing: R, vim, and 
RINSTALL=false
VIMINSTALL=false

# For installing R Studio Server
RSTUDIO=false
RSTUDIOADDRESS="0.0.0.0"
RSTUDIOPORT=8787

# User creation
CREATEUSER=false
USER='rstudio'
USERPW='rstudio'
SUDOUSER=false
SSHUSER=false

# For installing RHadoop ecosystem also installs curl-devel
HPATHS=false
RHADOOP=false
RHPC=false

# Change default values to specified.
while [ $# -gt 0 ]; do
	case "$1" in
		--emrinstall)
			EMRINSTALL=true
			;;
		--rinstall)
			RINSTALL=true
			;;
		--viminstall)
			VIMINSTALL=true
			;;	
		--rstudio)
			RSTUDIO=true
			;;
        --rstudio-port)
            shift
            RSTUDIOPORT=$1
            ;;
		--rstudio-address)
            shift
            RSTUDIOADDRESS=$1
            ;;
		--createuser)
		   CREATEUSER=true
		   ;;
		--user)
		   shift
		   USER=$1
		   ;;
   		--user-pw)
   		   shift
   		   USERPW=$1
   		   ;;
		--sudouser)
			SUDOUSER=true
		   ;;
		--sshuser)
			SSHUSER=true
		   ;;
		--hpaths)
			HPATHS=true
			;;
		--rhadoop)
			RHADOOP=true
			;;
		--rhpc)
			RHPC=true
			;;
		-*)
		   error_msg "Option not supported: $1"
		   ;;
		*)
		break;
		;;
	esac
	shift
done

# EMR Master Check
IS_MASTER=true
if [ "$EMRINSTALL" == true ]; then

	echo "Installing on EMR..."
	if [ -f /mnt/var/lib/info/instance.json ]; then 
		IS_MASTER=`cat /mnt/var/lib/info/instance.json | tr -d '\n ' | sed -n 's|.*\"isMaster\":\([^,]*\).*|\1|p'`
	fi
	
	# Install R from AWS Repository
	sudo yum update R-base -y -q
	
	# EMR permission fix
	sudo chmod 777 -R /mnt/var/lib/hadoop/tmp

	# Java compilation fix not needed, screws up path.
	#sudo R CMD javareconf
fi


# Install Applications
if [ "$RINSTALL" == true ]; then
	echo 'Installing R suite...' 

	sudo yum install -y -q R
fi

# Environmental variable set yet?
if [ -z ${UIUC_IMAGE_VERSION+x} ]; then 
	echo "First run detected .... "
	echo "Adding UIUC_IMAGE_VERSION environmental variable .... "
	# Add in a new environmental variable to indicate image version
	sudo sh -c "echo \"UIUC_IMAGE_VERSION='STAT490 Image Version: 1.1'\" >> $(R RHOME)/etc/Renviron"
	sudo sh -c "echo \"export UIUC_IMAGE_VERSION='STAT490 Image Version: 1.1'\" >> /etc/profile"
else 
	echo "The UIUC_IMAGE_VERSION variable has already been set to $UIUC_IMAGE_VERSION"; 
fi

# Install vim
if [ "$VIMINSTALL" == true ]; then
	echo 'Installing vim suite...' 

	sudo yum install -y -q vim
fi

# Install RStudio Server
if [ "$RSTUDIO" == true -a "$IS_MASTER" == true ]; then
	echo 'Installing R Studio Server...' 

	# Manually check to see if this is the latest release via: http://www.rstudio.com/products/rstudio/download-server/
	# Set up for CentOS x64
	sudo yum install -y -q openssl098e # Required only for RedHat/CentOS 6 and 7
	wget -O /tmp/rstudio-server-0.98.1091-x86_64.rpm http://download2.rstudio.org/rstudio-server-0.98.1091-x86_64.rpm
	sudo yum install -y -q --nogpgcheck /tmp/rstudio-server-0.98.1091-x86_64.rpm
	
	# Verify install
	sudo rstudio-server verify-installation
	
	# Change port away from default 8787
	if [ "$RSTUDIOPORT" != 8787 ]; then 
		echo "www-port=$RSTUDIOPORT" >> /etc/rstudio/rserver.conf
	fi
	
	# Change web address away from 0.0.0.0 to something more secure
	if [[ "$RSTUDIOADDRESS" != 0.0.0.0 ]]; then 
		echo "www-address=$RSTUDIOADDRESS" >> /etc/rstudio/rserver.conf
	fi
	
	# R Studio Respawning issue patch
	sudo sed -i "s/2345/345/g" /etc/init/rstudio-server.conf
	
	# Config change restart
	sudo rstudio-server restart
	
	echo '[tidying] Removing the image file ...'

	# Remove the install image (save about 50 mb)
	sudo rm -rf /tmp/rstudio-server-0.98.1091-x86_64.rpm
fi

if [ "$CREATEUSER" == true ]; then
	echo 'Trying to creating a user...'
	# Does the user exist? 
	if id -u $USER >/dev/null 2>&1; then
		echo 'User already exists.'
		echo 'If you are trying to change the password, use terminal command:'
		echo 'echo "USER:USERPW" | chpasswd'
	else
		echo 'User does not exist...'
		echo 'Adding user and initializing log directory...' 
		# Create user
		sudo useradd $USER
		
		# Apply password
		sudo sh -c "echo \"$USER:$USERPW\" | chpasswd"
	
		# Build directory path
		mkdir -p /var/log/hadoop/$USER

		# Allow ANYONE to write to any files within the directory
		sudo chown $USER:$USER -Rf /var/log/hadoop/$USER	
	fi
fi

# Give user sudo power
if [ "$SUDOUSER" == true ]; then
	echo 'Granting sudo user...'
	
	# Does the user already have sudo access? Y/N
	if sudo grep -q "$USER ALL=(ALL) ALL" /etc/sudoers; then
		echo "User $USER already has been granted sudo power"
	else
		sudo sh -c "echo \"$USER ALL=(ALL) ALL\" >> /etc/sudoers"
	fi
	
fi

# Grant SSH Permission
if [ "$SSHUSER" == true ]; then	
	echo 'Granting SSH permissions user...'
	
	# optimize?
	if sudo grep -q "AllowUsers root" /etc/ssh/sshd_config; then
		if sudo grep "AllowUsers root" /etc/ssh/sshd_config | grep -q "$USER"; then
			echo "User $USER already has been granted SSH access ..."
		else
			sudo sed -i "0,/AllowUsers root/s/AllowUsers root/AllowUsers root $USER/" /etc/ssh/sshd_config
		fi
	else
		sudo sh -c "echo \"\n# SSH Allowed Users\" >> /etc/ssh/sshd_config"
		sudo sh -c "echo \"AllowUsers root hadoop $USER\" >> /etc/ssh/sshd_config"
		sudo sh -c "echo \"ServerAliveInterval 60\" >> /etc/ssh/sshd_config"
	fi
	
fi


# Set paths and values for environmental variables
if [ "$HPATHS" == true ]; then
	echo 'Setting environement variables...' 

	# Location of R library
	RLIB_HOME=$(R RHOME)

	# Search for file path and take the last one.
	HADOOP_STREAMING=$(sudo find / -name 'hadoop-streaming.jar' | tail -n 1)
	HADOOP_CMD=$(sudo find / -name 'hadoop' | grep '/bin/hadoop' | tail -n 1)
	
	HADOOP_EXAMPLES=$(sudo find / -name 'hadoop-*examples.jar' | grep 'hadoop.*/hadoop-.*examples.jar' | head -n 1)

	# Conf file
	HADOOP_CONF=$(sudo find / -name 'conf' | grep 'hadoop/conf' | tail -n 1)
	
	# two possible implementations
	# Use tee
	# or sudo sh -c
	
	# R Studio Server Path Config
	sudo sh -c "echo -e \"\n# R Studio Server Path Config\" >> $RLIB_HOME/etc/Renviron"
	sudo sh -c "echo \"RLIB_HOME='$RLIB_HOME'\" >> $RLIB_HOME/etc/Renviron"
	sudo sh -c "echo \"HADOOP_STREAMING='$HADOOP_STREAMING'\" >> $RLIB_HOME/etc/Renviron"
	sudo sh -c "echo \"HADOOP_CMD='$HADOOP_CMD'\" >> $RLIB_HOME/etc/Renviron"
	sudo sh -c "echo \"HADOOP_CONF='$HADOOP_CONF'\" >> $RLIB_HOME/etc/Renviron"
	sudo sh -c "echo \"HADOOP_EXAMPLES='$HADOOP_EXAMPLES'\" >> $RLIB_HOME/etc/Renviron"
	sudo sh -c "echo \"JAVAC_HADOOP_PATH='$(hadoop classpath)'\" >> $RLIB_HOME/etc/Renviron"
	sudo sh -c "echo \"JAVA_TOOLS='$JAVA_HOME/lib/tools.jar'\" >> $RLIB_HOME/etc/Renviron"

	# Terminal R goodies
	sudo sh -c "echo -e \"\n# Terminal R goodies\" >> /etc/profile"
	sudo sh -c "echo \"export RLIB_HOME=$RLIB_HOME\" >> /etc/profile"
	sudo sh -c "echo \"export HADOOP_STREAMING=$HADOOP_STREAMING\" >> /etc/profile"
	sudo sh -c "echo \"export HADOOP_CMD=$HADOOP_CMD\" >> /etc/profile"
	sudo sh -c "echo \"export HADOOP_CONF=$HADOOP_CONF\" >> /etc/profile"
	sudo sh -c "echo \"export HADOOP_EXAMPLES=$HADOOP_EXAMPLES\" >> /etc/profile"
	sudo sh -c "echo \"export JAVAC_HADOOP_PATH=$(hadoop classpath)\" >> /etc/profile"
	sudo sh -c "echo \"export JAVA_TOOLS=$JAVA_HOME/lib/tools.jar\" >> /etc/profile"
	
	sudo sh -c "source /etc/profile"
fi

# Install RHadoop ecosystem
if [ "$RHADOOP" == true ]; then
	echo 'Installing rmr2, rhdfs, plyrmr, and R dependency packages...' 
	
	sudo yum install -y -q curl-devel
	
	sudo R --no-save << EOF
# Install dev tools
install.packages('devtools', repos="http://cran.us.r-project.org", INSTALL_opts=c('--byte-compile'))
	
# Install rmr2 dependencies
install.packages(c('RJSONIO', 'itertools', 'digest', 'Rcpp', 'functional', 'httr', 'plyr', 'stringr', 'reshape2', 'caTools', 'rJava'), repos="http://cran.us.r-project.org", INSTALL_opts=c('--byte-compile') )

# Install plyrmr dependencies
install.packages(c('dplyr', 'R.methodsS3', 'Hmisc'), repos="http://cran.us.r-project.org", INSTALL_opts=c('--byte-compile'))

# Install the RHadoop goodies (aka we do not care about version numbers..)
require('devtools')
install_github('RevolutionAnalytics/memoise', args=c('-–byte-compile'))
install_github('RevolutionAnalytics/rmr2', subdir='pkg', args=c('-–byte-compile'))
install_github('RevolutionAnalytics/rhdfs', subdir='pkg', args=c('-–byte-compile'))
install_github('RevolutionAnalytics/plyrmr', subdir='pkg', args=c('-–byte-compile'))
EOF
fi

if [ "$RHPC" == true ]; then
	echo 'Installing HPC packages ...'
	sudo R --no-save << EOF
# Installs some wonderful HPC Packages
install.packages(c('bigmemory','foreach','iterators','doMC','doSNOW','itertools'), repos='http://cran.us.r-project.org', INSTALL_opts=c('--byte-compile') )
EOF
fi

echo '[tidying] Removing the setup file ...'

sudo rm -rf hdp_setup.sh

# Done
echo 'Done.'
 