#!/bin/sh
#############################
## ch2.sh
## Modified from Hadoop: The Definitive Guide, 3rd Edition
#############################
## James Joseph Balamuta
## james.balamuta@gmail.com
#############################
## Initial Release 1.0 -- 01/22/15
#############################
## Talking about MapReduce on HDP 2.2
##
## http://hadoop.apache.org/docs/current/hadoop-mapreduce-client/hadoop-mapreduce-client-core/MapReduce_Compatibility_Hadoop1_Hadoop2.html

# The objective: Running Hadoop in Standalone Mode 

# The location of hadoop-examples.jar is different on HDP than given by the book
# find / -name 'hadoop-mapreduce-examples*.jar'
export HADOOP_CLASSPATH=/usr/hdp/2.2.0.0-2041/hadoop-mapreduce/hadoop-mapreduce-examples.jar

# Now, we will run a mapreduce
hadoop MaxTemperature input/ncdc/sample.txt output