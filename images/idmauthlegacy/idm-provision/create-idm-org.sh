#!/bin/bash

declare -A url=(
    [idm]="${IDM_URL}"
    [home]="${IDM_URL}/home"
    [organizations]="${IDM_URL}/organizations"
    [register_organization]="${IDM_URL}/organizations/new"
)

declare -A output=(
    [register_organization]="/tmp/register_organization.output.html"
    [organizations]="/tmp/organizations.output.html"
)

# read org data
if [ "$#" -lt 3 ]; then
    echo "Missing parameters"
    exit 1
else
    user_email="$1"
    org_name="$2"
    org_desc="$3"
fi

# generate cookies file for the organization
cookies_path="/tmp/idmcookies"
cookies_user_file="${cookies_path}/${user_email}.cookies"
cookies_org_file="${cookies_path}/${org_name// }.cookies"
[ -d "${cookies_path}" ] || mkdir -p "${cookies_path}"
[ -f "${cookies_org_file}" ] && rm -f "${cookies_org_file}"

curl_options="--location --insecure --silent --show-error --cookie ${cookies_user_file} --cookie-jar ${cookies_user_file}"

function _random_wait () {
    # random wait to use between curl requests
    local time=$(( ($RANDOM % 3) + 2 ))
    sleep ${time}
}

function _cleanup () {
    # remove all output files
    for f in "${output[@]}" ; do
	if [ -f "${f}" ]; then
	    rm -f "${f}"
	fi
    done
}

function _register_organization () {

    local name="$1"
    local description="$2"

    curl ${curl_options} \
	 --output "${output[register_organization]}" \
	 --referer "${url[home]}" \
	 "${url[register_organization]}"

    _random_wait

    utf8=$( sed "${output[register_organization]}" -n -e "s/^.*input name=\"utf8\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" | recode html )
    authenticity_token=$( sed "${output[register_organization]}" -n -e "s/^.*input name=\"authenticity_token\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" )
    owners=$( sed "${output[register_organization]}" -n -e 's/.*name="organization\[owners\]" type="hidden" value="\([^"]*\).*$/\1/p' )

    # fill the form and send it
    curl ${curl_options} \
	 --cookie ${cookies_user_file} \
	 --cookie-jar ${cookies_org_file} \
	 --output "${output[organizations]}" \
	 --referer "${url[register_organization]}" \
	 --form "utf8=${utf8}" \
	 --form "authenticity_token=${authenticity_token}" \
	 --form "organization[name]=${name}" \
	 --form "organization[owners]=${owners}" \
	 --form "organization[description]=${description}" \
	 --form "commit=Create Organization" \
	 "${url[organizations]}"

    _random_wait
}


### main
echo "*** Creating IDM organization:  ${org_name}"

_register_organization "${org_name}" "${org_desc}"
_cleanup
