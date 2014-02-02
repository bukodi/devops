#!/bin/bash

# Start this: curl https://raw2.github.com/bukodi/devops/master/scripts/apt-get-all.sh | bash

START_TIME=$(date)
echo "Start: $START_TIME"

#Add keys, and URLs
wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | apt-key add -
echo $'\ndeb http://pkg.jenkins-ci.org/debian binary/' >> /etc/apt/sources.list

wget -q -O - http://www.webmin.com/jcameron-key.asc | apt-key add -
echo $'\ndeb http://download.webmin.com/download/repository sarge contrib' >> /etc/apt/sources.list
echo $'deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib' >> /etc/apt/sources.list

#Update
apt-get update
apt-get -y upgrade

apt-get -y install mc \
 openjdk-7-jdk \
 maven \
 jenkins \
 jenkins-cli \
 apache2 \
 webmin \
 tomcat7 \
 tomcat7-admin \
 tomcat7-user \
 git-core

echo "Start: $START_TIME"
echo "Start: $(date)"
