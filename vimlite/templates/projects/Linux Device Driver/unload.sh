#!/bin/bash
module="scull"
device="scull"
mode="666"

/sbin/rmmod $module "$@" || exit 1

rm -f /dev/${device}[0-3]

