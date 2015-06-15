#!/bin/bash
_dev=${1:-0}
acpi -t | grep "Thermal ${_dev}" | awk '{print $4}'
