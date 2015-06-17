#!/bin/bash
version="0.1"

service_name=
service_path=
idas_host=
idas_port=
auth_token="NULL"

function _log () {

    local _message="$*"
    local _date=$( /bin/date "+%Y/%m/%d %H:%M:%S %z" )

    # log message
    echo -e "${_date}\t${_message}"
}

function _error () {

    local _message="$*"

    _log "ERROR: ${_message}"
}

function _warning () {

    local _message="$*"

    _log "WARNING: ${_message}"
}

function _debug () {

    local _message="$*"

    if [ ${_debug} -ne 0 ]; then
        _log "DEBUG: [${_program_name}] ${_message}"
    fi
}

function show_version () {
    cat <<EOF
$0 version ${version}
EOF
exit 0
}

function usage () {
    cat <<EOF
Usage: $0 <options>

  -h  --help                 Show this help.
  -v  --version              Show program version.

  Required parameters:

  -s  --service <name>                   Specify the <name> of the service to use.
  -p  --service-path <path>              Specify the <path> of the service.
  -H  --idas-host <host>                 Specify the IDAS <host>.
  -P  --idas-port <port>                 Specify the IDAS <port>.

  Optional parameters:

  -t  --auth-token <token>               Specify the OAuth 2.0 <token> to use.
EOF
exit 0
}

function parse_options () {
    TEMP=`getopt -o hvs:p:u:k:t: -l help,version,service:,service-path:,auth-token:,idas-host:,idas-port: -- "$@"`
    if test "$?" -ne 0; then
        usage
    fi
    eval set -- "$TEMP"
    while true ; do
        case "$1" in
            -h|--help)
                usage
                ;;
            -v|--version)
                show_version
                ;;
            -s|--service)
                shift
                service_name="$1"
                ;;
            -p|--service-path)
                shift
                service_path="$1"
                ;;
	    -H|--idas-host)
		shift
		idas_host="$1"
		;;
	    -P|--idas-port)
		shift
		idas_port="$1"
		;;
	    -t|--auth-token)
		shift
		auth_token="$1"
		;;
            --|*)
                break;
                ;;
        esac
        shift
    done
    shift
    
    local missing_parameters=0
    [ -z "${service_name}" ] && _error "Required parameter '--service' is missing." && missing_parameters=1
    [ -z "${service_path}" ] && _error "Required parameter '--service-path' is missing." && missing_parameters=1
    [ -z "${idas_host}" ] && _error "Required parameter '--idas-host' is missing." && missing_parameters=1
    [ -z "${idas_port}" ] && _error "Required parameter '--idas-port' is missing." && missing_parameters=1

    [ ${missing_parameters} -ne 0 ] && usage

}

parse_options "$@"
url="http://${idas_host}:${idas_port}/iot/devices"
# send_request
curl --header "Content-Type: application/json" \
     --header "X-Auth-Token: ${auth_token}" \
     --header "Fiware-Service: ${service_name}" \
     --header "Fiware-ServicePath: ${service_path}" \
     --silent \
     --show-error \
     "${url}" | python -m json.tool
