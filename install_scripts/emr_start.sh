bucket="<YOUR_BUCKET>"
region="<YOUR_REGION>"
keypair="<YOUR_KEYPAIR>"
master_instance="m1.large"
slave_instance="m1.large"
num_slaves=2

aws emr create-cluster --name emr_cluster \
--ami-version 3.2.1 \
--region $region \
--ec2-attributes KeyName=$keypair \
--no-auto-terminate \
--instance-groups \
InstanceGroupType=MASTER,InstanceCount=1,InstanceType=$master_instance \
InstanceGroupType=CORE,InstanceCount=$num_slaves,InstanceType=$slave_instance \
--bootstrap-actions \
Name=emR_bootstrap,\
Path="s3://$bucket/hdp_setup.sh",\
Args=[--emrinstall,--rstudio,--hpaths,--rhadoop,--createuser,--sudouser,--sshuser] \
--steps \
Name=HDFS_tmp_permission,\
Jar="s3://elasticmapreduce/libs/script-runner/script-runner.jar",\
Args="s3://$bucket/emr_permissions.sh"