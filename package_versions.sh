#!/bin/bash

# Copyright (c) 2016 The CoreOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

SCRIPT_ROOT=$(dirname $(readlink -f "$0"))
. "${SCRIPT_ROOT}/common.sh" || { echo "Unable to load common.sh"; exit 1; }

PACKAGES=(
	app-admin/etcd-wrapper
	app-admin/flannel
	app-admin/fleet
	app-admin/kubelet-wrapper
	app-admin/locksmith
	app-admin/mayday
	app-admin/toolbox
	app-crypt/tpmpolicy
	app-emulation/actool
	app-emulation/containerd
	app-emulation/docker
	app-emulation/rkt
	app-emulation/runc
	dev-db/etcd
	sys-apps/seismograph
	sys-apps/systemd
	sys-kernel/coreos-kernel
)

DEFINE_string channel "" \
  "The channel into which the version was released"

DEFINE_string version "" \
  "The version of the image to be inspected"

# Parse command line
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

# Die on any errors.
switch_to_strict_mode

if [ -z "${FLAGS_channel}" ] ; then
	die_notrace "--channel is required."
fi

if [ -z "${FLAGS_version}" ] ; then
	die_notrace "--version is required."
fi

raw_atoms=$(curl \
	--silent \
	--url "https://${FLAGS_channel}.release.core-os.net/amd64-usr/${FLAGS_version}/coreos_production_image_packages.txt")

atoms=()
for package in ${raw_atoms}; do
	export IFS="|"
	if grep --extended-regexp "(${PACKAGES[*]})" <<< "$package" > /dev/null; then
		atoms+=($(cut --delimiter=: --fields=1 <<< "$package"))
	fi
done
unset IFS

manifest_rev=$(cd ${SCRIPT_ROOT}/../../.repo/manifests &&
	git show v${FLAGS_version}:release.xml |
		gawk 'match($0, /coreos-overlay.*revision="([a-z0-9]*)"/, cap) {print cap[1]}')

for atom in ${atoms[*]}; do
	echo "[${atom}](https://github.com/coreos/coreos-overlay/tree/${manifest_rev}/${atom%%-[0-9]*}/${atom#*/}.ebuild)"
done
