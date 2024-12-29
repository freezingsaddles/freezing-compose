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

# Ensure Freezing Saddles site comes up on reboot
# It runs with Docker Compose so this should be sufficient.
# nginx was not starting as expected sometimes.
# https://github.com/freezingsaddles/freezing-compose/issues/5
#
# Thanks https://unix.stackexchange.com/a/271666 for inspiration
# shellcheck disable=SC2154
cat > /usr/local/bin/restart-on-reboot.sh <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [[ -d /opt/compose ]]; then
   (
    cd /opt/compose
    sleep 60
    docker compose ps
    docker compose up -d
    docker compose ps
   ) 2>&1 | logger -t freezingsaddles
fi
EOF
chmod 750 /usr/local/bin/restart-on-reboot.sh
crontab <<EOF
@reboot /usr/local/bin/restart-on-reboot.sh
EOF

# Re-establish Icinga monitoring for freezingsaddles.org #37
# https://github.com/freezingsaddles/freezing-compose/issues/37
# allow icinga to SSH into the nagios user.
# I already fixed the icinga config to remove the agent-based assumption.
mkdir -p ~nagios/.ssh
cat > ~nagios/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0X58CF7gH0cVPjlrpN/V0ovMHvVS2uhxSaom7+nNb9QuhOZMO2fhEdYGLgGmETnWHGZLXtu5J+uBnafTSxk+EzraHR/1WXCPAhIjelbdTpi606cNssvfqr3ByzNbhm6wg6jsdmLNeabdK3ok7UGh5W+dUsrk+5ZjwCqOzSgU3Mvm+VuQQQ8czx4EASNZOZUsTR/sMCaUfU+5mLKy1Zz7xaZp4FEhCLQ7pEu9IdugRmwNlMKwCW7Qc4bO0y5cA26ghuuZJSdJbnPXTOZYoLV9fpr5QC6ZydMhtEi/kx4aGhCofyOxqeCK6MvMlr4wt6jGY7vIu4bePFj8CL683LRPotkqHnyi65CEkf4UNLjCJwnZMA2GVxAyKgrF8LTTlbaijjBYIPj0gyDuUk6IDfJi8v1RG+bQ82NFWAXela026zIb9zjaz9xDd+IevA+p/0DVIKS4OLpSBof4UfK1mhDUwMDImTC57Ug4P9jSlXxwlWnVxcrU89vXFGBWvJyGfYkCoPPa9AvyS7BYSexg1ylWnxMbnJZsuKb1usEjbSg8Pg4RdxdRO47qSDFTF70W4v7O/85DdkCc6AcxKwXhLhQSvNdyhVGUi66AwYPwxqfE7d+i+ADM2E9f5gajhCYaO96oxd7q8iUcPv8yRRxH7wQdFNWM1tTcuHA6DIzBXY0GhGw== icinga@ur.obscure.org
EOF
chmod 700 ~nagios/.ssh
chmod 600 ~nagios/.ssh/authorized_keys
chown -R nagios:nagios ~nagios/.ssh
semanage fcontext -a -t ssh_home_t "/var/spool/nagios/.ssh/(.*)?"
restorecon -Rv /var/spool/nagios/.ssh
# Thanks https://unix.stackexchange.com/a/22731
usermod -s /bin/bash nagios
