# Finds the HIVE install directory
HIVE_HOME=$(find / -name 'hive' | grep '/bin/hive' | head -n 1)

# Uses parameter expansion to remove the /bin/hive part
export HIVE_HOME=${HIVE_HOME/\/bin*/}

# Returns /usr/hdp/2.2.0.0-2041/hadoop/bin/hadoop
HADOOP_HOME=$(find / -name 'hadoop' | grep 'hadoop/bin')

# Uses parameter expansion to remove the /bin/hadoop part
export HADOOP_HOME=${HADOOP_HOME/\/bin*/}

export HADOOP_CONF_DIR=$HADOOP_CONF

# Where is R Located?
R_HOME=$(R RHOME)

# Place R_HOME into hadoop config location
sudo sh -c "echo \"R_HOME=$R_HOME\" >> $HADOOP_HOME/conf/hadoop-env.sh"

# Add variables to Renviron and /etc/profile

# HIVE_HOME set variable
sudo sh -c "echo \"export HIVE_HOME=$HIVE_HOME\" >> /etc/profile"
sudo sh -c "echo \"export HIVE_HOME='$HIVE_HOME'\" >> $R_HOME/etc/Renviron"

# HADOOP_HOME set variable
sudo sh -c "echo \"export HADOOP_HOME=$HADOOP_HOME\" >> /etc/profile"
sudo sh -c "echo \"export HADOOP_HOME='$HADOOP_HOME'\" >> $R_HOME/etc/Renviron"

# HADOOP_CONF_DIR set variable
sudo sh -c "echo \"export HADOOP_CONF_DIR=$HADOOP_CONF_DIR\" >> /etc/profile"
sudo sh -c "echo \"export HADOOP_CONF_DIR='$HADOOP_CONF_DIR'\" >> $R_HOME/etc/Renviron"


# Add remote enable to Rserve config.
sudo sh -c "echo 'remote enable' >> /etc/Rserv.conf"

# Launch the daemon
R CMD Rserve

# Confirm launch
netstat -nltp

#if [ "$RHIVE" == true ]; then

# Install ant to build java files
echo '[SYS] Installing ant ... '
sudo yum -y install ant

echo '[R] Installing RHive package dependencies (rJava, Rserve, RUnit)...'
sudo R --no-save << EOF
# Installs some wonderful HPC Packages
install.packages( c('rJava','Rserve','RUnit'), repos='http://cran.us.r-project.org', INSTALL_opts=c('--byte-compile') )
EOF

# Install RHive package
echo '[GIT] Obtaining RHive package...'
git clone https://github.com/nexr/RHive.git
echo '[R] Compiling RHive package...'
cd RHive
ant build
echo '[R] Installing RHive package...'
sudo R CMD INSTALL RHive

echo '[R] Installing RHive package...'
sudo R --no-save << EOF
require('devtools')
install_github('RevolutionAnalytics/memoise', args=c('-–byte-compile'))
EOF
#fi


sudo R --no-save << EOF
Sys.setenv(HIVE_HOME="/usr/hdp/2.2.0.0-2041/hive")
Sys.setenv(HADOOP_HOME="/usr/hdp/2.2.0.0-2041/hadoop")
Sys.setenv(HADOOP_CONF_DIR="/etc/hadoop/conf")
library(RHive)
rhive.init()
rhive.connect(host="localhost",port=10000, hiveServer2=TRUE)
EOF