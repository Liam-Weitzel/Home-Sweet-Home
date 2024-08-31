#!/bin/bash

clear;

echo "Starting Apache2, Mysql/MariaDB, Tomcat";

sudo bash /opt/apache-tomcat-9.0.60/bin/catalina.sh stop;
sudo bash /opt/apache-tomcat-9.0.60/bin/catalina.sh start;
sudo service apache2 stop;
sudo service apache2 start;
sudo systemctl stop mysql.service;
sudo systemctl start mysql.service;

clear;
echo;
echo "Apache2, Mysql/MariaDB and Tomcat (re)started";
echo;
echo;
echo;
echo;
echo "To login to DB: mysql -u root -h localhost -p";
echo "Username: root         Password: root";
echo;
echo "Go to localhost:8080 for tomcat";
echo "Username: tomcat         Password: tomcat";
echo;
echo "Go to localhost:80 for apache2";
echo;
echo;
echo;
echo;
echo "Dont quit this process or tomcat (localhost:8080) will not be accessible";

trap '' INT
while : ; do
read -n 1 k <&1
done
