#!/usr/bin/env bash
# provision-server
#
# Script used to set up freezingsaddles.org with Rocky Linux 9.
# Installs packages, configures firewalls.
#
# Adapted from MIT licensed https://github.com/obscureorganization/obscure-scripts/blob/main/tiamat-install.sh

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
'

extra_packages='
bacula-client
bacula-common
bacula-libs
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


# Install packages
# Thanks https://linux.how2shout.com/enable-crb-code-ready-builder-powertools-in-almalinux-9/
# for the hint on how to enable crb to get texinfo and friends
dnf config-manager --set-enabled crb
#shellcheck disable=SC2086
dnf -y install $packages

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

# Start services
services='
dnf-automatic.timer
postfix
'
for svc in $services; do
	systemctl enable "$svc"
	systemctl start "$svc"
done

# Adjust selinux
setenforce Enforcing

