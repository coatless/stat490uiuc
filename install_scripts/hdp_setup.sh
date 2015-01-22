#!/bin/sh
#############################
## hdp_setup.sh
#############################
## James Joseph Balamuta
## james.balamuta@gmail.com
#############################
## Initial Release 1.0 -- 01/20/15
#############################
## Examples Uses
#############################
## # Obtain Script
## wget https://raw.githubusercontent.com/coatless/stat490uiuc/master/install_scripts/hdp_setup.sh
## chmod u+x hdp_setup.sh
## 
## # Default Setup
## ./hdp_setup.sh --ssuite --rstudio --createuser --sudouser --hpaths --rhadoop
## # Installs R and RStudio Server (manual check needed for new releases)
## # Creates a new user: rstudio with password: rstudio
## # Sets up hadoop paths and install RHadoop (latest)
##
## # Complex Setup
## ./hdp_setup.sh --ssuite --rstudio --rstudio-port=8008 --rstudio-address=127.0.0.1 --createuser --user=james --user-pw=nottelling --sudouser --hpaths --rhadoop
## # All of the default actions
## # Changes RStudio Server config to different values
## # Different user account is created 
##
## # Terminal R Only (No R Studio) with non-default user
## ./hdp_setup.sh --createuser --user=james --user-pw=nottelling --sudouser --hpaths --rhadoop

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

# Set paths for RHadoop
if [ "$HPATHS" == true ]; then
	echo 'Setting Hadoop paths for RHadoop...' 

	# Location of R library
	RLIB_HOME=$(R RHOME)

	# Search for file path and take the last one.
	HADOOP_STREAMING=$(find / -name 'hadoop-streaming*.jar' | grep 'hadoop-mapreduce/hadoop-streaming.*.jar' | tail -n 1)
	HADOOP_CMD=$(find / -name 'hadoop' | grep '/bin/hadoop' | tail -n 1)
	
	HADOOP_EXAMPLES=$(find / -name 'hadoop-mapreduce-examples*.jar' | head -n 1)

	# Conf file
	HADOOP_CONF='/etc/hadoop/conf'
	
	# R Studio Server Path Config
	echo "RLIB_HOME=$RLIB_HOME" >> $RLIB_HOME/etc/Renviron
	echo "HADOOP_STREAMING=$HADOOP_STREAMING" >> $RLIB_HOME/etc/Renviron
	echo "HADOOP_CMD=$HADOOP_CMD" >> $RLIB_HOME/etc/Renviron
	echo "HADOOP_CONF=$HADOOP_CONF" >> $RLIB_HOME/etc/Renviron
	echo "HADOOP_EXAMPLES=$HADOOP_EXAMPLES" >> $RLIB_HOME/etc/Renviron
	echo "JAVAC_HADOOP_PATH=$(hadoop classpath)" >> $RLIB_HOME/etc/Renviron
	echo "JAVA_TOOLS=$JAVA_HOME/lib/tools.jar" >> $RLIB_HOME/etc/Renviron

	
	# Terminal R goodies
	echo "RLIB_HOME=$RLIB_HOME" >> /etc/profile
	echo "HADOOP_STREAMING=$HADOOP_STREAMING" >> /etc/profile
	echo "HADOOP_CMD=$HADOOP_CMD" >> /etc/profile
	echo "HADOOP_CONF=$HADOOP_CONF" >> /etc/profile
	echo "HADOOP_EXAMPLES=$HADOOP_EXAMPLES" >> /etc/profile
	echo "JAVAC_HADOOP_PATH=$(hadoop classpath)" >> /etc/profile
	echo "JAVA_TOOLS=$JAVA_HOME/lib/tools.jar" >> /etc/profile
	
fi

# Install RHadoop ecosystem
if [ "$RHADOOP" == true ]; then
	echo 'Installing rmr2, rhdfs, plyrmr, and R dependency packages...' 
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

# Installs some wonderful HPC Packages
install.packages(c('bigmemory','foreach','iterators','doMC','doSNOW','itertools'), repos='http://cran.us.r-project.org', INSTALL_opts=c('--byte-compile') )
EOF
fi

# Done
echo 'Done.'
 