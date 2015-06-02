#!/bin/bash

declare -A url=(
    [idm]="${IDM_URL}"
    [home]="${IDM_URL}/home"
)
declare -A output=(
    [home]="/tmp/home.output.txt"
    [organization]="/tmp/organization.output.txt"
)

# read login (email) and organization
if [ "$#" -lt 2 ]; then
    echo "Missing parameters <user_email> <org_name>"
    exit 1
else
    user_email="$1"
    organization="$2"
fi

# cookies file for the user
cookies_path="/tmp/idmcookies"
cookies_user_file="${cookies_path}/${user_email}.cookies"
cookies_organization_file="${cookies_path}/${organization// }.cookies"
[ -d "${cookies_path}" ] || mkdir -p "${cookies_path}"
if [ ! -f "${cookies_user_file}" ]; then
    echo "Failed to find the cookies file for user ${user_email}."
    echo "Login first to generate the cookies file or create the user if it doesn't exist."
    exit 1
fi

curl_options="--location --insecure --silent --show-error --cookie ${cookies_user_file} --cookie-jar ${cookies_user_file}"

# get home page
curl ${curl_options} \
     --output "${output[home]}" \
     "${url[home]}"

# get organization session url
url[organization]="${url[idm]}"$( sed "${output[home]}" -n -e "s/^.*href=\"\([^\"]*\)\".*title=\"${organization}\".*$/\1/p" )
if [ "${url[organization]}" == "${url[idm]}" ]; then
    # organization not found with this user
    echo "Organization '${organization}' not found.  Can't switch session"
    exit 1
fi

curl_options="--location --insecure --silent --show-error --cookie ${cookies_user_file} --cookie-jar ${cookies_organization_file}"

# switch session to organization
curl ${curl_options} \
     --referer "${url[home]}" \
     --output "${output[organization]}" \
     "${url[organization]}"

# check for successful session switch
grep -q "Your identity has changed. Now you are acting on behalf of the “${organization}” organization." "${output[organization]}"
if [ $? -eq 0 ]; then
    echo "${organization} Session switch successful"
    retval=0
else
    echo "${organization} Session switch failed"
    # remove the cookies
    [ -f "${cookies_organization_file}" ] && rm -f "${cookies_organization_file}"
    retval=1
fi

# clean output temp files
for f in "${output[@]}" ; do
    if [ -f "${f}" ]; then
	rm -f "${f}"
    fi
done

exit $retval
