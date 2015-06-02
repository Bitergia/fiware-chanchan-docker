#!/bin/bash

declare -A url=(
    [applications]="${IDM_URL}/applications"
    [applications_list]="${IDM_URL}/applications?section=providing"
    [add_role]="${IDM_URL}/relation/customs"
    [permissions]="${IDM_URL}/permissions?relation_id="
)

declare -A output=(
    [applications]="/tmp/applications.output.txt"
    [applications_list]="/tmp/applications_list.output.txt"
    [application_profile]="/tmp/application_profile.output.txt"
    [edit_application_profile]="/tmp/edit_application_profile.output.txt"
    [add_role]="/tmp/add_role.output.txt"
    [permissions]="/tmp/permissions.output.html"    
)

declare -A oauth

# read parameters
if [ "$#" -lt 3 ]; then
    echo "Missing parameters: <org_name> <app_name> <role_name>"
    exit 1
else
    org_name="$1"
    app_name="$2"
    role_name="$3"
fi

# cookies file for the organization
cookies_path="/tmp/idmcookies"
cookies_org_file="${cookies_path}/${org_name// }.cookies"
[ -d "${cookies_path}" ] || mkdir -p "${cookies_path}"
if [ ! -f "${cookies_org_file}" ]; then
    echo "Failed to find the cookies file for organization '${org_name}'"
    echo "Login and switch session first to generate the cookies file or create the organization if it doesn't exist."
    exit 1
fi

curl_options="--location --insecure --silent --show-error --cookie ${cookies_org_file} --cookie-jar ${cookies_org_file}"

function _find_application () {

    local app="$1"
    local retval=0
    
    curl ${curl_options} \
	 --referer "${output[applications]}" \
	 --output "${output[applications_list]}" \
	 --header "X-Requested-With: XMLHttpRequest" \
	 "${url[applications_list]}"

    url[application_profile]="${IDM_URL}"$( sed "${output[applications_list]}" -n -e "s/^.*href=\"\([^\"]*\)\">${app}<\/a>.*$/\1/p" )
    if [ "${url[application_profile]}" == "${IDM_URL}" ]; then
	# application not found within this organization
	echo "Application '${app}' not found on organization '${org_name}'"
	retval=1
    else
	# application profile url found
	retval=0
    fi
    
    return $retval
}

function _edit_application_profile () {

    curl ${curl_options} \
	 --referer "${url[applications_list]}" \
	 --output "${output[application_profile]}" \
	 "${url[application_profile]}"

    url[edit_application_profile]="${url[application_profile]}/edit"
    
    curl ${curl_options} \
	 --referer "${url[application_profile]}" \
	 --output "${output[edit_application_profile]}" \
	 "${url[edit_application_profile]}"
    
}

function _add_role () {

    local name="$1"
    
    utf8=$( sed "${output[edit_application_profile]}" -n -e "/action=\"\/relation\/customs\"/ s/^.*input name=\"utf8\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" | recode html )
    authenticity_token=$( sed "${output[edit_application_profile]}" -n -e "/action=\"\/relation\/customs\"/ s/^.*input name=\"authenticity_token\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" )
    actor_id=$(sed "${output[edit_application_profile]}" -n -e "s/^.*input.*name=\"relation_custom\[actor_id\]\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" )

    curl ${curl_options} \
	 --output "${output[add_role]}" \
	 --referer "${url[edit_application_profile]}" \
	 --data "utf8=${utf8}" \
	 --data "authenticity_token=${authenticity_token}" \
	 --data "relation_custom[actor_id]=${actor_id}" \
	 --data "relation_custom[name]=${name}" \
	 --data "commit=Save" \
	 --header "X-Requested-With: XMLHttpRequest" \
	 --header "X-CSRF-Token: ${authenticity_token}" \
	 --header "Accept: */*;q=0.5, text/javascript, application/javascript, application/ecmascript, application/x-ecmascript" \
	 "${url[add_role]}"

#    _random_wait

    role_id=$( cat "${output[add_role]}" | grep "id:" | tr -d ' ' | sed -e 's/^id://g' -e 's/,$//g' )

    curl ${curl_options} \
	 --output "${output[permissions]}" \
	 --referer "${url[application_roles]}" \
	 --header "X-Requested-With: XMLHttpRequest" \
	 --header "X-CSRF-Token: ${authenticity_token}" \
	 "${url[permissions]}${role_id}"

}


retval=1
_find_application "${app_name}"
if [ $? -eq 0 ]; then
    _edit_application_profile
    _add_role "${role_name}"
    retval=0
fi

# clean output temp files
for f in "${output[@]}" ; do
    if [ -f "${f}" ]; then
	rm -f "${f}"
    fi
done

exit $retval
