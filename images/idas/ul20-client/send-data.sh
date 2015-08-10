#!/bin/bash

FIGWAY_SCRIPTS_PATH=/opt/fiware-figway
IDAS_SCRIPTS_PATH=${FIGWAY_SCRIPTS_PATH}/python-IDAS4/Sensors_UL20

function send_temp_data () {

    local device_id="$1"
    local value="t|$2"
    local ret=1

    cd ${IDAS_SCRIPTS_PATH}
    local output=$( python SendObservation.py ${device_id} "${value}" )

    status_code=$( echo "${output}" | sed -n -e 's/^\* Status Code: \(.\+\)$/\1/g p' )

    case "${status_code}" in
        200)
            ret=0
            ;;
        *)
            echo "${output}"
            ret=1
            ;;
    esac

    return $ret
}

while read device_id temp ; do
    send_temp_data $device_id $temp
done
