devops - Setting up a development server.
======

Start with root user:
```
bash <(curl https://raw2.github.com/bukodi/devops/master/installDevServer.sh) 
```

If you want provide the admin password:
```
bash <(curl https://raw2.github.com/bukodi/devops/master/installDevServer.sh) AdminPassw0rd
```
WARNING! Providing a password in command line is unsecure because the history will contains it.

If you want log:
```
bash <(curl https://raw2.github.com/bukodi/devops/master/installDevServer.sh) | tee -a install.log
```

# Services
- Creates an admin user
- Java and Maven
- Jenkins
- Apache
- Webmin
- Tomcat

# Tested platforms
- Ubuntu Server 13.10 x64 on DigitalOcean

