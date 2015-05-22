#!/bin/sh -ex

apt-get clean
/var/lib/apt -type f | xargs rm -f

rm -rf /root/charms/
apt-get -y purge cloud-init

fstrim -v /
