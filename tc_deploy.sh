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

function check_return {
	echo $RETURN
	FAILED=$(echo $RETURN | grep "FAILED" | wc -l)

	if [ "$FAILED" -eq 1 ]
	then
		exit 1
	fi
}

function check_org_exists {
  EXISTS=$(cf orgs | grep -x "${1}\ *" | wc -l)
  echo $EXISTS
}

function create_org {
  EXISTS=$(check_org_exists ${1})
  if [ $EXISTS -eq 0 ]
  then
    echo "Creating org: ${1} ..."
    RETURN=($(cf create-org "${1}"))
	check_return
  else
    echo "Organization ${1} already exists"
  fi
  RETURN=($(cf t -o "${1}"))
  check_return
}

cf api ${CF_API} --skip-ssl-validation &&
cf auth ${CF_TEST_USER} ${CF_TEST_USER_PASS} &&
create_org ${CF_TEST_ORG} &&

chmod +x ./configure.sh &&
chmod +x ./installer.sh &&
./configure.sh -d ${GITHUB_SPACE} -cf-space ${CF_TEST_SPACE} --no-download --skip-ssl-validation
