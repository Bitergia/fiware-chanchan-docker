#!/bin/bash

source ${SCRIPTS_DIR}/variables.sh

declare -A url=(
    [applications]="${IDM_URL}/applications"
    [applications_list]="${IDM_URL}/applications?section=providing"
)

declare -A output=(
    [applications]="/tmp/applications.output.txt"
    [applications_list]="/tmp/applications_list.output.txt"
    [application_profile]="/tmp/application_profile.output.txt"
)

declare -A oauth

# read parameters
if [ "$#" -lt 2 ]; then
    echo "Missing parameters <org_name> <app_name>"
    exit 1
else
    org_name="$1"
    app_name="$2"
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

function _get_oauth_data () {

    curl ${curl_options} \
        --referer "${url[applications_list]}" \
        --output "${output[application_profile]}" \
        "${url[application_profile]}"

    # get oauth credentials for the app
    oauth[id]=$( cat "${output[application_profile]}" | tr -d '\n' | tr -d ' ' |
        sed -n -e 's|.*divclass="client-id"><h6>ClientID</h6><p>\([^<]*\)</p></div>.*|\1|p' )
    oauth[secret]=$( sed "${output[application_profile]}" -n -e 's/^.*span class="site-client-secret">\(.*\)<\/span>/\1/p')

    if [ -z "${oauth[id]}" -o -z "${oauth[secret]}" ]; then
        echo "Failed to get oauth credentials for '${app_name}'."
        retval=1
    else
        retval=0
    fi
    return $retval

}

function _dump_oauth_data () {

    _tag=$( echo ${org_name} | sed -e "s/ /_/g; s/^\(...\).*\(..\)$/\L\1\2/" )
    echo "\"${_tag}\": { \"name\": \"${org_name}\", \"id\": \"${oauth[id]}\", \"secret\": \"${oauth[secret]}\"}" >> "${CC_OAUTH_CREDENTIALS}" && \
    cat "${CC_OAUTH_CREDENTIALS}" | sort -u > "${CC_OAUTH_CREDENTIALS}.tmp" && \
    mv "${CC_OAUTH_CREDENTIALS}.tmp" "${CC_OAUTH_CREDENTIALS}"
}

retval=1
_find_application "${app_name}"
if [ $? -eq 0 ]; then
    _get_oauth_data
    if [ $? -eq 0 ]; then
        _dump_oauth_data && retval=0
    fi
fi

# clean output temp files
for f in "${output[@]}" ; do
    if [ -f "${f}" ]; then
        rm -f "${f}"
    fi
done

exit $retval