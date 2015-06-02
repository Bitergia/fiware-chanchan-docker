#!/bin/bash

declare -A url=(
    [idm]="${IDM_URL}"
    [home]="${IDM_URL}/home"
    [applications]="${IDM_URL}/applications"
    [register_application]="${IDM_URL}/applications/new"
    [add_role]="${IDM_URL}/relation/customs"
    [add_permission]="${IDM_URL}/permission/customs"
    [permissions]="${IDM_URL}/permissions?relation_id="
)

declare -A output=(
    [register_application]="/tmp/register_application.output.html"
    [applications]="/tmp/applications.output.html"
    [application_roles]="/tmp/application_roles.output.html"
    [finish_registration]="/tmp/finish_registration.output.html"
    [header]="/tmp/header.txt"
    [add_role]="/tmp/add_role.output.html"
    [add_permission]="/tmp/add_permission.output.html"
    [permissions]="/tmp/permissions.output.html"
    [add_role_permission]="/tmp/add_role_permissions.output.html"
)

# read app data
if [ "$#" -lt 5 ]; then
    echo "Missing parameters <org_name> <app_name> <app_desc> <app_url> <app_callback>"
    exit 1
else
    org_name="$1"
    app_name="$2"
    app_desc="$3"
    app_url="$4"
    app_callback="$5"
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

function _random_wait () {
    local time=$(( ($RANDOM % 3) + 2 ))
    sleep ${time}
}

function _cleanup () {
    # remove all output files
    #echo "    - Cleaning output files"
    for f in "${output[@]}" ; do
	if [ -f "${f}" ]; then
	    rm -f "${f}"
	fi
    done
}

function _register_application () {

    local app_name="$1"
    local app_description="$2"
    local app_url="$3"
    local app_callback="$4"

    curl ${curl_options} \
	 --output "${output[register_application]}" \
	 --referer "${url[home]}" \
	 "${url[register_application]}"

    _random_wait

    utf8=$( sed "${output[register_application]}" -n -e "s/^.*input name=\"utf8\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" | recode html )
    authenticity_token=$( sed "${output[register_application]}" -n -e "s/^.*input name=\"authenticity_token\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" )

    # fill the form and send it
    curl ${curl_options} \
	 --output "${output[applications]}" \
	 --referer "${url[register_application]}" \
	 --form "utf8=${utf8}" \
	 --form "authenticity_token=${authenticity_token}" \
	 --form "application[name]=${app_name}" \
	 --form "application[description]=${app_description}" \
	 --form "application[url]=${app_url}" \
	 --form "application[callback_url]=${app_callback}" \
	 --form "commit=Next" \
	 --dump-header "${output[header]}" \
	"${url[applications]}"

    _random_wait
}

function _set_application_logo () {

    url[referer_application_logo]=$( sed "${output[header]}" -n -e 's/^Location: \(.*\)$/\1/p' )
    url[application_roles]="${url[idm]}"$( sed "${output[applications]}" -n -e 's/^.*href="\([^"]*\)" class="next-step".*$/\1/p' )

    # logo - just skip it for now
    curl ${curl_options} \
	 --output "${output[application_roles]}" \
	 --referer "${url[referer_application_logo]}" \
	 "${url[application_roles]}"

    _random_wait
}

function _finish_registration () {

    url[finish_registration]="${url[idm]}"$( sed "${output[application_roles]}" -n -e 's/^.*href="\([^"]*\)" class="next-step".*$/\1/p' )

    # finish registration
    curl ${curl_options} \
	 --output "${output[finish_registration]}" \
	 --referer "${url[application_roles]}" \
	 "${url[finish_registration]}"

    _random_wait

}

echo "*** Creating IDM application '${app_name}' on organization '${org_name}'"

_register_application "${app_name}" "${app_desc}" "${app_url}" "${app_callback}"
_set_application_logo
_finish_registration

_cleanup
