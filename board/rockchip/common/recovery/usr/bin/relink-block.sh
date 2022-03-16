#!/bin/sh

cat /proc/cmdline |grep -q "storagenode"
if [[ $? != 0 ]]; then
	exit 1
fi

wait_for_file() {
	file="$1"
	timeout="$2"
	local count

	[ "$timeout" == "0" ] && return

	count=0
	while [ -z "$(ls $file)" ]; do
		sleep 1
		count=$((count + 1))
		[ "$count" == "$timeout" ] && break
	done
}

relink_block() {
	local BOOTMEDIA=""
	local BOOTDEVICE="/dev"
	local BOOTNODE=""
	local NODENAME=""
	local NODEADDR=""
	local device=""
	local block_name=""

	for x in $(cat /proc/cmdline); do
		case ${x} in
			storagemedia=*)
				BOOTMEDIA=$(echo ${x} | cut -f 2 -d =)
			;;
			storagenode=*)
				BOOTNODE=$(echo ${x} | awk -F '[/]' '{print $NF}')
				NODENAME=$(echo "$BOOTNODE" | cut -f 1 -d @)
				NODEADDR=$(echo "$BOOTNODE" | cut -f 2 -d @)
				BOOTNODE="$NODEADDR.$NODENAME"
			;;
		esac
	done

	case ${BOOTMEDIA} in
		emmc | sd)
			wait_for_file /dev/mmcblk* 10
			BOOTDEVICE=$(ls /dev/mmcblk[0-9])
			device="/dev/mmcblk"
			;;
		usb | scsi)
			wait_for_file /dev/sd* 10
			BOOTDEVICE=$(ls /dev/sd[a-z])
			device="/dev/sd"
			;;
	esac

	for x in $(echo "$BOOTDEVICE"); do
		udevadm info --query=path --name=${x} | grep -q "$BOOTNODE"
		if [[ $? = 0 ]]; then
			device=${x}
			break
		fi
	done

	for x in $(ls ${device}*); do
		block_name=$(udevadm info --name=${x} | grep "ID_PART_ENTRY_NAME" | cut -f 2 -d =)
		if [[ -n "$block_name" ]]; then
			ln -sf ${x} /dev/block/by-name/${block_name}
		fi
	done
}

relink_block

exit 0
