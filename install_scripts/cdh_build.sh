# Building the image

# The documentation that this script follows is located here
# http://www.cloudera.com/content/www/en-us/documentation/enterprise/latest/topics/cdh_qs_yarn_pseudo.html
#
# Port information about the CDH is given here:
# http://www.cloudera.com/content/www/en-us/documentation/enterprise/latest/topics/cdh_ig_ports_cdh5.html


# Log in as root
sudo bash

# UID
USER=nombre

# Configures mysql/mariadb
DATABASE_PASS=db

# Disable firewalld at the moment
systemctl disable firewalld
systemctl stop firewalld

sudo yum clean all

#########################################
# Devtools

sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm

sudo yum -y install tcl

# Make sure repos are up to date
sudo yum clean all

# Required
sudo yum -y install R git ant maven make gcc-c++ gcc binutils libX11-devel libXpm-devel libXft-devel libXext-devel

# Recommended
sudo yum -y install gcc-gfortran openssl-devel pcre-devel mesa-libGL-devel glew-devel ftgl-devel mysql-devel \
fftw-devel cfitsio-devel graphviz-devel avahi-compat-libdns_sd-devel libldap-dev python-devel libxml2-devel gsl-static


# RStudio Server Install
wget https://download2.rstudio.org/rstudio-server-rhel-0.99.491-x86_64.rpm
sudo yum -y install --nogpgcheck rstudio-server-rhel-0.99.491-x86_64.rpm

rm -rf rstudio-server-rhel-0.99.491-x86_64.rpm

#########################################
# Updating JAVA & Setting PATH variables

# First download the latest Java build...
sudo yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel

# Set alternative to using this version
sudo alternatives --set java /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.65-2.b17.el7_1.x86_64/jre/bin/java

# Set up a Java Environmental variables derived from: which java
touch java.sh

cat <<EOF >> java.sh
JAVA_HOME=/usr/lib/jvm/java-1.8.0/bin/java
JRE_HOME=/usr/lib/jvm/java-1.8.0/jre/bin/java
PATH=\$PATH:\$JAVA_HOME:\$JRE_HOME
EOF

# Move it to java.sh profile
sudo mv java.sh /etc/profile.d/java.sh

############################################
# Obtain CDH repo
############################################

curl -O https://archive.cloudera.com/cdh5/one-click-install/redhat/7/x86_64/cloudera-cdh-5-0.x86_64.rpm

# Add Repository
sudo rpm --import http://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/RPM-GPG-KEY-cloudera

sudo yum -y --nogpgcheck localinstall cloudera-cdh-5-0.x86_64.rpm

##############################################
# mariadb / mysql
##############################################

sudo rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm

sudo yum -y install mysql-community-server

systemctl enable mysqld


# MariaDB JDBC driver
# Download at: http://www.mysql.com/downloads/connector/j/5.1.html

sudo wget http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.31.tar.gz && tar zxvf mysql-connector-java-5.1.31.tar.gz
sudo mkdir -p /usr/share/java/
sudo cp mysql-connector-java-5.1.31/mysql-connector-java-5.1.31-bin.jar /usr/share/java/mysql-connector-java.jar

sudo systemctl start mysqld

# Automated mysql_secure_installation
mysqladmin -u root password "$DATABASE_PASS"
mysql -u root -p"$DATABASE_PASS" -e "UPDATE mysql.user SET Password=PASSWORD('$DATABASE_PASS') WHERE User='root'"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

sudo systemctl stop mysqld

#################################################
#################################################

###################################
# CDH Component Install
###################################

####################
# Hadoop (MR + HDFS)
#####################
sudo yum -y install hadoop-conf-pseudo

# Files in the right place?
rpm -ql hadoop-conf-pseudo

# Formate the namenode
sudo -u hdfs hdfs namenode -format

# Start HDFS
for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x start ; done

# Create directories for hadoop processes
sudo /usr/lib/hadoop/libexec/init-hdfs.sh

# Verify the HDFS file structure
sudo -u hdfs hadoop fs -ls -R /

# Spin YARN
sudo service hadoop-yarn-resourcemanager start
sudo service hadoop-yarn-nodemanager start 
sudo service hadoop-mapreduce-historyserver start

# New user
sudo -u hdfs hadoop fs -mkdir /user/$USER
sudo -u hdfs hadoop fs -chown $USER /user/$USER

# Fix for HDFS file structure script
sudo -u hdfs hadoop fs -mkdir /user/hive/warehouse
sudo -u hdfs hadoop fs -chown 1777 /user/hive/warehouse


# Stop services
for x in `cd /etc/init.d ; ls hadoop-*` ; do sudo service $x stop ; done

##############################

# Temp

export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce


################################
# Install components
################################


################################
# Zookeeper
################################

sudo yum -y install zookeeper zookeeper-server

# Setup zookeeper permissions

sudo mkdir -p /var/lib/zookeeper
sudo chown -R zookeeper /var/lib/zookeeper/

# Spin up Zookeeper
sudo service zookeeper-server init --myid=1
sudo service zookeeper-server start
sudo service zookeeper-server stop


# Zookeeper REST Server
git clone https://github.com/apache/zookeeper

active=$(pwd)
cd zookeeper
sudo ant

cd src/contrib/rest
nohup ant run >/dev/null 2>&1 &

cd $active

#################################
# HttpFS
#################################

sudo yum -y install hadoop-httpfs

# Note: HttpFS already configured with proxy user.

##########
# Hbase
##########
sudo yum -y install hbase

# Requires root
sudo cat <<EOF >> /etc/security/limits.conf
hdfs  -       nofile  32768
hdfs  -       nproc   2048
hbase -       nofile  32768
hbase -       nproc   2048
EOF

# Add an upper bound on HDFS data node files

sudo sed -i 's|</configuration>||' /etc/hadoop/conf/hdfs-site.xml

# Add WebHDFS to hdfs-site.xml
sudo cat <<EOF >> /etc/hadoop/conf/hdfs-site.xml
    <property>
        <name>dfs.datanode.max.transfer.threads</name>
        <value>4096</value>
    </property>

</configuration>
EOF

# HBase is now in standalone mode.
# Need to switch it to pseudo-clustered mode
# Note: fs.defaultFS in /conf/core-site.xml is given as
# localhost:8020

sudo yum -y install hbase-master

sudo sed -i 's|</configuration>||' /etc/hbase/conf/hbase-site.xml

sudo cat <<EOF >> /etc/hbase/conf/hbase-site.xml
    <property>
        <name>hbase.cluster.distributed</name>
        <value>true</value>
    </property>
    <property>
        <name>hbase.rootdir</name>
        <value>hdfs://localhost:8020/hbase</value>
    </property>

</configuration>
EOF

# Install Regionserver
sudo yum -y install hbase-regionserver

# Install Thrift
sudo yum -y install hbase-thrift

# HBase REST Server
sudo yum -y install hbase-rest

sudo sed -i 's|</configuration>||' /etc/hbase/conf/hbase-site.xml

sudo cat <<EOF >> /etc/hbase/conf/hbase-site.xml
    <property>
        <name>hbase.rest.port</name>
        <value>60050</value>
    </property>

</configuration>
EOF


#####################
# Install Hive
#####################
sudo yum -y install hive hive-metastore hive-server2 hive-hbase

# The following warning applies to any collections configured to
# use Non-SolrCloud mode. Any such collection configuration will
# need to be upgraded, see Upgrading Cloudera Search for details.

# We may want to add memory controls

# Recommend to darren he use beeline instead of hive
# Start beeline WITH connection: beeline -u jdbc:hive2://

# Configuring Hive Metastore to not use derby :'(

# Follows n.n.n
HIVE_VERSION=1.1.0
HIVE_HOST=localhost

# Setup JDBC driver for hive
ln -s /usr/share/java/mysql-connector-java.jar /usr/lib/hive/lib/mysql-connector-java.jar

# Fix for local directory issue

## sudo sed -i 's|hive-txn-schema-0.13.0.mysql.sql|/usr/lib/hive/scripts/metastore/upgrade/mysql/hive-txn-schema-0.13.0.mysql.sql|' /usr/lib/hive/scripts/metastore/upgrade/mysql/hive-schema-1.1.0.mysql.sql

cd /usr/lib/hive/scripts/metastore/upgrade/mysql

sudo systemctl start mysqld

# Create the database
mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE metastore; USE metastore; SOURCE /usr/lib/hive/scripts/metastore/upgrade/mysql/hive-schema-$HIVE_VERSION.mysql.sql;"

# Create a user
mysql -u root -p"$DATABASE_PASS" -e "CREATE USER 'hive'@'localhost' IDENTIFIED BY '$DATABASE_PASS'; REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'hive'@'$HIVE_HOST'; GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'$HIVE_HOST'; FLUSH PRIVILEGES;"

sudo systemctl stop mysqld

cd $OLDPWD

# Switch to using mysql

# Changes connection URL ( > if you switch hive_host, you will need to change this! < )
sudo sed -i 's|jdbc:derby:;databaseName=/var/lib/hive/metastore/metastore_db;create=true|jdbc:mysql://localhost/metastore|' /usr/lib/hive/conf/hive-site.xml

# Remove ConnectionDriver
sudo sed -i 's|org.apache.derby.jdbc.EmbeddedDriver|com.mysql.jdbc.Driver|' /usr/lib/hive/conf/hive-site.xml

sudo sed -i 's|</configuration>||' /usr/lib/hive/conf/hive-site.xml

sudo cat <<EOF >> /usr/lib/hive/conf/hive-site.xml
	<property>
	  <name>javax.jdo.option.ConnectionUserName</name>
	  <value>hive</value>
	</property>

	<property>
	  <name>javax.jdo.option.ConnectionPassword</name>
	  <value>$DATABASE_PASS</value>
	</property>

	<property>
	  <name>datanucleus.autoCreateSchema</name>
	  <value>false</value>
	</property>

	<property>
	  <name>datanucleus.fixedDatastore</name>
	  <value>true</value>
	</property>

	<property>
	  <name>datanucleus.autoStartMechanism</name> 
	  <value>SchemaTable</value>
	</property> 

	<property>
	  <name>hive.metastore.uris</name>
	  <value>thrift://localhost:9083</value>
	  <description>IP address (or fully-qualified domain name) and port of the metastore host</description>
	</property>

	<property>
		<name>hive.metastore.schema.verification</name>
		<value>true</value>
	</property>

</configuration>
EOF



######################
# Pig
######################

sudo yum -y install pig

########################
# Oozie
########################



sudo yum -y install oozie oozie-client

# Alternatives
alternatives --set oozie-tomcat-conf /etc/oozie/tomcat-conf.http

# Associate the mysql connector with oozie
ln -s /usr/share/java/mysql-connector-java.jar /var/lib/oozie/mysql-connector-java.jar

# Create Oozie Database and Oozie MariaDB User
sudo systemctl start mysqld

mysql -u root -p"$DATABASE_PASS" -e "create database oozie; grant all privileges on oozie.* to 'oozie'@'localhost' identified by 'oozie'; grant all privileges on oozie.* to 'oozie'@'%' identified by 'oozie';"


# Modify property file
sudo sed -i 's|</configuration>||' /etc/oozie/conf/oozie-site.xml

sudo cat <<EOF >> /etc/oozie/conf/oozie-site.xml
    <property>
        <name>oozie.service.JPAService.jdbc.driver</name>
        <value>com.mysql.jdbc.Driver</value>
    </property>
    <property>
        <name>oozie.service.JPAService.jdbc.url</name>
        <value>jdbc:mysql://localhost:3306/oozie</value>
    </property>
    <property>
        <name>oozie.service.JPAService.jdbc.username</name>
        <value>oozie</value>
    </property>
    <property>
        <name>oozie.service.JPAService.jdbc.password</name>
        <value>oozie</value>
    </property>
	
</configuration>
EOF

# Oozie Database Schema
sudo -u oozie /usr/lib/oozie/bin/ooziedb.sh create -run


### Enabling the Oozie Web console

# ExtJs
sudo wget -qO- -O tmp.zip https://archive.cloudera.com/gplextras/misc/ext-2.2.zip && unzip tmp.zip -d /var/lib/oozie && rm -rf tmp.zip

# Spin up HDFS
for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x start ; done

# Install the Oozie ShareLib in Hadoop HDFS
sudo -u hdfs hadoop fs -mkdir /user/oozie
sudo -u hdfs hadoop fs -chown oozie:oozie /user/oozie


# FS_URI = fs.defaultFS in core-site.xml, which is hdfs://localhost:8020

# Why this approach does not work: http://blog.cloudera.com/blog/2014/05/how-to-use-the-sharelib-in-apache-oozie-cdh-5/
#hdfs dfs -put /usr/lib/oozie/oozie-sharelib-yarn/lib /user/oozie/share

# Error: java.io.FileNotFoundException: File /user/oozie/share/lib does not exist
# http://gethue.com/running-an-oozie-workflow-and-getting-split-class-org-apache-oozie-action-hadoop-oozielauncherinputformatemptysplit-not-found/
#sudo -u oozie /usr/lib/oozie/bin/oozie-setup.sh sharelib create -fs hdfs://localhost:8020 -locallib /usr/lib/oozie/oozie-sharelib-yarn

#
sudo oozie-setup sharelib create -fs hdfs://localhost:8020 -locallib /usr/lib/oozie/oozie-sharelib-yarn

# Solution: http://stackoverflow.com/questions/28702100/apache-oozie-failed-loading-sharelib

sudo mv /etc/oozie/conf/hadoop-conf/core-site.xml /etc/oozie/conf/hadoop-conf/core-site.xml.orig

ln -s /etc/hadoop/conf/core-site.xml /etc/oozie/conf/hadoop-conf/core-site.xml

sudo oozie admin -shareliblist -oozie http://localhost:11000/oozie

sudo oozie admin -sharelibupdate -oozie http://localhost:11000/oozie

sudo oozie admin -shareliblist -oozie http://localhost:11000/oozie


# hack to move directory
sudo -u hdfs hadoop fs

# Spin down HDFS
for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x stop ; done


#  Enable Uber JARs
sudo sed -i 's|</configuration>||' /etc/oozie/conf/oozie-site.xml

sudo cat <<EOF >> /etc/oozie/conf/oozie-site.xml
   <property>
        <name>oozie.action.mapreduce.uber.jar.enable</name>
        <value>true</value>
	</property>

</configuration>
EOF


############################
# Flume
##############################

sudo yum -y install flume-ng flume-ng-agent flume-ng-doc

# Flume template property for sources, sinks, channels, and the flow within an agent
sudo cp /etc/flume-ng/conf/flume-conf.properties.template /etc/flume-ng/conf/flume.conf

# Flume template for specifying bigger heap sizes, debugging, or profiling obptions
sudo cp /etc/flume-ng/conf/flume-env.sh.template /etc/flume-ng/conf/flume-env.sh

############################

###############
# Sqoop
###############

sudo yum -y install sqoop2-server sqoop2-client

# Set to use YARN
alternatives --set sqoop2-tomcat-conf /etc/sqoop2/tomcat-conf.dist

# Associate the mysql connector with sqoop2
ln -s /usr/share/java/mysql-connector-java.jar /var/lib/sqoop2/mysql-connector-java.jar

#################
# Snappy
##################

# Installed by default

# To enable for MR 
sudo sed -i 's|</configuration>||' /etc/hadoop/conf/mapred-site.xml

sudo cat <<EOF >> /etc/hadoop/conf/mapred-site.xml
	<property>
		<name>mapreduce.map.output.compress</name>  
		<value>true</value>
	</property>
	<property>
		<name>mapred.map.output.compress.codec</name>  
		<value>org.apache.hadoop.io.compress.SnappyCodec</value>
	</property>

</configuration>
EOF

##################################
# Spark
##################################

sudo yum -y install spark-core spark-master spark-worker spark-history-server spark-python

##### Livy is bad.

##################################
# Impala
##################################

sudo yum -y install impala impala-server impala-state-store impala-catalog  

cp /etc/hive/conf/hive-site.xml /etc/impala/conf/
cp /etc/hadoop/conf/core-site.xml /etc/impala/conf
cp /etc/hadoop/conf/hdfs-site.xml /etc/impala/conf
cp /etc/hbase/conf/hbase-site.xml /etc/impala/conf

# !>> May need to do short circuits with impala <<!

#####################################
# Installing hue
#####################################

# Python is at 2.7.5 , is this problematic?

sudo yum -y install hue


# Delete config
sudo sed -i 's|</configuration>||' /etc/hadoop/conf/hdfs-site.xml

# Add WebHDFS to hdfs-site.xml
sudo cat <<EOF >> /etc/hadoop/conf/hdfs-site.xml
	<property>
		<name>dfs.webhdfs.enabled</name>
		<value>true</value>
	</property>

</configuration>
EOF

# Delete config ending in core-site.xml
sudo sed -i 's|</configuration>||' /etc/hadoop/conf/core-site.xml

# Add WebHDFS
sudo cat <<EOF >> /etc/hadoop/conf/core-site.xml
	<!-- Hue WebHDFS proxy user setting -->
	<property>
		<name>hadoop.proxyuser.hue.hosts</name>
		<value>*</value>
	</property>
	<property>
		<name>hadoop.proxyuser.hue.groups</name>
		<value>*</value>
	</property>

</configuration>
EOF


# Generate a secret hash
# SECRET_HASH=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 45)
SECRET_HASH=090c39b3c2859d5c6e0fd7d63ccefc9ebdc6628c3ecbb

sudo sed -i "s|secret_key=|secret_key=$SECRET_HASH|" /etc/hue/conf/hue.ini

# Point to WebHDFS
sudo sed -i "s|## webhdfs_url|webhdfs_url|" /etc/hue/conf/hue.ini

# Disable spark from appearing in Hue
sudo sed -i "s|## app_blacklist=|app_blacklist=spark|" /etc/hue/conf/hue.ini

#james
#giantpeach

###################################################################
###################################################################

#####################################
# Set up a Hadoop environmentals
#####################################
touch uiuc-hadoop.sh

cat <<EOF >> uiuc-hadoop.sh
HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce
HADOOP_CONF_DIR=/etc/hadoop/conf
PIG_CONF_DIR=/usr/lib/pig/conf
PIG_CLASSPATH=/usr/lib/hbase/hbase-0.94.2-cdh4.2.0-security.jar:/usr/lib/zookeeper/zookeeper-3.4.5-cdh4.2.0.jar
OOZIE_URL=http://localhost:11000/oozie
EOF

# Move it to java.sh profile
sudo mv uiuc-hadoop.sh /etc/profile.d/uiuc-hadoop.sh



######################
# Startup order
######################
#
# ZooKeeper
# HDFS
# HttpFS
# YARN
# HBase
# Hive
# Oozie
# Flume
# Sqoop
# Hue

# # Zookeeper
# sudo service zookeeper-server start

# # HDFS
# for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x start ; done

# # HttpFS
# sudo service hadoop-httpfs start

# # YARN
# sudo service hadoop-yarn-resourcemanager start
# sudo service hadoop-yarn-nodemanager start
# sudo service hadoop-mapreduce-historyserver start

# # HBase
# sudo service hbase-master start
# sudo service hbase-thrift start
# sudo service hbase-rest start
# sudo service hbase-regionserver start

# sudo service hive-metastore start
# sudo service hive-server2 start

# sudo service oozie start

# #########################
# # Power down procedure
# #########################
# # Hue
# # Sqoop
# # Flume
# # Oozie
# # Hive
# # HBase
# # YARN
# # HttpFS
# # HDFS
# # Zookeeper

# sudo service oozie stop

# sudo service hive-server2 stop
# sudo service hive-metastore stop

# sudo service hbase-regionserver stop
# sudo service hbase-rest stop
# sudo service hbase-thrift stop
# sudo service hbase-master stop

# sudo service hadoop-mapreduce-historyserver stop
# sudo service hadoop-yarn-nodemanager stop
# sudo service hadoop-yarn-resourcemanager stop

# sudo service hadoop-httpfs stop

# for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x stop ; done

# sudo service zookeeper-server stop

