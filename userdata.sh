#!/bin/bash
# AUTOMATIC WORDPRESS INSTALLER IN  AWS LINUX 2 AMI
# CHANGE DATABASE VALUES BELOW AND PASTE IT TO USERDATA SECTION In ADVANCED SECTION WHILE LAUNCHING EC2
# USE ELASTIC IP ADDRESS AND ALLOW SSH, HTTP AND HTTPS REQUEST IN SECURITY GROUP
# by Dev Bhusal
# Downloaded from https://www.devbhusal.com/wordpress.aws.sh

#Change these values and keep in safe place
db_root_password=PassWord4-root
db_username=wordpress_user
db_user_password=PassWord4-user
db_name=wordpress_db

# install LAMP Server
yum update -y
#install apache server
yum install -y httpd
 
#since amazon ami 2018 is no longer supported ,to install latest php and mysql we have to do some tricks.
#first enable php7.xx from  amazon-linux-extra and install it

amazon-linux-extras enable php7.4
yum clean metadata
yum install -y php php-{pear,cgi,common,curl,mbstring,gd,mysqlnd,gettext,bcmath,json,xml,fpm,intl,zip,imap,devel}
#install imagick extension
yum -y install gcc ImageMagick ImageMagick-devel ImageMagick-perl
pecl install imagick
chmod 755 /usr/lib64/php/modules/imagick.so
cat <<EOF >>/etc/php.d/20-imagick.ini

extension=imagick

EOF

systemctl restart php-fpm.service


#and download mysql package to yum  and install mysql server from yum
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum localinstall -y https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
yum install -y mysql-community-server



systemctl start  httpd
systemctl start mysqld

# Change OWNER and permission of directory /var/www
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

# Download wordpress package and extract
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* /var/www/html/

# AUTOMATIC mysql_secure_installation
# change permission of error log file to extract initial root password 
chown  ec2-user:apache /var/log/mysqld.log
temppassword=$(grep 'temporary password' /var/log/mysqld.log | grep -o ".\{12\}$")
#and change back to mysql 
chown  mysql:mysql /var/log/mysqld.log

#change root password to db_root_password
 mysql -p$temppassword --connect-expired-password  -e "SET PASSWORD FOR root@localhost = PASSWORD('$db_root_password');FLUSH PRIVILEGES;" 
mysql -p'$db_root_password'  -e "DELETE FROM mysql.user WHERE User='';"
mysql -p'$db_root_password' -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"


# Create database user and grant privileges
mysql -u root -p"$db_root_password" -e "GRANT ALL PRIVILEGES ON *.* TO '$db_username'@'localhost' IDENTIFIED BY '$db_user_password';FLUSH PRIVILEGES;"

# Create database
mysql -u $db_username -p"$db_user_password" -e "CREATE DATABASE $db_name;"

# Create wordpress configuration file and update database value
cd /var/www/html
cp wp-config-sample.php wp-config.php

sed -i "s/database_name_here/$db_name/g" wp-config.php
sed -i "s/username_here/$db_username/g" wp-config.php
sed -i "s/password_here/$db_user_password/g" wp-config.php
cat <<EOF >>/var/www/html/wp-config.php

define( 'FS_METHOD', 'direct' );
define('WP_MEMORY_LIMIT', '256M');

EOF

# Change permission of /var/www/html/
chown -R ec2-user:apache /var/www/html
chmod -R 774 /var/www/html

#  enable .htaccess files in Apache config using sed command
sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/httpd/conf/httpd.conf

#Make apache and mysql to autostart and restart apache
systemctl enable  httpd.service
systemctl enable mysqld.service
systemctl restart httpd.service

