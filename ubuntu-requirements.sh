#!/bin/bash

CF_DEB_FILENAME="cfcli.deb"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


add-apt-repository -y ppa:webupd8team/java
add-apt-repository -y ppa:cwchien/gradle

apt-get update
apt-get -y install oracle-java8-installer
export JAVA_HOME=/usr/lib/jvm/java-8-oracle
echo "JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> ~/.profile


apt-get -y install nodejs-legacy maven npm gradle git zip
npm -g install grunt-cli 
wget -O $CF_DEB_FILENAME "https://cli.run.pivotal.io/stable?release=debian64&source=github"
dpkg -i $CF_DEB_FILENAME
apt-get -y install -f
rm $CF_DEB_FILENAME
