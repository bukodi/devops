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

