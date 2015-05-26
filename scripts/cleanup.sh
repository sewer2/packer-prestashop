#!/bin/bash -ex

# Make sure udev does not block our network - http://6.ptmc.org/?p=164
echo "==> Cleaning up udev rules"
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

echo "==> Cleaning up leftover dhcp leases"
# Ubuntu 10.04
if [ -d "/var/lib/dhcp3" ]; then
    rm /var/lib/dhcp3/*
fi
# Ubuntu 12.04 & 14.04
if [ -d "/var/lib/dhcp" ]; then
    rm /var/lib/dhcp/*
fi 

echo "==> Cleaning up tmp"
rm -rf /tmp/*

uname -a
export APT_LISTCHANGES_FRONTEND=none
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy purge $(dpkg --list | grep '^rc' |awk '{print $2}')
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy purge $(dpkg --list | awk -v image="$(uname -r)" '/linux-image-[0-9]/{if($0 !~ image) print $2 }')
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy autoremove --purge
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -y clean
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -y autoclean


update-initramfs -u
update-grub

echo "==> Installed packages"
dpkg --get-selections | grep -v deinstall

# Remove Bash history
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/vagrant/.bash_history

# Clean up log files
find /var/log -type f | while read f; do echo -ne '' > $f; done;

# Make sure we wait until all the data is written to disk, otherwise
# Packer might quite too early before the large files are deleted
sync


echo "==> Installed packages before cleanup"
dpkg --get-selections | grep -v deinstall

# Remove some packages to get a minimal install
echo "==> Removing all linux kernels except the currrent one"
dpkg --list | awk '{ print $2 }' | grep 'linux-image-3.*-generic' | grep -v $(uname -r) | xargs apt-get -y purge
echo "==> Removing linux headers"
dpkg --list | awk '{ print $2 }' | grep linux-headers | xargs apt-get -y purge
rm -rf /usr/src/linux-headers*
echo "==> Removing linux source"
dpkg --list | awk '{ print $2 }' | grep linux-source | xargs apt-get -y purge
echo "==> Removing documentation"
dpkg --list | awk '{ print $2 }' | grep -- '-doc$' | xargs apt-get -y purge
apt-get -y purge build-essential
echo "==> Removing obsolete networking components"
apt-get -y purge ppp pppconfig pppoeconf
echo "==> Removing other oddities"
apt-get -y purge popularity-contest installation-report landscape-common wireless-tools wpasupplicant

# Clean up the apt cache
apt-get -y autoremove --purge
apt-get -y autoclean
apt-get -y clean
sed -i 's|10.0.2.15|127.0.0.1|g' /var/lib/juju/agents/unit-*/agent.conf

fstrim -v /
