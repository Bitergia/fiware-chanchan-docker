#!/bin/bash
version="0.1"

fake_min=none
fake_max=none
fake_cur=none
fake_var=none
fake_id=none
fake_type=none
fake_default_id=0
fake_default_type=random
use_sensor=none
delay=10
runpath="/var/run/therm-sensors"
FIGWAY_SCRIPTS_PATH=/opt/fiware-figway/python-IDAS4
IDAS_SCRIPTS_PATH=${FIGWAY_SCRIPTS_PATH}/Sensors_UL20

function _log () {

    local _message="$*"
    local _date=$( /bin/date "+%Y/%m/%d %H:%M:%S %z" )

    # log message
    echo -e "${_date}\t${_message}" >&2
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
    cat <<EOF >&2
$0 version ${version}
EOF
exit 0
}

function usage () {
    cat <<EOF >&2
Usage: $0 <options>

  -h  --help                 Show this help.
  -v  --version              Show program version.

  Required parameters:

  -f  --fake                 Use a fake sensor (generates random data).  Use --min and --max to set minimum and maximum values allowed.
  -a  --acpi                 Use acpi detected thermal sensors.
  -s  --sys                  Use sensors from /sys/class/thermal/.

  Extra parameters for fake sensor:

  -m  --min <value>          Minimum <value> for fake sensor.
  -M  --max <value>          Maximum <value> for fake sensor.
  -V  --variance <value>     Maximum variance between generated values.
  -i  --id <id>              Id for the fake sensor.  Default value is '0'.
  -t  --type <type>          Type of the fake sensor.  Default value is 'random'.

  Optional parameters:

  -d  --delay <value>        Delay in seconds between sensor readings. Default is 10 seconds.

EOF
exit 0
}

function parse_options () {
    TEMP=`getopt -o hvfasm:M:d:V:i:t: -l help,version,fake,acpi,sys,min:,max:,delay:,variance:,id:,type: -- "$@"`
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
            -f|--fake)
                use_sensor=fake
                ;;
            -a|--acpi)
                use_sensor=acpi
                ;;
            -s|--sys)
                use_sensor=sys
                ;;
            -m|--min)
                shift
                fake_min=$1
                ;;
            -M|--max)
                shift
                fake_max=$1
                ;;
            -d|--delay)
                shift
                delay=$1
                ;;
            -V|--variance)
                shift
                fake_var=$1
                ;;
	    -i|--id)
		shift
		fake_id="$1"
		;;
	    -t|--type)
		shift
		fake_type="$1"
		;;
            --|*)
                break;
                ;;
        esac
        shift
    done
    shift

    local missing_parameters=0
    if [ "${use_sensor}" = "fake" ] ; then
        [ "${fake_min}" = "none" ] && _error "Required parameter '--min' is missing." && missing_parameters=1
        [ "${fake_max}" = "none" ] && _error "Required parameter '--max' is missing." && missing_parameters=1
        [ "${fake_var}" = "none" ] && _error "Required parameter '--variance' is missing." && missing_parameters=1
        [ ${fake_min} -ge ${fake_max} ] && _error "--min value must be lower than --max value." && missing_parameters=1
	[ "${fake_id}" = "none" ] && fake_id="${fake_default_id}"
	[ "${fake_type}" = "none" ] && fake_type="${fake_default_type}"
    fi

    [ "${use_sensor}" = "none" ] && _error "Must specify one type of sensor: fake, acpi, sys." && missing_parameters=1

    [[ ! ${delay} =~ ^\+?[0-9]+$ ]] && _error "delay value must be a positive integer." && missing_parameters=1
    [ ${delay} -lt 1 ] && _error "delay value must be greater than 0." && missing_parameters=1

    [ ${missing_parameters} -ne 0 ] && usage

}

function register_sensor () {

    local device_id="$1"
    local entity_id="SENSOR_TEMP_${device_id}"
    local ret=1

    if [ -e "${runpath}/${device_id}" ] ; then
	_log "Device '${device_id}' is already registered."
    else
	cd ${IDAS_SCRIPTS_PATH}
	local output=$( python RegisterDevice.py SENSOR_TEMP ${device_id} ${entity_id} )

	status_code=$( echo "${output}" | sed -n -e 's/^\* Status Code: \(.\+\)$/\1/g p' )

	case "${status_code}" in
	    201)
		_log "Registered new device '${device_id}' on entity '${entity_id}'"
		touch "${runpath}/${device_id}"
		ret=0
		;;
	    *)
		_error "${output}"
		ret=1
		;;
	esac
    fi
    return $ret
}

function check_acpi_sensors () {
    local ret=0
    local n=$( acpi -t | grep ^Thermal | wc -l )
    if [ $n -lt 1 ]; then
        _error "No thermal sensors found using acpi"
        ret=1
    else
	acpi -t | while read line ; do
	    id=$( echo "${line}" | sed -e "s/^Thermal \([0-9]\+\): .*, \([^ ]\+\) degrees.*/${HOSTNAME}_ACPI_\1_Thermal/g" )
	    value=$( echo "${line}" | sed -e "s/^Thermal \([0-9]\+\): .*, \([^ ]\+\) degrees.*/\2/g" )
	    register_sensor "${id}"
	done
    fi
    return $ret
}

function check_sys_sensors () {
    local ret=0
    local n=$( ls  /sys/class/thermal/ | grep thermal_zone | wc -l )
    if [ $n -lt 1 ]; then
        _error "No thermal sensors found using /sys/class/thermal"
        ret=1
    else
	for i in $( ls /sys/class/thermal/ | grep thermal_zone ) ; do
            local type=$( cat /sys/class/thermal/${i}/type | sed -e 's/ /_/g' )
            register_sensor "${HOSTNAME}_SYS_${i}_${type}"
	done
    fi
    return $ret
}

function sys_sensors () {
    for i in $( ls /sys/class/thermal/ | grep thermal_zone ) ; do
        local temp0=$( cat /sys/class/thermal/${i}/temp )
        local temp1=$((${temp0}/1000))
        local temp2=$((${temp0}/100))
        local tempm=$((${temp2} % ${temp1}))
        local value="${temp1}.${tempm}"
        local type=$( cat /sys/class/thermal/${i}/type | sed -e 's/ /_/g' )
        echo "${HOSTNAME}_SYS_${i}_${type} ${value}"
    done
}

function fake_sensor () {

    local id="$1"
    local type="$2"

    if [ "${fake_cur}" = "none" ] ; then
        fake_cur=$(( $RANDOM % (${fake_max} - ${fake_min} + 1) + ${fake_min} ))
    else
        var_sign=$(( $RANDOM % 2 ))
	var_val=$(( $RANDOM % ( ${fake_var} + 1 ) ))
	if [ ${var_sign} -eq 0 ] ; then
	    fake_cur=$(( ${fake_cur} + ${var_val} ))
	    [ ${fake_cur} -gt ${fake_max} ] && fake_cur=${fake_max}
	else
	    fake_cur=$(( ${fake_cur} - ${var_val} ))
	    [ ${fake_cur} -lt ${fake_min} ] && fake_cur=${fake_min}
	fi
    fi
    echo "${HOSTNAME}_FAKE_${id}_${type} ${fake_cur}"
}

function acpi_sensors () {
    acpi -t | while read line ; do
	id=$( echo "${line}" | sed -e "s/^Thermal \([0-9]\+\): .*, \([^ ]\+\) degrees.*/${HOSTNAME}_ACPI_\1_Thermal/g" )
	value=$( echo "${line}" | sed -e "s/^Thermal \([0-9]\+\): .*, \([^ ]\+\) degrees.*/\2/g" )
	echo "${id} ${value}"
    done
}

function generate_data () {
    local func="$1"
    shift
    local params="$@"
    while true ; do
	${func} ${params}
	sleep ${delay}
    done
}

parse_options "$@"

[ -d "${runpath}" ] || mkdir -p "${runpath}"


case "${use_sensor}" in
    "fake")
	register_sensor "${HOSTNAME}_FAKE_${fake_id}_${fake_type}"
	generate_data fake_sensor "${fake_id}" "${fake_type}"
	;;
    "acpi")
	check_acpi_sensors || exit 1
	generate_data acpi_sensors
	;;
    "sys")
	check_sys_sensors || exit 1
	generate_data sys_sensors
	;;
    *)
	_error "Unknown sensor type: '${use_sensor}'."
	exit 1
	;;
esac
