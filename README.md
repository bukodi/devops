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

## Java and Maven

## Jenkins
Login with `admin` and the provied password.
Installed plugins:
- Git

## Apache

## Webmin
Login with `admin` and the provied password.

## Tomcat

# Other features
- Creates a user named `admin`
- Redirects the http to https
- Creates reverse proxies for the installed services
- Creates a default index page  

# Tested platforms
- Ubuntu Server 13.10 x64 on DigitalOcean
-- Instance type: 1GB RAM/1 CPU  (Install time: 09:50)
- Ubuntu Server 12.04 LTS x64 on Amazon EC2 
-- Image: ami-8e987ef9 (ubuntu-precise-12.04-amd64-server-20131003)
-- Instance type: m3.medium (Install time: 10:19)
