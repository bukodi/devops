#!/bin/bash
AWS_ACCESS_KEY=$([ $AWS_ACCESS_KEY ] && echo $AWS_ACCESS_KEY || echo "${aws.s3.accessKey}")
AWS_SECRET_KEY=$([ $AWS_SECRET_KEY ] && echo $AWS_SECRET_KEY || echo "${aws.s3.secretKey}")
EC2_URL=$([ $EC2_URL ] && echo $EC2_URL || echo "ec2.${aws.s3.region}.amazonaws.com")

AD_MANAGER_AMI=ami-234ecc54 # Ubuntu Server 14.04 LTS (HVM), SSD Volume Type 64 bit
AD_MANAGER_USER_DATA_FILE=instance-user-data.sh

ec2-run-instances $AD_MANAGER_AMI \
	--subnet subnet-65819107 \
	--instance-type t2.micro \
	--key BCT --group sg-d83d23ba --group sg-ee3d238c \
	--user-data-file $AD_MANAGER_USER_DATA_FILE \
	--associate-public-ip-address true > /tmp/run-instance.log
	
tmpLine=$(cat /tmp/run-instance.log | grep INSTANCE)
instanceId=${tmpLine:9:10} 
ec2addtag $instanceId --tag Name=ad-manager-${instanceId:2}
sleep 2s
ec2-describe-instances $instanceId | grep NICASSOCIATION 
echo "ad-manager instance started on EC2."
