#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

# /etc/machine-id after a new image is created:
COREOS_BLANK_MACHINE_ID="42000000000000000000000000000042"
MACHINE_ID_FILE="/sysroot/etc/machine-id"

# Run and log a command
bootengine_cmd() {
    ret=0
    "$@" >/tmp/bootengine.out 2>&1 || ret=$?
    vinfo < /tmp/bootengine.out
    if [ $ret -ne 0 ]; then
        warn "bootengine: command failed: $*"
        warn "bootengine: command returned $ret"
    fi
    return $ret
}

do_setup_root() {
    if ! bootengine_cmd mount -o remount,rw /sysroot; then
        warn "bootengine setup root: Can't remount root rw"
        return 0
    fi

    # Initialize base filesystem
    bootengine_cmd systemd-tmpfiles --root=/sysroot --create \
        baselayout.conf baselayout-etc.conf baselayout-usr.conf

    # Check for "initial" /etc/machine-id or a blank / non-existant
    # /etc/machine-id file and create a "real" one instead.
    if grep -qs '^[0-9a-fA-F]{32}$' "${MACHINE_ID_FILE}" && \
        [ "$(cat "${MACHINE_ID_FILE}")" != "${COREOS_BLANK_MACHINE_ID}" ] ; then
        info "bootengine: machine-id is valid"
    else
        info "bootengine: generating new machine-id"
        rm -f "${MACHINE_ID_FILE}"
        bootengine_cmd systemd-machine-id-setup --root=/sysroot
    fi
}

# Skip if root and root/usr are not mount points
if ismounted /sysroot && ismounted /sysroot/usr; then
    do_setup_root
fi
