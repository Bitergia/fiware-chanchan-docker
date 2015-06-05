#!/bin/bash

CC_APP_CLIENT_PATH="fiware-chanchan/client"
CC_OAUTH_CREDENTIALS="/tmp/appoauth.txt"
DEPLOY_USER=bitergia

if [ -f "${CC_OAUTH_CREDENTIALS}" ]; then
    ORGANIZATIONS=$( (echo "{" ; (cat "${CC_OAUTH_CREDENTIALS}" | paste -s -d ',') ; echo "}")  | python -m json.tool )
    su - ${DEPLOY_USER} <<EOF
cat << __EOF > ${CC_APP_CLIENT_PATH}/app/orgs.json
${ORGANIZATIONS}
__EOF
EOF
fi