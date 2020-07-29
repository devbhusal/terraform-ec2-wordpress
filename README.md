# terraform-ec2-wordpress
Using Terraform and EC2-User-data to create AWS EC2 with Linux AMI , install LAMP server, Install WordPress and setup database for WordPress 
you just need need access key and secret access key of your account.
Specify region in aws and change database values in userdata.sh. Terraform will launch new Linux AMI EC2 with Elastic IP address
Bash script in Userdata.sh will install LAMP server and configure wp-config.php for you
