#!/usr/bin/env bash
# provision-server
#
# Script used to set up freezingsaddles.org with Rocky Linux 9.
# Installs packages, configures firewalls.
#
# Adapted from MIT licensed code from:
#     https://github.com/obscureorganization/obscure-scripts/blob/main/tiamat-install.sh
#     https://github.com/PacktPublishing/Docker-for-Developers/blob/master/chapter7/bin/provision-docker.sh
#
# As such, this script is also MIT licensed.
#
# MIT Licensed
#
# Copyright 2024 Richard Bullington-McGuire
# Copyright 2020 Packt
# Copyright 2019 The Obscure Organization
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject
# to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Usage:
#     ssh rocky@example.com sudo su - < bin/provision-server.sh
#

# Set unofficial bash strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/

set -euo pipefail
IFS=$'\n\t'

DEBUG=${DEBUG:-false}

# Thanks https://stackoverflow.com/a/17805088
$DEBUG && export PS4='${LINENO}: ' && set -x

# Thanks https://askubuntu.com/a/15856
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

packages='
dnf-automatic
epel-release
firewalld
git
postfix
s-nail
sysstat
yum-utils
vim-enhanced
'

extra_packages='
bacula-client
bacula-common
bacula-libs
docker-ce
docker-ce-cli
docker-compose-plugin
containerd.io
nagios-plugins
nagios-plugins-disk
nagios-plugins-load
nagios-plugins-mysql
nagios-plugins-pgsql
nagios-plugins-procs
nagios-plugins-smtp
nagios-plugins-swap
nagios-plugins-users
nrpe
shellcheck
'

firewall_services_allow='
http
https
'

# Set up swap
SWAPFILE=/swap
if [[ ! -f "$SWAPFILE" ]]; then
    dd if=/dev/zero of="$SWAPFILE" bs=1M count=4096
    chmod 600 "$SWAPFILE"
    mkswap "$SWAPFILE"
    swapon "$SWAPFILE"
    if ! grep -q '^/swap' /etc/fstab; then
        echo "/swap swap swap defaults 0 0" >> /etc/fstab
    fi
fi


# Install packages
# Thanks https://linux.how2shout.com/enable-crb-code-ready-builder-powertools-in-almalinux-9/
# for the hint on how to enable crb to get texinfo and friends
dnf config-manager --set-enabled crb
#shellcheck disable=SC2086
dnf -y install $packages

sudo yum-config-manager --add-repo \
   https://download.docker.com/linux/centos/docker-ce.repo

#shellcheck disable=SC2086
dnf -y install $extra_packages

# Configure dnf-automatic
if [[ ! -f /etc/dnf/automatic.conf.dist ]]; then
    cp -a /etc/dnf/automatic.conf /etc/dnf/automatic.conf.dist
fi
sed -i'' -e 's/root@example.com/freezingsaddles@obscure.org/' /etc/dnf/automatic.conf


# Fix up firewall
systemctl restart firewalld
for svc in $firewall_services_allow; do
    firewall-cmd --zone=public --add-service "$svc"
done

firewall-cmd --runtime-to-permanent
firewall-cmd --reload

# Start services
services='
dnf-automatic.timer
docker
firewalld
sysstat-collect.timer
postfix
'
for svc in $services; do
	systemctl enable "$svc"
	systemctl start "$svc"
done

usermod -aG docker rocky

# Adjust selinux
setenforce Enforcing
