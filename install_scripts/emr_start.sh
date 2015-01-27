bucket="stat490uiuc"
region="us-east-1"
keypair="<hidden>"

aws emr create-cluster --name emR-example --ami-version=3.3.0 --applications Name=Hue Name=Hive Name=Pig --ec2-attributes KeyName=myKey --region $region --use-default-roles --ec2-attributes KeyName=$keypair --no-auto-terminate --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m1.large InstanceGroupType=CORE,InstanceCount=2,InstanceType=m1.large --bootstrap-actions Name=hdp_setup,Path="s3://$bucket/hdp_setup.sh",Args=[--emrinstall,--rstudio,--createuser,--sudouser,--sshuser,--hpaths,--rhadoop,--rhpc] --steps Name=HDFS_tmp_permission,Jar="s3://elasticmapreduce/libs/script-runner/script-runner.jar",Args="s3://$bucket/emr_permissions.sh"