#!/bin/bash

declare -A url=(
    [login]="${IDM_URL}"
    [sign_in]="${IDM_URL}/users/sign_in"
)
declare -A output=(
    [login]="/tmp/login.output.txt"
    [sign_in]="/tmp/sign_in.output.txt"
)

# read login (email) and password
if [ "$#" -lt 2 ]; then
    echo "Missing parameters <user_email> <user_password>"
    exit 1
else
    user_email="$1"
    user_password="$2"
fi

# generate cookies file for the user
cookies_path="/tmp/idmcookies"
cookies_file="${cookies_path}/${user_email}.cookies"
[ -d "${cookies_path}" ] || mkdir -p "${cookies_path}"
[ -f "${cookies_file}" ] && rm -f "${cookies_file}"

curl_options="--location --insecure --silent --show-error --cookie ${cookies_file} --cookie-jar ${cookies_file}"

# get login page
curl ${curl_options} \
    --output "${output[login]}" \
    "${url[login]}"

utf8=$( sed "${output[login]}" -n -e "s/^.*input name=\"utf8\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" | recode html )
authenticity_token=$( sed "${output[login]}" -n -e "s/^.*input name=\"authenticity_token\" type=\"hidden\" value=\"\([^\"]*\).*$/\1/p" )

# fill the form and send it
curl ${curl_options} \
    --output "${output[sign_in]}" \
    --referer "${url[login]}" \
    --form "utf8=${utf8}" \
    --form "authenticity_token=${authenticity_token}" \
    --form "user[email]=${user_email}" \
    --form "user[password]=${user_password}" \
    --form "user[remember_me]=1" \
    --form "commit=Sign in" \
    "${url[sign_in]}"

# check for successful login
grep -q "Fiware.signOut" "${output[sign_in]}"
if [ $? -eq 0 ]; then
    echo "${user_email} Login successful"
    retval=0
else
    echo "${user_email} Login failed"
    # remove the cookies
    [ -f "${cookies_file}" ] && rm -f "${cookies_file}"
    retval=1
fi

# clean output temp files
for f in "${output[@]}" ; do
    if [ -f "${f}" ]; then
	rm -f "${f}"
    fi
done

exit $retval
