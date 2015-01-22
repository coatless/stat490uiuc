#!/bin/sh
#############################
## java_example.sh
#############################
## James Joseph Balamuta
## james.balamuta@gmail.com
#############################
## Initial Release 1.0 -- 01/20/15
#############################
## Objective: Compile MapReduce Job via Java
#############################
## # Obtain Script
## wget https://raw.githubusercontent.com/coatless/stat490uiuc/master/sample/java_example.sh
## chmod u+x java_example.sh
## 
## # Launch Script
## ./java_example.sh

wget https://raw.githubusercontent.com/coatless/stat490uiuc/master/sample/input/file01
wget https://raw.githubusercontent.com/coatless/stat490uiuc/master/sample/input/file02
wget https://raw.githubusercontent.com/coatless/stat490uiuc/master/sample/WordCount.java

echo "Putting file01 into HDFS..."
hdfs dfs -put file01 /user/rstudio/wordcount/input
echo "Putting file02 into HDFS..."
hdfs dfs -put file02 /user/rstudio/wordcount/input

echo "JAVA COMPILE OPTION 1..."
# Java Compiling Option 1
JAVAC_HADOOP_PATH=$(hadoop classpath)
export HADOOP_CLASSPATH=$JAVAC_HADOOP_PATH

mkdir WordCount1

javac -classpath ${HADOOP_CLASSPATH} -d WordCount1/ WordCount.java
jar -cf wc.jar -C WordCount1/ .

hadoop jar wc.jar WordCount /user/rstudio/wordcount/input /user/rstudio/wordcount/output1

hdfs dfs -cat /user/rstudio/wordcount/output1/part-r-00000 


echo "JAVA COMPILE OPTION 2..."
# Java Compiling Option 2
JAVA_TOOLS=$JAVA_HOME/lib/tools.jar
export HADOOP_CLASSPATH=$JAVA_TOOLS
mkdir WordCount2

hadoop com.sun.tools.javac.Main WordCount.java -d WordCount2/
jar -cf wc2.jar -C WordCount2/ .

hadoop jar wc2.jar WordCount /user/rstudio/wordcount/input /user/rstudio/wordcount/output2

hdfs dfs -cat /user/rstudio/wordcount/output2/part-r-00000 

