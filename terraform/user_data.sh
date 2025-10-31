#!/bin/bash
yum update -y
yum install -y httpd
echo "Hello from Terraform $(hostname)" > /var/www/html/index.html
systemctl enable httpd
systemctl start httpd
