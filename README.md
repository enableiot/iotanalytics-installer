# iotanalytics-installer
Installation wizard

Here is an installation wizzard for IoT Analytics on Cloud Foundry.

Please run ./configure.sh to start a wizzard.

It will export configuration to conf/ directory.

In the end it will ask you if you want to deploy app stack based on created configuration.

If you decide to do it later or you'd like to deploy another space with the same configuration of IoT Analytics, you can execute ./installer.sh CONFIGURATION_FILE

### Pre-requirements
1. Node.js v0.10.x
1. grunt-cli
1. Apache Maven 2.2.1 or higher
1. Java 1.8 or higher
1. Python 2.7
1. Gradle 2.4
1. Git
1. Cloud Foundry CLI
1. zip packaging utility
