#!/bin/bash
# Copyright (c) 2015 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

function usage {
  echo "Usage: installer.sh CONFIGURATION_FILE"
  echo "No configuration file provided or it does not exist"
  exit
}

function check_space_exists {
  EXISTS=$(cf spaces | grep -x "${1}\ *" | wc -l)
  echo $EXISTS
}

function check_service_exists {
  EXISTS=$(echo "$SERVICES_RES" | grep ${1} | wc -l)
  echo $EXISTS
}

function check_app_exists {
  EXISTS=$(cf apps | grep ${1} | wc -l)
  echo $EXISTS
}

# ${1} service name in marketplace
# ${2} service plan in marketplace
# ${3} (optional) name for service to be created; my${1} if not provided
function install_service {
  EXISTS=$(check_service_exists "my${1}")
  if [ $EXISTS -eq 0 ]
  then
    echo "Creating service my${1}"
    NAME="$1"
    PLAN="$2"

    if [ -z "$3" ];
	then
		NAME_FOR_SERVICE="my$1"
	else
		NAME_FOR_SERVICE="my$3"
	fi

    echo $NAME $PLAN $NAME_FOR_SERVICE

	RETURN=("$(cf create-service ${NAME} "${PLAN}" "${NAME_FOR_SERVICE}")")

	check_return
  else
    echo "Service my${1} already exists"
  fi
}

function get_default_domain {
  DEFAULT_DOMAIN=($(cf domains | head -n 3 | tail -1))
  DOMAIN=${DEFAULT_DOMAIN[0]}
  echo ${DOMAIN}
}

function get_backend_endpoint {
  DOMAIN=$(get_default_domain)
  echo "http://${1}-backend.${DOMAIN}"
}

function get_dashboard_endpoint {
  DOMAIN=$(get_default_domain)
  echo "https://${1}-dashboard.${DOMAIN}"
}

function provide_backend_endpoint {
  ADDRESS=$(get_backend_endpoint ${1})
  SOME_SERVICE="{\"host\":\"${ADDRESS}\"}"
  EXISTS=$(check_service_exists backend-ups)
  if [ $EXISTS -eq 0 ]
  then
    echo "Creating backend-ups $SOME_SERVICE"
    RETURN=("$(cf cups backend-ups   -p ${SOME_SERVICE})")
  else
    echo "Updating backend-ups $SOME_SERVICE"
    RETURN=("$(cf uups backend-ups   -p ${SOME_SERVICE})")
  fi
  
  check_return
}

function provide_dashboard_endpoint {
  ADDRESS=$(get_dashboard_endpoint ${1})
  DASHBOARD_SERVICE="{\"host\":\"${ADDRESS}\"}"
  EXISTS=$(check_service_exists dashboard-endpoint-ups)
  if [ $EXISTS -eq 0 ]
  then
    echo "Creating dashboard-endpoint-ups $DASHBOARD_SERVICE"
    RETURN=("$(cf cups dashboard-endpoint-ups -p ${DASHBOARD_SERVICE})")
  else
    echo "Updating dashboard-endpoint-ups $DASHBOARD_SERVICE"
    RETURN=("$(cf uups dashboard-endpoint-ups -p ${DASHBOARD_SERVICE})")
  fi
  check_return
}

function provide_kafka_configuration {
  KAFKA_CONF="{\"topic\":\"metrics\",\"enabled\":true,\"partitions\":1,\"replication\":1,\"timeout_ms\":10000}"
  EXISTS=$(check_service_exists kafka-ups)
  if [ $EXISTS -eq 0 ]
  then
    echo "Creating kafka-ups $KAFKA_CONF"
    cf cups kafka-ups -p ${KAFKA_CONF}
  else
    echo "Updating kafka-ups $KAFKA_CONF"
    cf uups kafka-ups -p ${KAFKA_CONF}
  fi
}


function provide_mail_credentials {
  MAIL_SERVICE="{\"sender\":\"${MAIL_SERVICE_SENDER}\"}"
  EXISTS=$(check_service_exists mail-ups)
  if [ $EXISTS -eq 0 ]
  then
    echo "Creating mail-ups $MAIL_SERVICE"
    RETURN=("$(cf cups mail-ups -p ${MAIL_SERVICE})")
  else 
    echo "Updating mail-ups $MAIL_SERVICE"
    RETURN=("$(cf uups mail-ups -p ${MAIL_SERVICE})")
  fi
  
  check_return
}

function provide_websocket_credentials {
  WEBSOCKET_SERVICE="{\"username\":\"${WEBSOCKET_SERVICE_USERNAME}\",\"password\":\"${WEBSOCKET_SERVICE_PASSWORD}\"}"
  EXISTS=$(check_service_exists websocket-ups)
  if [ $EXISTS -eq 0 ]
  then
    echo "Creating websocket-ups $WEBSOCKET_SERVICE"
    RETURN=("$(cf cups websocket-ups -p ${WEBSOCKET_SERVICE})")
  else
    echo "websocket-ups already exists."
  fi
  
  check_return
}

function provide_rule_engine_credentials {
  RULE_ENGINE_SERVICE="{\"username\":\"${RULE_ENGINE_SERVICE_USERNAME}\",\"password\":\"${RULE_ENGINE_SERVICE_PASSWORD}\"}"
  EXISTS=$(check_service_exists rule-engine-credentials-ups)
  if [ $EXISTS -eq 0 ]
  then
    echo "Creating rule-engine-credentials-ups $RULE_ENGINE_SERVICE"
    RETURN=("$(cf cups rule-engine-credentials-ups -p ${RULE_ENGINE_SERVICE})")
  else
    echo "rule-engine-credentials-ups already exists."
  fi
  
  check_return
}

function provide_gateway_credentials {
  GATEWAY_SERVICE="{\"username\":\"${GATEWAY_SERVICE_USERNAME}\",\"password\":\"${GATEWAY_SERVICE_PASSWORD}\"}"
  EXISTS=$(check_service_exists gateway-credentials-ups)
  if [ $EXISTS -eq 0 ]
  then
    echo "Creating gateway-credentials-ups $GATEWAY_SERVICE"
    RETURN=("$(cf cups gateway-credentials-ups -p ${GATEWAY_SERVICE})")
  else
    echo "gateway-credentials-ups already exists"
  fi
  check_return
}

function provide_dashboard_security_credentials {
  PRIVATE_PATH="\"./keys/private.pem\""
  PUBLIC_PATH="\"./keys/public.pem\""

  SECURITY_CREDENTIALS="{\"private_pem_path\":${PRIVATE_PATH},\"public_pem_path\":${PUBLIC_PATH},\"captcha_test_code\":\"${CAPTCHA_TEST_CODE}\",\"interaction_token_permision_key\":\"${INTERACTION_TOKEN_PERMISSION_KEY}\"}"

  EXISTS=$(check_service_exists dashboard-security-ups)
  if [ $EXISTS -eq 0 ]
  then
    echo "Creating dashboard-security-ups $SECURITY_CREDENTIALS"
    RETURN=("$(cf cups dashboard-security-ups -p ${SECURITY_CREDENTIALS})")
  else
    echo "Updating dashboard-security-ups $SECURITY_CREDENTIALS"
    RETURN=("$(cf uups dashboard-security-ups -p ${SECURITY_CREDENTIALS})")
  fi
  
  check_return
}

function provide_captcha_credentials {
	CAPTCHA_CREDENTIALS="{\"siteKey\":\"${CAPTCHA_CREDENTIALS_SITE_KEY}\",\"secretKey\":\"${CAPTCHA_CREDENTIALS_SECRET_KEY}\",\"enabled\":\"${CAPTCHA_ENABLED}\"}"
	EXISTS=$(check_service_exists recaptcha-ups)
	if [ $EXISTS -eq 0 ]
	then
		echo "Creating recaptcha-ups $CAPTCHA_CREDENTIALS"
		RETURN=("$(cf cups recaptcha-ups -p ${CAPTCHA_CREDENTIALS})")
	else
		echo "Updating recaptcha-ups $CAPTCHA_CREDENTIALS"
		RETURN=("$(cf uups recaptcha-ups -p ${CAPTCHA_CREDENTIALS})")
	fi

	check_return
}

function provide_kerberos_credentials {
  KERBEROS_SERVICE="{\"kdc\":\"${KERBEROS_SERVICE_KDC}\",\"kpassword\":\"${KERBEROS_SERVICE_PASSWORD}\",\"krealm\":\"${KERBEROS_SERVICE_REALM}\",\"kuser\":\"${KERBEROS_SERVICE_USER}\"}"
  EXISTS=$(check_service_exists kerberos-service)
  if [ $EXISTS -eq 0 ]
  then
    echo "Creating kerberos-service $KERBEROS_SERVICE"
    RETURN=("$(cf cups kerberos-service -p ${KERBEROS_SERVICE})")
  else
    echo "Updating kerberos-service $KERBEROS_SERVICE"
    RETURN=("$(cf uups kerberos-service -p ${KERBEROS_SERVICE})")
  fi

  check_return
}

function deploy_backend {
    APP_NAME="${1}-backend"
    EXISTS=$(check_app_exists ${APP_NAME})
    if [ $EXISTS -eq 1 ]
    then
        RETURN=("$(cf d ${APP_NAME} -f)")
        check_return
    fi
    if [ "x${DOWNLOAD_SOURCES_FROM_GITHUB}" = "x1" ]
      then
        git clone ${GITHUB_SPACE}/iotanalytics-backend.git
    fi
    echo 'Deploying iotanalytics-backend'
    DOMAIN=$(get_default_domain)
    cd iotanalytics-backend/ &&
    gradle clean build &&
    cf push ${APP_NAME} -d ${DOMAIN} &&
    check_exit_code
    cd ..
}
function set_websocket_keys {
    mkdir -p security &&
    cp ${PUBLIC_PEM_PATH} ./security/public.pem
    if [ "$?" -ne "0" ]
    then
      echo "Public RSA key not found in ${PUBLIC_PEM_PATH}. Unable to deploy Dashboard application."
      exit 1
    fi
}

function deploy_websocket {
  APP_NAME="${1}-websocket"
  EXISTS=$(check_app_exists ${APP_NAME})
  if [ $EXISTS -eq 1 ]
  then
    RETURN=("$(cf d ${APP_NAME} -f)")
	check_return
  fi
  if [ "x${DOWNLOAD_SOURCES_FROM_GITHUB}" = "x1" ]
     then
       git clone ${GITHUB_SPACE}/iotanalytics-websocket-server.git
  fi
  cd iotanalytics-websocket-server &&
  set_websocket_keys &&
  DOMAIN=$(get_default_domain)
  RETURN=("$(cf push ${APP_NAME} -d ${DOMAIN})")
  check_return
  cd ..
}

function deploy_rule_engine_app {
  APP_NAME="${1}-rule-engine"
  EXISTS=$(check_app_exists ${APP_NAME})
  if [ $EXISTS -eq 1 ]
  then
    RETURN=("$(cf d ${APP_NAME} -f)")
	check_return
  fi
  if [ "x${DOWNLOAD_SOURCES_FROM_GITHUB}" = "x1" ]
    then
      git clone ${GITHUB_SPACE}/iotanalytics-gearpump-rule-engine.git
  fi

  cd "iotanalytics-gearpump-rule-engine" &&
  echo "Deploying rule engine app" &&
  ./cf-deploy.sh
  check_exit_code
  cd ..
}



function set_dashboard_keys {
    mkdir -p keys &&
    cp ${PRIVATE_PEM_PATH} ./public-interface/keys/private.pem
    if [ "$?" -ne "0" ]
    then
      echo "Private RSA key not found in ${PRIVATE_PEM_PATH}. Unable to deploy Dashboard application."
      exit 1
    fi
    cp ${PUBLIC_PEM_PATH} ./public-interface/keys/public.pem
    if [ "$?" -ne "0" ]
    then
      echo "Public RSA key not found in ${PUBLIC_PEM_PATH}. Unable to deploy Dashboard application."
      exit 1
    fi
}

function deploy_frontend { 
  APP_NAME="${1}-dashboard"
  EXISTS=$(check_app_exists ${APP_NAME})
  if [ $EXISTS -eq 1 ]
  then
    RETURN=("$(cf d ${APP_NAME} -f)")
	check_return
  fi
  if [ "x${DOWNLOAD_SOURCES_FROM_GITHUB}" = "x1" ]
  then
    git clone ${GITHUB_SPACE}/iotanalytics-dashboard.git
  fi

  cd iotanalytics-dashboard &&
  mkdir -p ./public-interface/keys &&
  set_dashboard_keys &&
  cd ./public-interface &&
  npm -d install #NPM too often fail at the first time
  cd .. &&
  ./cf-deploy.sh
  check_exit_code
  cd ..
}

function create_space {
  EXISTS=$(check_space_exists ${1})
  if [ $EXISTS -eq 0 ]
  then
    echo "Creating space: ${1} ..."
    RETURN=("$(cf create-space "${1}")")
	check_return
  else 
    echo "Space ${1} already exists"
    fetch_services
  fi
  RETURN=("$(cf t -s "${1}")")
  check_return
}

function deploy_services {
  install_service postgresql93 free postgres &&
  install_service zookeeper shared &&
  install_service redis28 free redis &&
  install_service hdfs bare &&
  install_service kafka shared &&
  install_service hbase shared &&
  install_service smtp shared
  if [ "x${DEPLOY_RULE_ENGINE}" = "x1" ]
  then
    install_service gearpump "1 worker"
  fi
  provide_backend_endpoint ${1} &&
  provide_dashboard_endpoint ${1} &&
  provide_kafka_configuration &&
  provide_mail_credentials &&
  provide_websocket_credentials &&
  provide_captcha_credentials &&
  provide_rule_engine_credentials &&
  provide_gateway_credentials &&
  provide_dashboard_security_credentials &&
  provide_kerberos_credentials &&
  echo "All services created or updated successfully!"
}

function deploy_apps {
  if [ "x${DOWNLOAD_SOURCES_FROM_GITHUB}" = "x1" ]
  then
    rm -rf temp/
  fi

  mkdir -p temp &&
  cd temp &&
  deploy_frontend ${1} &&
  deploy_backend ${1}
  if [ "x${DEPLOY_RULE_ENGINE}" = "x1" ]
  then
    deploy_rule_engine_app ${1}
  fi
  if [ "x${DEPLOY_WEBSOCKET}" = "x1" ]
  then
    deploy_websocket ${1}
  fi
  cd ..
  rm -rf temp/ || sudo rm -rf temp/
  echo "All applications were deployed successfully! :D"
}

function deploy {
  create_space ${1} &&
  deploy_services ${1} &&
  DEPLOY_APPS=${2}
  if [ ${DEPLOY_APPS} -eq 1 ]
  then
    deploy_apps ${1}
  fi
}

function destroy {
    clear_services
    EXISTS=$(check_space_exists ${1})
    if [ $EXISTS -eq 1 ]
    then
        RETURN=("$(cf delete-space -f "$1")")
        check_return
    else
        echo "Space ${1} not found."
    fi
}

function check_return {
	echo $RETURN
	FAILED=$(echo $RETURN | grep "FAILED" | wc -l)

	if [ "$FAILED" -eq 1 ]
	then
		exit 1
	fi
}

function check_exit_code {
	if [ $? -eq 1 ]
	then
		exit 1
	fi
}

function fetch_services {
	SERVICES_RES=$(cf services)
}

function clear_services {
	SERVICES_RES=""
}


CONFIGURATION_FILE=${1}
if [ ! -f ${CONFIGURATION_FILE} ]
then
  usage
fi

echo "Reading configuration file ${CONFIGURATION_FILE}"
source ${CONFIGURATION_FILE}

if [ "x${CF_SPACE_NAME}" = "x" ]
then
  usage
fi
if [ "x${FORCE}" = "x1" ]
then
  destroy ${CF_SPACE_NAME}
fi
deploy ${CF_SPACE_NAME} ${DEPLOY_APPS}
