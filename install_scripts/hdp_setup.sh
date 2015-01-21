#!/bin/sh
##
## hdp_setup.sh
##
## James Joseph Balamuta
## james.balamuta@gmail.com
##
## Initial Release 1.0 -- 01/20/15
##
## To use the script:
## wget hdp_setup.sh
## chmod u+x hdp_setup.sh


# List of supported options with default values

# For installing SSUITE: R, vim, and curl-devel
SSUITE=false

# For installing R Studio Server
RSTUDIO=false
RSTUDIOADDRESS="0.0.0.0"
RSTUDIOPORT=8787
CREATEUSER=false
USER='rstudio'
USERPW='rstudio'
SUDOUSER=false

# For installing RHadoop ecosystem
HPATHS=false
RHADOOP=false

# Change default values to specified.
while [ $# -gt 0 ]; do
	case "$1" in
		--ssuite)
			SSUITE=true
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
		--hpaths)
			HPATHS=true
			;;
		--rhadoop)
			RHADOOP=true
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

# Install Applications
if [ "$SSUITE" == true ]; then
	echo 'Installing software suite...' 

	sudo yum install -y -q R vim curl-devel
fi

# Install RStudio Server
if [ "$RSTUDIO" == true ]; then
	echo 'Installing R Studio Server...' 

	# Manually check to see if this is the latest release via: http://www.rstudio.com/products/rstudio/download-server/
	# Set up for CentOS x64
	sudo yum install -y -q openssl098e # Required only for RedHat/CentOS 6 and 7
	wget -O /tmp/rstudio-server-0.98.1091-x86_64.rpm http://download2.rstudio.org/rstudio-server-0.98.1091-x86_64.rpm
	sudo yum install -y -q --nogpgcheck /tmp/rstudio-server-0.98.1091-x86_64.rpm
	
	# Verify install
	sudo rstudio-server verify-installation
	
	# Change port away from default 8787
	if ["$RSTUDIOPORT" != 8787]; then 
		echo "www-port=$RSTUDIOPORT" >> /etc/rstudio/rserver.conf
	fi
	
	# Change web address away from 0.0.0.0 to something more secure
	if [["$RSTUDIOADDRESS" != 0.0.0.0]]; then 
		echo "www-address=$RSTUDIOADDRESS" >> /etc/rstudio/rserver.conf
	fi
	
	# R Studio Respawning issue patch
	sed -i "s/2345/345/g" /etc/init/rstudio-server.conf
	
	# Config change restart
	sudo rstudio-server restart
fi

if [ "$CREATEUSER" == true ]; then
	echo 'Trying to creating a user...'
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
		echo "$USER:$USERPW" | chpasswd
			
		# Build directory path
		mkdir -p /var/log/hadoop/$USER

		# Allow ANYONE to write to any files within the directory
		sudo chown $USER:$USER -Rf /var/log/hadoop/$USER	
	fi
fi

if [ "$SUDOUSER" == true ]; then
	echo 'Granting sudo user...'
	
	# Give user sudo power
	echo "$USER ALL=(ALL) ALL" >> /etc/sudoers
fi

# Install Applications
if [ "$HPATHS" == true ]; then
	echo 'Setting Hadoop paths for RHadoop...' 

	# Not necessarily the most efficient way of getting R_HOME. 
	RLIB_HOME=$(R RHOME)

	# Search for file path and take the last one.
	HADOOP_STREAMING=$(find / -name 'hadoop-streaming*.jar' | grep 'hadoop-mapreduce/hadoop-streaming.*.jar' | tail -n 1)
	HADOOP_CMD=$(find / -name 'hadoop' | grep '/bin/hadoop' | tail -n 1)

	# R Studio Server Path Config
	echo "HADOOP_STREAMING=$HADOOP_STREAMING" >> $RLIB_HOME/etc/Renviron
	echo "HADOOP_CMD=$HADOOP_CMD" >> $RLIB_HOME/etc/Renviron
	
	# Terminal R goodies
	echo "HADOOP_STREAMING=$HADOOP_STREAMING" >> /etc/profile
	echo "HADOOP_CMD=$HADOOP_CMD" >> /etc/profile
	
fi

# Install RHadoop ecosystem
if [ "$RHADOOP" == true ]; then
	echo 'Installing rmr2, rhdfs, plyrmr, and R dependency packages...' 
	sudo R --no-save << EOF
# Install dev tools
install.packages('devtools', repos="http://cran.us.r-project.org")
	
# Install rmr2 dependencies
install.packages(c('RJSONIO', 'itertools', 'digest', 'Rcpp', 'functional', 'httr', 'plyr', 'stringr', 'reshape2', 'caTools', 'rJava'), repos="http://cran.us.r-project.org", INSTALL_opts=c('--byte-compile') )

# Install plyrmr dependencies
install.packages(c('dplyr', 'R.methodsS3', 'Hmisc'), repos="http://cran.us.r-project.org", INSTALL_opts=c('--byte-compile')

# Install the RHadoop goodies (aka we do not care about version numbers..)
require('devtools')
install_github('RevolutionAnalytics/memoise')
install_github('RevolutionAnalytics/rmr2', subdir='pkg')
install_github('RevolutionAnalytics/rhdfs', subdir='pkg')
install_github('RevolutionAnalytics/plyrmr', subdir='pkg')

# Installs some wonderful HPC Packages
install.packages(c('bigmemory','foreach','iterators','doMC','doSNOW','itertools'), repos='http://cran.us.r-project.org', INSTALL_opts=c('--byte-compile') )
EOF
fi

# Done
echo 'Done.'
 