#!/bin/sh

# e.g. PCIe SSD
# block_name=/dev/block/by-name/userdata
# device=/devices/platform/3c0800000.pcie/pci0002:20/0002:20:00.0/0002:21:00.0/nvme/nvme0/nvme0n1/nvme0n1p7
# block_num=7
# block_name=/dev/nvme0n1p7
# device=/dev/nvme0n1

block_name=$1
device=$(udevadm info --query=path --name=${block_name})

block_num=${device##*[a-zA-Z]}
block_name="/dev/$(echo ${device} | awk -F'/' '{print $NF}')"
device="/dev/$(echo ${device} | awk -F'/' '{print $(NF-1)}')"

block_end=""

for x in $(cat /proc/cmdline); do
	case ${x} in
		virtual_lba_count=*)
			block_end=`expr $(echo ${x} | cut -f 2 -d =) - 34`s
		;;
	esac
done

cat /proc/cmdline | grep -q "virtual_header_lba"
if [[ $? != 0 ]]; then
/usr/sbin/sgdisk -e ${device}
/usr/sbin/parted ${device} <<EOF
resizepart ${block_num} -34s
q
EOF
else
	cat /proc/cmdline | grep -q "virtual_header_lba=1"
	if [[ $? == 0 ]]; then
/usr/sbin/sgdisk -e ${device}
/usr/sbin/parted ${device} <<EOF
resizepart ${block_num} ${block_end}
q
EOF
	fi
fi
/sbin/mke2fs -t ext4 -b 4096 -O ^huge_file -m 0 -q -F ${block_name}
/sbin/e2fsck -fy ${block_name}
