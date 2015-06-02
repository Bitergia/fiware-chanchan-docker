#!/bin/bash

declare -A url=(
    [idm]="${IDM_URL}"
    [home]="${IDM_URL}/home"
    [sign_up]="${IDM_URL}/users/sign_up"
    [users]="${IDM_URL}/users"
)

declare -A output=(
    [sign_up]="/tmp/sign_up.output.html"
    [sign_up_form]="/tmp/sign_up_form.output.html"
    [confirmation_token]="/tmp/confirmation_token.output.html"
    [confirmation_header]="/tmp/confirmation_header.output.html"
)

# read user data
if [ "$#" -lt 3 ]; then
    echo "Missing parameters"
    exit 1
else
    user_name="$1"
    user_email="$2"
    user_password="$3"
fi

# generate cookies file for the user
cookies_path="/tmp/idmcookies"
cookies_file="${cookies_path}/${user_email}.cookies"
[ -d "${cookies_path}" ] || mkdir -p "${cookies_path}"
[ -f "${cookies_file}" ] && rm -f "${cookies_file}"

curl_options="--location --insecure --silent --show-error --cookie ${cookies_file} --cookie-jar ${cookies_file}"

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

function _sign_up () {

    local username="$1"
    local email="$2"
    local password="$3"

    # first, get the sign up page
    # this will generate a new captcha in the database

    #echo "    - Signing up"

    curl ${curl_options} \
	 --output "${output[sign_up]}" \
	 --referer "${url[idm]}/" \
	 "${url[sign_up]}"

    _random_wait

    # get the form values

    utf8=$( sed "${output[sign_up]}" -n -e "s/^.*input name=\"utf8\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" | recode html )
    authenticity_token=$( sed "${output[sign_up]}" -n -e "s/^.*input name=\"authenticity_token\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" )

    # read captcha key from sign up form
    captcha_key=$( sed "${output[sign_up]}" -n -e "s/^.*input id=\"captcha_key\" name=\"captcha_key\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" )

    # get the captcha value from the database
    captcha=$( echo "SELECT value FROM simple_captcha_data WHERE \`key\`='${captcha_key}';" | mysql --batch --skip-column-names --user=${IDM_DBUSER} --password=${IDM_DBPASS} ${IDM_DBNAME} )

    # fill the sign up form and send it
    curl ${curl_options} \
	 --output "${output[sign_up_form]}" \
	 --referer "${url[sign_up]}" \
	 --form "utf8=${utf8}" \
	 --form "authenticity_token=${authenticity_token}" \
	 --form "user[name]=${username}" \
	 --form "user[email]=${email}" \
	 --form "user[password]=${password}" \
	 --form "user[password_confirmation]=${password}" \
	 --form "captcha=${captcha}" \
	 --form "captcha_key=${captcha_key}" \
	 --form "inlineCheckbox1=option1" \
	 --form "commit=Accept" \
	 "${url[users]}"

    _random_wait
}

function _activate_account () {

    local email="$1"

    #echo "    - Activating account"
    # get the confirmation token from the database
    confirmation_token=$( echo "SELECT users.confirmation_token FROM (users LEFT JOIN actors ON (actors.id = users.actor_id)) WHERE actors.email='${email}';" | mysql --batch --skip-column-names --user=${IDM_DBUSER} --password=${IDM_DBPASS} ${IDM_DBNAME})

    curl ${curl_options} \
	 --dump-header "${output[confirmation_header]}" \
	 --output "${output[confirmation_token]}" \
	 "${url[users]}/confirmation?confirmation_token=${confirmation_token}"

}

function _check_sign_up () {

    grep -q 'class="field_with_errors"' "${output[sign_up_form]}"
    if [ $? -eq 0 ]; then
	echo "Sign up failed"
	return 1
    else
	return 0
    fi
}

function _check_activation () {

    grep -q "^Location: ${url[home]}" "${output[confirmation_header]}"
    if [ $? -eq 0 ]; then
	return 0
    else
	echo "Activation failed"
	return 1
    fi
}

### main
_cleanup

echo "*** Creating IDM user:  ${user_name}"

_sign_up "${user_name}" "${user_email}" "${user_password}"
_check_sign_up && _activate_account "${user_email}"
_check_activation
_cleanup
