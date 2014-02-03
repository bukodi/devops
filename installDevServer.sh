#!/bin/bash

# Start this: source <(curl https://raw2.github.com/bukodi/devops/master/installDevServer.sh) [AdminPassw0rd]

SCRIPT_BASE_URL=https://raw2.github.com/bukodi/devops/master
EXTERNAL_HOST_NAME="devserver.bukodi.com"

if [ `whoami` != root ]; then
    echo 'Please run this script as root or using sudo'
    exit
fi

# Start this: curl http://www.bukodi.com/installDevServer.sh | bash
if [ $# -eq 0 ]; then
        echo 'Enter a new password for the admin user!'
        read -s -p "Password:" psw1
        echo 'ADMIN_PASSWORD1=>>>'$psw1'<<<'
        echo ''
        read -s -p "Verify:" psw2
        echo 'ADMIN_PASSWORD2=>>>'$psw2'<<<'
        echo ''
        if [ $psw1 != $psw2 ]; then
                echo 'Password and verification are not equal!'
                exit
        fi;
        ADMIN_PASSWORD=$psw1
elif [ $# -eq 1 ]; then
        ADMIN_PASSWORD=$1
else
        echo 'Wrong number of arguments!'
        exit
fi

#TODO test ping hostname (if not then add to /etc/host)
echo 'ADMIN_PASSWORD=>>>'$ADMIN_PASSWOPRD'<<<'
exit
curl $SCRIPT_BASE_URL/scripts/apt-get-all.sh | bash   


echo $'\n\n*** Create admin user****'
useradd admin
adduser admin sudo
adduser admin users
echo "admin:$ADMIN_PASSWORD" | chpasswd

echo $'\n\n*** Change Jenkins URL to http://localhost:8081/jenkins ****'
sed -i 's/HTTP_PORT=8080/HTTP_PORT=8081/' /etc/default/jenkins
sed -i 's/JENKINS_ARGS="/JENKINS_ARGS="--prefix=\/jenkins /' /etc/default/jenkins
sed -i 's/JENKINS_URL=/JENKINS_URL="http:\/\/127.0.0.1:8081\/jenkins"/' /etc/jenkins/cli.conf
export JENKINS_URL="http://127.0.0.1:8081/jenkins"
echo $'JENKINS_URL="http://127.0.0.1:8081/jenkins"' >> /etc/environment
adduser jenkins shadow
service jenkins restart
while [ -z "$(jenkins-cli who-am-i 2>&1 | grep 'Authenticated as:')" ]; do echo 'Wait for Jenkins restart...'; sleep 2s; done

#Wait for update
jenkins-cli groovysh 'jenkins.model.Jenkins.instance.updateCenter.updateAllSites()'
while [ -z "$(curl $JENKINS_URL/pluginManager/advanced 2>&1 | grep 'Update information obtained:' | grep 'min\|sec')" ]; do echo 'Wait for Jenkins update site refresh...'; sleep 2s; done

#Install plugins and enable jenkins security 	 
jenkins-cli install-plugin git -deploy 
jenkins-cli install-plugin git-client -deploy
jenkins-cli groovysh 'jenkins.model.Jenkins.instance.securityRealm = new hudson.security.PAMSecurityRealm(null)'
jenkins-cli groovysh 'jenkins.model.Jenkins.instance.authorizationStrategy = new hudson.security.FullControlOnceLoggedInAuthorizationStrategy()'
jenkins-cli groovysh 'jenkins.model.Jenkins.instance.save()'  --username admin --password $ADMIN_PASSWORD

#
service jenkins restart
while [ -z "$(jenkins-cli who-am-i 2>&1 | grep 'Authenticated as:')" ]; do echo 'Wait for Jenkins restart...'; sleep 2s; done

echo $'\n\n*** Grant access to Tomcat  ****'
cd /etc/tomcat7
mv tomcat-users.xml tomcat-users.xml.original
echo "<?xml version='1.0' encoding='utf-8'?>" > tomcat-users.xml
echo "<tomcat-users>" >> tomcat-users.xml
echo "  <role rolename=\"manager-gui\"/>" >> tomcat-users.xml
echo "  <role rolename=\"admin-gui\"/>" >> tomcat-users.xml
echo "  <user username=\"admin\" password=\"$ADMIN_PASSWORD\" roles=\"manager-gui,admin-gui\"/>" >> tomcat-users.xml
echo "</tomcat-users>" >> tomcat-users.xml
cd -
service tomcat7 restart

echo $'\n\n*** Configure Webmin ****'
cd /etc/webmin
sed -i 's/ssl=1/ssl=0/' miniserv.conf
sed -i 's/port=10000/port=10001/' miniserv.conf
sed -i 's/listen=10000/listen=10001/' miniserv.conf

echo 'bind=127.0.0.1' >> miniserv.conf
echo "webprefix=/webmin" >> config
echo "webprefixnoredir=1" >> config
echo "referer=$EXTERNAL_HOST_NAME" >> config
cd -
service webmin restart
while ! echo exit | nc localhost 10001; do sleep 10; done

echo $'\n\n*** Configure Apache  ****'
cd /etc/apache2
#Load modules
a2enmod ssl
a2enmod proxy
a2enmod proxy_http
a2enmod rewrite

#Enable SSL
ln -s /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf
sed -i 's/DocumentRoot \/var\/www/DocumentRoot \/var\/www\n\t\tInclude conf-available\/reverse-proxies.conf/' sites-enabled/default-ssl.conf

#Redirect http to https
sed -i 's/DocumentRoot \/var\/www/DocumentRoot \/var\/www\n\n\tRewriteEngine On\n\tRewriteRule \^(\.\*)\$ https:\/\/%{HTTP_HOST}\$1 \[R=301,L\]\n/' sites-enabled/000-default.conf

#Setup proxies
echo "ProxyPass /jenkins http://127.0.0.1:8081/jenkins" >> conf-available/reverse-proxies.conf
echo "ProxyPassReverse /jenkins http://127.0.0.1:8081/jenkins" >> conf-available/reverse-proxies.conf
echo "ProxyPass /webmin/ http://127.0.0.1:10001/" >> conf-available/reverse-proxies.conf
echo "ProxyPassReverse /webmin/ http://127.0.0.1:10001/" >> conf-available/reverse-proxies.conf
cd -

#Create index.html
echo '<html>' >> index.html
echo '<head><title>Development server</title></head>' >> index.html
echo '<body>' >> index.html
echo ' <p><a href="https://./jenkins">Jenkins</a></p>' >> index.html
echo ' <p><a href="/webmin/">Webmin</a></p>' >> index.html
echo '</body>' >> index.html
echo '</html>' >> index.html
mv index.html /var/www/index.html

#Restart apache
service apache2 restart
