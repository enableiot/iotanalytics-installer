# iotanalytics-installer
Installation wizard

Here is an installation wizzard for IoT Analytics on Trusted Analytics Platform.

Please run ./configure.sh to start a wizzard.

It will export configuration to conf/ directory.

In the end it will ask you if you want to deploy app stack based on created configuration.

If you decide to do it later or you'd like to deploy another space with the same configuration of IoT Analytics, you can execute ./installer.sh CONFIGURATION_FILE

Before executing the installer, make sure that you are logged into Trusted Analytics Platform with command:
```
cf login
```

### Pre-requirements
1. Node.js v0.10.x
1. grunt-cli
1. Apache Maven 2.2.1 or higher
1. Java 1.8 or higher
1. Python 2.7
1. Gradle 2.4
1. Git
1. Cloud Foundry CLI and Trusted Analytics Platform account (https://github.com/trustedanalytics)
1. zip packaging utility
1. GNU Make >= 3.8
1. npm >= 1.3.10

### Pre-requirements installation examples

Ubuntu and Debian-based OSes:

1. Java:

  ```
    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get install oracle-java8-installer
  ```
        
  Remember to export JAVA_HOME:
        
  ```
    export JAVA_HOME=/usr/lib/jvm/java-8-oracle
    echo "JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> ~/.profile
   ```

2. Gradle:
        
  ```
    sudo add-apt-repository -y ppa:cwchien/gradle
    sudo apt-get install gradle
  ```

3. Other dependencies:
        
  ```
    sudo apt-get install nodejs-legacy maven npm git zip
  ```

4. grunt-cli:
        
  ```
    sudo npm -g install grunt-cli 
  ```

5. Download Cloud Foundry CLI deb package and install it using:
        
  ```
    sudo dpkg -i <path to deb>
  ``` 

