#!/bin/bash

source ${SCRIPTS_DIR}/variables.sh
export IDM_PROVISION_SCRIPTS="${SCRIPTS_DIR}/idm-provision"

cd ${IDM_PROVISION_SCRIPTS}
PATH=${PATH}:${IDM_PROVISION_SCRIPTS}

ORG_A="Organization A"
ORG_A_DESC="Demo Organization A"
ORG_B="Organization B"
ORG_B_DESC="Demo Organization B"
APP_NAME="Chanchan"
APP_DESC="Demo application"
APP_URL="http://${CC_HOSTNAME}"
APP_CALLBACK="http://${CC_HOSTNAME}/login"

# Admin user
create-idm-user.sh "${CC_USER_NAME}" "${CC_EMAIL}" "${CC_PASS}"

# Create organization A
create-idm-org.sh "${CC_EMAIL}" "${ORG_A}" "${ORG_A_DESC}"

# Add application to organization with custom role
create-idm-app.sh "${ORG_A}" "${APP_NAME}" "${APP_DESC}" "${APP_URL}" "${APP_CALLBACK}"

# Create organization B
create-idm-org.sh "${CC_EMAIL}" "${ORG_B}" "${ORG_B_DESC}"

# Add application to organization with custom role
create-idm-app.sh "${ORG_B}" "${APP_NAME}" "${APP_DESC}" "${APP_URL}" "${APP_CALLBACK}"

# Dump oauth credentials
dump-oauth-credentials.sh "${ORG_A}" "${APP_NAME}"
dump-oauth-credentials.sh "${ORG_B}" "${APP_NAME}"
