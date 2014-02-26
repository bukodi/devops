#!/bin/bash

# Start this: bash <(curl https://raw2.github.com/bukodi/devops/master/installDevServer.sh) [AdminPassw0rd]

SCRIPT_BASE_URL=https://raw2.github.com/bukodi/devops/master
EXTERNAL_HOST_NAME=$(hostname -f)
START_TIME=$(date)


if [ `whoami` != root ]; then
    echo 'Please run this script as root'
    exit
fi

if [ $# -eq 0 ]; then
    echo 'Enter a new password for the admin user!'
    read -s -p "Password:" psw1
    echo ''
    read -s -p "Verify:" psw2
    echo ''
    if [ $psw1 != $psw2 ]; then
        echo 'Password and verification are not equal!'
        exit
    fi
    ADMIN_PASSWORD=$psw1
elif [ $# -eq 1 ]; then
    echo 'WARNING: the bash history contains the password provided as argument!'
    ADMIN_PASSWORD=$1
else
    echo 'Wrong number of arguments!'
    exit
fi

#TODO test ping EXTERNAL_HOST_NAME (if not then add to /etc/host)

#Execute apt-get-all script:
bash <(curl $SCRIPT_BASE_URL/scripts/apt-get-all.sh)

###############################################################################################

function setupApache {
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
    echo "# Proxies" >> conf-available/reverse-proxies.conf
    echo "ProxyRequests Off" >> conf-available/reverse-proxies.conf
    echo "AllowEncodedSlashes NoDecode" >> conf-available/reverse-proxies.conf
    echo "" >> conf-available/reverse-proxies.conf

    cd - > /dev/null
    
    #Create index.html
    echo '<html>' >> index.html
    echo '<head><title>Development server</title></head>' >> index.html
    echo '<body>' >> index.html
    echo '</body>' >> index.html
    echo '</html>' >> index.html
    mv index.html /var/www/index.html
    
    #Restart apache
    service apache2 restart
}

function addApacheProxy {
    path=$1
    url=$2
    label=$3

    # Add a proxy to public https website
    echo "ProxyPass $path $url nocanon" >> /etc/apache2/conf-available/reverse-proxies.conf
    echo "ProxyPassReverse $path $url" >> /etc/apache2/conf-available/reverse-proxies.conf

    sed -i "s/<\\/body>/ <p><a href\=\"${path//\//\\/}\">${label//\//\\/}<\\/a><\\/p>\\n<\\/body>/" /var/www/index.html
}

function createAdminUser {
    adminPassword=$1
    
    echo $'\n\n*** Create admin user****'
    if [ -z $(getent group admin) ]; then 
        useradd admin
    else
        useradd admin -g admin #If admin user currently exits, just add to the group
    fi
    adduser admin sudo
    adduser admin users
    echo "admin:$adminPassword" | chpasswd
}

function setupTomcat {
    echo $'\n\n*** Configure Tomcat  ****'
    cd /etc/tomcat7
    mv tomcat-users.xml tomcat-users.xml.original
    echo "<?xml version='1.0' encoding='utf-8'?>" > tomcat-users.xml
    echo "<tomcat-users>" >> tomcat-users.xml
    echo "  <role rolename=\"manager-gui\"/>" >> tomcat-users.xml
    echo "  <role rolename=\"admin-gui\"/>" >> tomcat-users.xml
    echo "  <user username=\"admin\" password=\"$ADMIN_PASSWORD\" roles=\"manager-gui,admin-gui\"/>" >> tomcat-users.xml
    echo "</tomcat-users>" >> tomcat-users.xml
    cd - > /dev/null
    service tomcat7 restart
    
    addApacheProxy '/manager' 'http://127.0.0.1:8080/manager' 'Tomcat Application Manager'
}

function setupNexus {
    echo $'\n\n*** Download and configure Nexus ****'
    cd /usr/local
    wget http://www.sonatype.org/downloads/nexus-latest-bundle.tar.gz
    tar xvfz nexus-latest-bundle.tar.gz
    rm nexus-latest-bundle.tar.gz
    ln -s $(ls -d nexus-*) nexus  # create symlink /usr/local/nexus
    cd - > /dev/null

    #TODO: create service user instead of running sevice with root
    export NEXUS_HOME="/usr/local/nexus"
    echo $'NEXUS_HOME="/usr/local/nexus"' >> /etc/environment
    sed -i 's/^NEXUS_HOME=.*$/NEXUS_HOME=\"\/usr\/local\/nexus\"/' /usr/local/nexus/bin/nexus
    sed -i 's/^#RUN_AS_USER=.*$/RUN_AS_USER=root/' /usr/local/nexus/bin/nexus
    
    sed -i 's/^application-host=.*$/application-host=127.0.0.1/' /usr/local/nexus/conf/nexus.properties
    
    ln -s /usr/local/nexus/bin/nexus /etc/init.d/nexus
    update-rc.d nexus defaults

    #First start of service
    service nexus start
    while [ -z "$(curl http://127.0.0.1:8081/nexus/service/local/status 2>&1 | grep '<state>STARTED</state>')" ]; do 
        echo 'Waiting for Nexus start...'
        sleep 2s
    done    
    
    # Change admin password
    curl -d "{
                \"data\": {
                    \"userId\": \"admin\", 
                    \"oldPassword\":\"admin123\",
                    \"newPassword\":\"$ADMIN_PASSWORD\"
                }
            }" \
        -u admin:admin123 http://localhost:8081/nexus/service/local/users_changepw \
        -H "Content-Type: application/json" -D-

    #Prevent warning: "Base URL does not match your actual URL!"
    cd /usr/local/sonatype-work/nexus/conf/
    sed -i "s/<baseUrl>.*<\/baseUrl>/<baseUrl>https:\/\/$EXTERNAL_HOST_NAME\/nexus<\/baseUrl>/" nexus.xml
    sed -i "s/<forceBaseUrl>.*<\/forceBaseUrl>/<forceBaseUrl>true<\/forceBaseUrl>/" nexus.xml
    cd - > /dev/null

    #Restart Nexus
    service nexus start
    while [ -z "$(curl http://127.0.0.1:8081/nexus/service/local/status 2>&1 | grep '<state>STARTED</state>')" ]; do 
        echo 'Waiting for Nexus restart...'
        sleep 2s
    done    

    addApacheProxy '/nexus' 'http://127.0.0.1:8081/nexus' 'Nexus'
}

function setupJenkins {
    echo $'\n\n*** Configure Jenkins  ****'
    echo $'\n# Change Jenkins URL to http://localhost:8082/jenkins ****'
    sed -i 's/HTTP_PORT=8080/HTTP_PORT=8082/' /etc/default/jenkins
    sed -i 's/JENKINS_ARGS="/JENKINS_ARGS="--prefix=\/jenkins /' /etc/default/jenkins
    sed -i 's/JENKINS_URL=/JENKINS_URL="http:\/\/127.0.0.1:8082\/jenkins"/' /etc/jenkins/cli.conf
    export JENKINS_URL="http://127.0.0.1:8082/jenkins"
    echo $'JENKINS_URL="http://127.0.0.1:8082/jenkins"' >> /etc/environment
    adduser jenkins shadow
    service jenkins restart
    while [ -z "$(jenkins-cli who-am-i 2>&1 | grep 'Authenticated as:')" ]; do 
        echo 'Waiting for Jenkins restart...'
        sleep 2s
    done
    
    #Wait for update
    jenkins-cli groovysh 'jenkins.model.Jenkins.instance.updateCenter.updateAllSites()'
    while [ -z "$(curl $JENKINS_URL/pluginManager/advanced 2>&1 | grep 'Update information obtained:' | grep 'min\|sec')" ]; do 
        echo 'Waiting for Jenkins update site refresh...'
        sleep 2s
    done
    
    #Install plugins and enable jenkins security 	 
    jenkins-cli install-plugin xvfb -deploy
    jenkins-cli install-plugin git -deploy
    jenkins-cli install-plugin git-client -deploy
    jenkins-cli groovysh 'jenkins.model.Jenkins.instance.securityRealm = new hudson.security.PAMSecurityRealm(null)'
    jenkins-cli groovysh 'jenkins.model.Jenkins.instance.authorizationStrategy = new hudson.security.FullControlOnceLoggedInAuthorizationStrategy()'
    jenkins-cli groovysh 'jenkins.model.Jenkins.instance.save()'  --username admin --password $ADMIN_PASSWORD
    
    #
    service jenkins restart
    while [ -z "$(jenkins-cli who-am-i 2>&1 | grep 'Authenticated as:')" ]; do 
        echo 'Waiting for Jenkins restart...'
        sleep 2s
    done

    addApacheProxy '/jenkins' 'http://127.0.0.1:8082/jenkins' 'Jenkins'
}

function setupWebmin {
    echo $'\n\n*** Configure Webmin ****'
    cd /etc/webmin
    sed -i 's/ssl=1/ssl=0/' miniserv.conf
    sed -i 's/port=10000/port=10001/' miniserv.conf
    sed -i 's/listen=10000/listen=10001/' miniserv.conf
    
    echo 'bind=127.0.0.1' >> miniserv.conf
    echo "webprefix=/webmin" >> config
    echo "webprefixnoredir=1" >> config
    echo "referer=$EXTERNAL_HOST_NAME" >> config
    cd - > /dev/null
    service webmin restart

    addApacheProxy '/webmin/' 'http://127.0.0.1:10001/' 'Webmin'
}

function setupShellinabox {
    echo $'\n\n*** Configure Shellinabox ****'
    sed -i 's/^SHELLINABOX_PORT=.*$/SHELLINABOX_PORT=4201\nSHELLINABOX_ARGS=\" --localhost-only --disable-ssl --disable-ssl-menu\"/' /etc/init.d/shellinabox
    service shellinabox restart

    addApacheProxy '/shellinabox' 'http://127.0.0.1:4201/' 'Shell-In-A-Box'
}

#########################################################################

createAdminUser $ADMIN_PASSWORD
setupApache
setupTomcat
setupNexus
setupJenkins
setupWebmin
setupShellinabox
#Restart apache
service apache2 restart 

#TODO
# setupNexus
# add more Jenkins plugin
# redirect Tomcat test virtual host
# setupSelenuim
# use the same certificate between installations
# use getopts() for parsing arguments
# branding options (Title, color, image)
# -- /usr/local/nexus/nexus
# test on AWS , TryStack and Rackspace

echo "Completed. ( $START_TIME - $(date) )"
exit 0


# Nexus setup
# http://jedi.be/blog/2010/10/12/Automating%20Sonatype%20Nexus%20with%20REST%20calls/

