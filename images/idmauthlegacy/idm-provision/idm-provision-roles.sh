#!/bin/bash

source ${SCRIPTS_DIR}/variables.sh
export IDM_PROVISION_SCRIPTS="${SCRIPTS_DIR}/idm-provision"

cd ${IDM_PROVISION_SCRIPTS}
PATH=${PATH}:${IDM_PROVISION_SCRIPTS}

ORG_A="Organization A"
ORG_B="Organization B"
APP_NAME="Chanchan"

ROLE_M="Member"
ROLE_P="Publisher"

create-role.sh "${ORG_A}" "${APP_NAME}" "${ROLE_M}"
create-role.sh "${ORG_A}" "${APP_NAME}" "${ROLE_P}"
create-role.sh "${ORG_B}" "${APP_NAME}" "${ROLE_M}"
create-role.sh "${ORG_B}" "${APP_NAME}" "${ROLE_P}"

create-permission.sh "${ORG_A}" "${APP_NAME}" "Subscribe" "Subscribe Option for Orion PEP" "subscribecontext" "subscribe"
create-permission.sh "${ORG_A}" "${APP_NAME}" "Create" "Create Option for Orion PEP" "updatecontext" "create"
create-permission.sh "${ORG_A}" "${APP_NAME}" "Update" "Update Option for Orion PEP" "updatecontext" "update"
create-permission.sh "${ORG_A}" "${APP_NAME}" "Delete" "Delete Option for Orion PEP" "updatecontext" "delete"
create-permission.sh "${ORG_B}" "${APP_NAME}" "Subscribe" "Subscribe Option for Orion PEP" "subscribecontext" "subscribe"
create-permission.sh "${ORG_B}" "${APP_NAME}" "Create" "Create Option for Orion PEP" "updatecontext" "create"
create-permission.sh "${ORG_B}" "${APP_NAME}" "Update" "Update Option for Orion PEP" "updatecontext" "update"
create-permission.sh "${ORG_B}" "${APP_NAME}" "Delete" "Delete Option for Orion PEP" "updatecontext" "delete"

# add permissions to Publisher role
add-permission-to-role.sh "${ORG_A}" "${APP_NAME}" "${ROLE_P}" "Subscribe"
add-permission-to-role.sh "${ORG_A}" "${APP_NAME}" "${ROLE_P}" "Create"
add-permission-to-role.sh "${ORG_A}" "${APP_NAME}" "${ROLE_P}" "Update"
add-permission-to-role.sh "${ORG_A}" "${APP_NAME}" "${ROLE_P}" "Delete"
add-permission-to-role.sh "${ORG_B}" "${APP_NAME}" "${ROLE_P}" "Subscribe"
add-permission-to-role.sh "${ORG_B}" "${APP_NAME}" "${ROLE_P}" "Create"
add-permission-to-role.sh "${ORG_B}" "${APP_NAME}" "${ROLE_P}" "Update"
add-permission-to-role.sh "${ORG_B}" "${APP_NAME}" "${ROLE_P}" "Delete"

# add some users with roles
create-idm-user.sh "User A" "user.a@${IDM_HOSTNAME}" "..test"
create-idm-user.sh "User B" "user.b@${IDM_HOSTNAME}" "..test"
create-idm-user.sh "User AB" "user.ab@${IDM_HOSTNAME}" "..test"
create-idm-user.sh "User 0" "user.0@${IDM_HOSTNAME}" "..test"
create-idm-user.sh "User M" "user.m@${IDM_HOSTNAME}" "..test"

add-user-with-role.sh "user.a@${IDM_HOSTNAME}" "${ORG_A}" "${APP_NAME}" "${ROLE_P}"
add-user-with-role.sh "user.ab@${IDM_HOSTNAME}" "${ORG_A}" "${APP_NAME}" "${ROLE_P}"
add-user-with-role.sh "user.m@${IDM_HOSTNAME}" "${ORG_A}" "${APP_NAME}" "${ROLE_M}"

add-user-with-role.sh "user.b@${IDM_HOSTNAME}" "${ORG_B}" "${APP_NAME}" "${ROLE_P}"
add-user-with-role.sh "user.ab@${IDM_HOSTNAME}" "${ORG_B}" "${APP_NAME}" "${ROLE_P}"
add-user-with-role.sh "user.m@${IDM_HOSTNAME}" "${ORG_B}" "${APP_NAME}" "${ROLE_M}"
