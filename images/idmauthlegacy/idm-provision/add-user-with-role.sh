#!/bin/bash

declare -A url=(
    [home]="${IDM_URL}/home"
    [contacts]="${IDM_URL}/contacts"
    [applications]="${IDM_URL}/applications"
    [applications_list]="${IDM_URL}/applications?section=providing"
)

declare -A output=(
    [home]="/tmp/home.output.txt"
    [contacts]="/tmp/contacts.output.txt"
    [applications]="/tmp/applications.output.txt"
    [applications_list]="/tmp/applications_list.output.txt"
    [application_profile]="/tmp/application_profile.output.txt"
    [edit_application_profile]="/tmp/edit_application_profile.output.txt"
    [update_contacts]="/tmp/update_contacts.output.txt"
    [add_contact]="/tmp/add_contact.output.txt"
)

role_id=""
user_id=""
org_id=""
contact_id=""

# read parameters
if [ "$#" -lt 4 ]; then
    echo "Missing parameters: <user_email> <org_name> <app_name> <role_name>"
    exit 1
else
    user_email="$1"
    org_name="$2"
    app_name="$3"
    role_name="$4"
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
	 --referer "${url[home]}" \
	 --output "${output[home]}" \
	 "${url[home]}"
    
    grep -q "Fiware.signOut" "${output[home]}"
    if [ $? -ne 0 ]; then
	echo "Organization session lost."
	# remove the cookies
	[ -f "${cookies_org_file}" ] && rm -f "${cookies_org_file}"
	return 1
    fi
    
    curl ${curl_options} \
	 --referer "${url[applications]}" \
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

function _find_role () {

    local role_name="$1"
    
    retval=0
    role_id=$( sed "${output[edit_application_profile]}" -n -e "s/^.*<label for=\"input_relation_custom_\([0-9]*\)\">${role_name}<\/label>.*$/\1/p" )
    if [ -z ${role_id} ]; then
	echo "Role '${role_name}' not found for application '${app_name}'."
	retval=1
    fi
    return $retval
}

function _find_user () {

    local email="$1"

    retval=0
    user_id=$( echo "SELECT id FROM actors WHERE email='${email}';" | mysql --batch --skip-column-names --user=${IDM_DBUSER} --password=${IDM_DBPASS} ${IDM_DBNAME} )
    if [ -z ${user_id} ]; then
	echo "User '${email}' not found."
	retval=1
    fi
    return $retval
}

function _find_organization () {

    local org="$1"

    retval=0
    org_id=$( echo "SELECT id FROM actors WHERE name='${org}';" | mysql --batch --skip-column-names --user=${IDM_DBUSER} --password=${IDM_DBPASS} ${IDM_DBNAME} )
    if [ -z ${org_id} ]; then
	echo "Organization '${org}' not found."
	retval=1
    fi
    return $retval
}

function _find_contact () {
    
    retval=0
    contact_id=$( echo "SELECT id FROM contacts WHERE sender_id=${org_id} AND receiver_id=${user_id} and ties_count > 0" | mysql --batch --skip-column-names --user=${IDM_DBUSER} --password=${IDM_DBPASS} ${IDM_DBNAME} )
    if [ -z ${contact_id} ]; then
	# no contact found -> add new contact
	retval=1
    fi
    return $retval
    
}

function _get_contacts_list () {

    curl ${curl_options} \
	 --referer "${url[contacts]}" \
	 --output "${output[contacts]}" \
	 "${url[contacts]}"

    retval=0
    grep "/organizations" "${output[contacts]}" | grep -q "contacts"
    if [ $? -ne 0 ]; then
	echo "Failed to get contacts list for organization '${org_name}'"
	retval=1
    fi
    return $retval
}

function _update_contact () {

    retval=0

    utf8=$( sed "${output[contacts]}" -n -e "/action=\"\/contacts\/${contact_id}\"/ s/^.*input name=\"utf8\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" | recode html )
    authenticity_token=$( sed "${output[contacts]}" -n -e "/action=\"\/contacts\/${contact_id}\"/ s/^.*input name=\"authenticity_token\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" )
    relations_list=$( (sed "${output[contacts]}" -e "s/></>&\n</g" | sed -n -e "/action=\"\/contacts\/${contact_id}\"/,/<\/form>/ s/^.*value=\"\([^\"]*\)\" selected=\"selected\".*$/\1/p" ; echo ${role_id} )| sort -u )

    curl ${curl_options} \
	 --referer "${url[contacts]}" \
	 --output "${output[update_contacts]}" \
	 --data "utf8=${utf8}" \
	 --data "_method=put" \
	 --data "authenticity_token=${authenticity_token}" \
	 --data "contact[relation_ids][]" \
	 $( for id in ${relations_list} ; do
		echo "--data contact[relation_ids][]=${id}"
	    done
	 ) \
	 --header "X-Requested-With: XMLHttpRequest" \
	 --header "X-CSRF-Token: ${authenticity_token}" \
	 --header "Accept: */*;q=0.5, text/javascript, application/javascript, application/ecmascript, application/x-ecmascript" \
	 "${url[contacts]}/${contact_id}"

    grep -q "SocialStream.Contact.update({ id: \"${contact_id}\" });" "${output[update_contacts]}"
    if [ $? -ne 0 ]; then
	retval=1
    fi
    
    return $retval
}

function _add_new_contact () {

    partial_url=$( sed "${output[contacts]}" -n -e "s/^.*href=\"\([^\"]*\)\".*title=\"${org_name}\".*$/\1\/contacts/p" | sed -e 's,/,\\/,g' )
    url[organization_contacts]="${IDM_URL}"$( sed "${output[contacts]}" -n -e "s/^.*href=\"\([^\"]*\)\".*title=\"${org_name}\".*$/\1\/contacts/p" )
    utf8=$( sed "${output[contacts]}" -n -e "/action=\"${partial_url}\"/ s/^.*input name=\"utf8\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" | recode html )
    authenticity_token=$( sed "${output[contacts]}" -n -e "/action=\"${partial_url}\"/ s/^.*input name=\"authenticity_token\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" )

    retval=0
    curl ${curl_options} \
	 --referer "${url[contacts]}" \
	 --output "${output[add_contact]}" \
	 --form "utf8=${utf8}" \
	 --form "authenticity_token=${authenticity_token}" \
	 --form "actors=${user_id}" \
	 --form "relations[]=${role_id}" \
	 --form "commit=Add" \
	 "${url[organization_contacts]}"

    _get_contacts_list
    
    return $retval
}

_find_organization "${org_name}" && \
_find_application "${app_name}" && \
_edit_application_profile && \
_find_role "${role_name}" && \
_find_user "${user_email}" && \
_find_contact
if [ $? -eq 0 ]; then
    # add to existing contact
    _get_contacts_list
    _update_contact
    retval=$?
else
    # add new contact
    _get_contacts_list
    _add_new_contact
    retval=$?
fi

for f in "${output[@]}" ; do
    if [ -f "${f}" ]; then
	rm -f "${f}"
    fi
done
    
exit $retval
