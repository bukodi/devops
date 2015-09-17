#!/bin/bash

####### Properties ###############
# These values come from src/main/resources/bct-admanager.properties
#
awsAccessKey='${aws.s3.accessKey}'
awsSecretKey='${aws.s3.secretKey}'
awsRegion='${aws.s3.region}'
installBucket='${install.bucketName}'
bctAdmanagerVersion='${pom.version}'
jdbcUrl='${install.jdbcUrl}'
jdbcUser='${install.jdbcUser}'
jdbcPassword='${install.jdbcPassword}'
ALSMatrixBucket='${install.bucketName}'
ALSMatrixPath='${pom.version}/ALS-matrix-bin.tar.gz'
####### END OF: Properties ###############

tomcatVersion='8.0.20'

echo "$(date) Install started. ( $(pwd -P), $0 )" >> /tmp/install.log

START_TIME=$(date)
add-apt-repository ppa:webupd8team/java -y
apt-get update
apt-get -y install awscli mc 
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
apt-get -y -q install oracle-java8-installer
update-java-alternatives -s java-8-oracle

echo "$(date) Java installed." >> /tmp/install.log

mkdir /root/.aws
echo "[default]" > /root/.aws/config
echo "aws_secret_access_key = $awsSecretKey" >> /root/.aws/config
echo "aws_access_key_id = $awsAccessKey" >> /root/.aws/config
echo "region = $awsRegion" >> /root/.aws/config

cd /opt
wget http://xenia.sote.hu/ftp/mirrors/www.apache.org/tomcat/tomcat-8/v$tomcatVersion/bin/apache-tomcat-$tomcatVersion.tar.gz
tar -xf apache-tomcat-$tomcatVersion.tar.gz 
rm apache-tomcat-$tomcatVersion.tar.gz
mv apache-tomcat-$tomcatVersion tomcat8
cd tomcat8

echo "$(date) Tomcat installed." >> /tmp/install.log

aws s3 cp  s3://$installBucket/$bctAdmanagerVersion/bct-admanager.war webapps/
aws s3 cp  s3://$ALSMatrixBucket/$ALSMatrixPath /tmp/ALS-matrix-bin.tar.gz
tar xf /tmp/ALS-matrix-bin.tar.gz
rm /tmp/ALS-matrix-bin.tar.gz

echo "$(date) Donwnload from S3 completed." >> /tmp/install.log


javaOpts="-Dmodel.instance-dir=/opt/tomcat8/ALS-matrix/instance-dir "
javaOpts=$javaOpts"-Djavax.persistence.jdbc.url=$jdbcUrl "
javaOpts=$javaOpts"-Djavax.persistence.jdbc.user=$jdbcUser "
javaOpts=$javaOpts"-Djavax.persistence.jdbc.password=$jdbcPassword "
echo "export JAVA_OPTS='$javaOpts'" >> bin/setenv.sh
echo "export JAVA_HOME='/usr/lib/jvm/java-8-oracle'" >> bin/setenv.sh
chmod 755 bin/setenv.sh 

bin/startup.sh

echo "$(date) Install completed." >> /tmp/install.log

