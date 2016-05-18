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

CONFIGURATION_DIR="conf/"
CONFIGURATION_FILE=${CONFIGURATION_DIR}"configuration.sh"
KEYS_DIR=${CONFIGURATION_DIR}keys

function random_password {
  p=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  echo $p
}

function get_default_domain {
  DEFAULT_DOMAIN=($(cf domains | head -n 3 | tail -1))
  DOMAIN=${DEFAULT_DOMAIN[0]}
}

function generate_keys {
  openssl genrsa -out ${KEYS_DIR}/private.pem 2048 &&
  openssl rsa -in ${KEYS_DIR}/private.pem -pubout -out ${KEYS_DIR}/public.pem &&
  export_pem_files_path
}

function export_pem_files_path {
  echo PUBLIC_PEM_PATH=${PWD}/${KEYS_DIR}/public.pem >> ${CONFIGURATION_FILE}
  echo PRIVATE_PEM_PATH=${PWD}/${KEYS_DIR}/private.pem >> ${CONFIGURATION_FILE}
}

function write_section {
   SECTION=${1}
   echo "" >> ${CONFIGURATION_FILE}
   echo "#--------${SECTION}-------#" >> ${CONFIGURATION_FILE}
}

function setup_field {
  FIELD=${1}
  DEFAULT=${2}
  COMMENT=${3}
  
  if [ $FORCE_DEFAULT ]
  then
	echo "${FIELD}=${DEFAULT}" | tee -a ${CONFIGURATION_FILE}
	return
  fi
  
  echo ""
  echo "Please provide ${FIELD} ${COMMENT} [default: ${DEFAULT}]>"
  read  -r
  if [ "x$REPLY" = "x" ]
  then
    echo "${FIELD}=${DEFAULT}" | tee -a ${CONFIGURATION_FILE}
  else
    echo "${FIELD}=${REPLY}" | tee -a ${CONFIGURATION_FILE}
  fi
}

while [[ $# > 0 ]]
do
	key="$1"

	case $key in
		-d|--default)
            FORCE_DEFAULT=1

            if [ -z "$2" ];
            then
                echo "Please provide github space after -d or --default option"
                exit 0
            else
                GITHUB_SPACE="$2"
            fi

		    shift
		;;
		--no-download)
		    NO_DOWNLOAD=1
        ;;
        --skip-ssl-validation)
            SKIP_SSL_VALIDATION=1
        ;;
		-cf-space)
		    CUSTOM_SPACE=1

            if [ -z "$2" ];
            then
                echo "Please provide cf space name after -cf-space option"
                exit 0
            else
                CUSTOM_SPACE_NAME="$2"
            fi
            shift
        ;;
        *)
            echo "Run script with -d or --default option to run non-interactively and set all to defaults"
            exit 0
		;;
	esac
	shift
done

while true
do
  mkdir -p ${CONFIGURATION_DIR}
  mkdir -p ${KEYS_DIR}

  echo "#!/bin/bash" > ${CONFIGURATION_FILE}
  echo "" >> ${CONFIGURATION_FILE}

  if [ ! $FORCE_DEFAULT ]
  then 
	  echo "Dashboard application is using RSA keys for security reason."
	  echo "Would you like to provide paths to existing files with public and private keys in PEM format?"
	  read -p "Otherwise configuration wizzard will generate a new Dashboard's keys. >" -r
  fi
	
  if [[ $REPLY == [Yy] ]]
  then
    write_section "SECURITY KEYS"
    setup_field "PUBLIC_PEM_PATH" "${PWD}/${KEYS_DIR}/public.pem"
    setup_field "PRIVATE_PEM_PATH" "${PWD}/${KEYS_DIR}/private.pem" 
  else
    generate_keys
  fi
  
  write_section "Common config"

  if [ -z "$SKIP_SSL_VALIDATION" ];
    then
    setup_field "DASHBOARD_STRICT_SSL" "true" "Strict SSL certificate verification active for Dashboard connections"
    else
    setup_field "DASHBOARD_STRICT_SSL" "false" "Strict SSL certificate verification not active for Dashboard connections"
  fi

  if [ -z "$GITHUB_SPACE" ];
    then
    setup_field "GITHUB_SPACE" "https://github.com/enableiot" "Git repository to download packages"
  fi
  if [ ! $CUSTOM_SPACE ]
  then
    setup_field "CF_SPACE_NAME" "installer" "Cloud Foundry Space Name"
  else
    setup_field "CF_SPACE_NAME" ${CUSTOM_SPACE_NAME} "Cloud Foundry Space Name"
  fi
  setup_field "FORCE" 0 "remove and create from scratch" 
  setup_field "DEPLOY_APPS" 1 "set only variables (0), install apps (1)"
  if [ ! $NO_DOWNLOAD ]
  then
    setup_field "DOWNLOAD_SOURCES_FROM_GITHUB" 1 "use previously downloaded enableiot applications sources (0), download enableiot applications sources (1)"
  else
    setup_field "DOWNLOAD_SOURCES_FROM_GITHUB" 0
  fi

  get_default_domain
  write_section "MAIL SERVER"
  setup_field "MAIL_SERVICE_SENDER" "example_user@"$DOMAIN
   
  write_section "BACKEND CREDENTIALS"
  setup_field "BACKEND_SERVICE_USERNAME" "backend@example.com" "user to communicate with backend"
  setup_field "BACKEND_SERVICE_PASSWORD" $(random_password)
  
  write_section "GATEWAY CREDENTIALS"
  setup_field "GATEWAY_SERVICE_USERNAME" "gateway@example.com" "user with data ingestion privileges for MQTT"
  setup_field "GATEWAY_SERVICE_PASSWORD" $(random_password)
  
  write_section "WEBSOCKET CREDENTIALS"
  setup_field "WEBSOCKET_SERVICE_USERNAME" "websocket"
  setup_field "WEBSOCKET_SERVICE_PASSWORD" $(random_password)
  
  write_section "RULE ENGINE CREDENTIALS"
  setup_field "RULE_ENGINE_SERVICE_USERNAME" "rule_engine@example.com" 
  setup_field "RULE_ENGINE_SERVICE_PASSWORD" $(random_password)

  
  write_section "GOOGLE CAPTCHA CONFIGURATION"
  setup_field "CAPTCHA_ENABLED" "false" "enable Google reCAPTCHA? (true-yes, false-no)"
  setup_field "CAPTCHA_CREDENTIALS_SITE_KEY" "" "google Captcha site key"
  setup_field "CAPTCHA_CREDENTIALS_SECRET_KEY" "" "google Captcha secret key"
 
  write_section "SECRETS FOR TESTING"
  setup_field "CAPTCHA_TEST_CODE" $(random_password) "secret for REST testing user creation"
  setup_field "INTERACTION_TOKEN_PERMISSION_KEY" $(random_password) "token for REST super admin actions"
  
  write_section "OTHER APPLICATION INSTALATION"
  setup_field "DEPLOY_RULE_ENGINE" 1 "deploy rule engine (1-yes, 0-no) ?"
  setup_field "DEPLOY_WEBSOCKET" 1 "deploy websocket (1-yes, 0-no) ?"
 
  
  cat ${CONFIGURATION_FILE}
  
  if [ $FORCE_DEFAULT ]
  then 
	  break
  fi
  
  
  REPLIED=0
  while [[ $REPLIED -eq 0 ]]
  do
    read -p "Is that configuration correct? >" -r
    if [ "x${REPLY}" != "x" ]
    then
      REPLIED=1
    fi
  done
  if [[ $REPLY == [Yy] ]]
  then
    break
  fi
done

if [ ! $FORCE_DEFAULT ]
then 
	read -p "Do you want to start deployment? >" -r
fi

if [[ $REPLY == [Yy] || $FORCE_DEFAULT ]]
then
  ./installer.sh ${CONFIGURATION_FILE}
fi
