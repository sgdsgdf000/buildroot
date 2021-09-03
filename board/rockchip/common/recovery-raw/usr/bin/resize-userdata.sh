#!/bin/sh

resolve_device() {
	local BOOTMEDIA=""
	local BOOTDEVICE="/dev"
	local BOOTNODE=""
	local NODENAME=""
	local NODEADDR=""

	for x in $(cat /proc/cmdline); do
			case ${x} in
				storagemedia=*)
					BOOTMEDIA=$(echo ${x} | cut -f 2 -d =)
				;;
				storagenode=*)
					BOOTNODE=$(echo ${x} | sed 's/\///g' | cut -f 2 -d =)
					NODENAME=$(echo "$BOOTNODE" | cut -f 1 -d @)
					NODEADDR=$(echo "$BOOTNODE" | cut -f 2 -d @)
					BOOTNODE="$NODEADDR.$NODENAME"
				;;
			esac
	done

	case ${BOOTMEDIA} in
		emmc | sd)
			BOOTDEVICE="/dev/mmcblk"
			;;
		usb | scsi)
			BOOTDEVICE="/dev/sd"
			;;
	esac

	DEV="$(ls ${BOOTDEVICE}*${block_num})"
	for x in $(echo "$DEV"); do
		udevadm info --query=path --name=${x} | grep -q "$BOOTNODE"
		if [[ $? = 0 ]]; then
			block_name=${x}
			break
		fi
	done

	case ${BOOTMEDIA} in
		emmc | sd)
			device=${block_name%[a-zA-Z]*}
			;;
		usb | scsi)
			device=${block_name%[0-9]*}
			;;
	esac
}

if [[ -z $1 ]]; then
	block_name="/dev/block/by-name/userdata"
else
	block_name=$1
fi
device=$(udevadm info --query=path --name=${block_name})
block_num=${device##*[a-zA-Z]}
resolve_device

/usr/sbin/sgdisk -e ${device}
/usr/sbin/parted ${device} <<EOF
resizepart ${block_num} -34s
q
EOF
/sbin/mke2fs -t ext4 -b 4096 -O ^huge_file -m 0 -q -F ${block_name}
/sbin/e2fsck -fy ${block_name}
