#!/bin/bash -ex

cat <<EOF > /etc/resolv.conf
#nameserver 2001:4860:4860::8888
#nameserver 2001:4860:4860::8844
nameserver 8.8.8.8
nameserver 8.8.4.4
options timeout:2 attempts:1 rotate
EOF

apt-get -y --force-yes update
apt-get -y --force-yes dist-upgrade
apt-get -y --force-yes install curl

#if [ "x${PACKER_BUILD_TYPE}" == "xqemu" ]; then
    apt-get -y --force-yes install grub-pc
    export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
    dpkg-reconfigure grub-pc
    sed -i 's|#GRUB_DISABLE_LINUX_UUID=true|GRUB_DISABLE_LINUX_UUID=true|g' /etc/default/grub
    sed -i 's|#GRUB_DISABLE_RECOVERY="true"|GRUB_DISABLE_RECOVERY="true"|g' /etc/default/grub
    sed -i 's|GRUB_TIMEOUT=10|GRUB_TIMEOUT=5|g' /etc/default/grub
    sed -i 's|GRUB_CMDLINE_LINUX=""|GRUB_CMDLINE_LINUX="consoleblank=0"|g' /etc/default/grub
    sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="quiet"|GRUB_CMDLINE_LINUX_DEFAULT="consoleblank=0"|g' /etc/default/grub
    update-grub
#fi

cat <<EOF > /etc/fstab
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system> <mount point>   <type>          <options>                        <dump>  <pass>
/dev/sda1       /               ext4    defaults,relatime,discard,errors=panic      0       1
EOF

cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet6 auto
iface eth0 inet dhcp
#dns-nameservers 2001:4860:4860::8888 2001:4860:4860::8844 8.8.8.8 8.8.4.4
dns-nameservers 8.8.8.8 8.8.4.4

EOF
