#!/bin/bash
# AUTOMATIC WORDPRESS INSTALLER IN  AWS LINUX AMI 2018
# CHANGE DATABASE VALUES BELOW AND PASTE IT TO USERDATA SECTION In ADVANCED SECTION WHILE LAUNCHING EC2
# USE ELASTIC IP ADDRESS AND ALLOW SSH, HTTP AND HTTPS REQUEST IN SECURITY GROUP
# by Dev Bhusal
# Downloaded from https://www.devbhusal.com/wordpress.aws.sh

#Change these values and keep in safe place
db_root_password=PassWord4root
db_username=wordpress_user
db_user_password=PassWord4user
db_name=wordpress_db

# install LAMP Server
yum update -y
yum install -y httpd24 php72 mysql57-server
yum install -y php72-mysqlnd php72-mcrypt php72-zip php72-intl php72-mbstring php72-gd php72-pecl-imagick
service httpd start

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
service mysqld start
mysql -e "SET PASSWORD FOR root@localhost = PASSWORD('$db_root_password');FLUSH PRIVILEGES;"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE test;DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';"

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

EOF

# Change permission of /var/www/html/
chown -R ec2-user:apache /var/www/html
chmod -R 774 /var/www/html

#  enable .htaccess files in Apache config using sed command
sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/httpd/conf/httpd.conf

#Make apache and mysql to autostart and restart apache
chkconfig httpd on
chkconfig mysqld on
service httpd restart
