#!/bin/sh

UPGRADE_DIR="firefly_upgrade"
EXEC_BIN="firefly_upgrade.sh"
BOARD_DIR="/var/cache/firefly"
BOOL_COPY_DIR="true"
UPGRADE_FW_NAME="update.img"
FIREFLY_MNT="/tmp/mnt"
DEBUG_CONSOLE="/dev/ttyFIQ0"
UPGRADE_FW_REBOOT_WAIT_MEDIA="true"

firefly_update_success=0

sleep 2

log() {
    local format="$1"
    shift
    #printf -- "$format\n" "$@" >&2
    printf -- "$format\n" "$@" > $DEBUG_CONSOLE
}


is_recovery() {
	current_os_mode=normal
	mount | grep "rootfs on / type rootfs"
	if [ $? = 0 ]; then
		hexdump -C /dev/block/by-name/misc | grep false > /dev/null
		if [ $? = 0 ]; then
			current_os_mode=recovery
		fi
	fi
}


is_recovery_factory_reset() {
	current_os_mode=normal
	mount | grep "rootfs on / type rootfs"
	if [ $? = 0 ]; then
		hexdump -C /dev/block/by-name/misc | grep wipe > /dev/null
		if [ $? = 0 ]; then
			current_os_mode=recovery
			log "Is recovery factory reset, so $0 exit"
			exit
		fi
	fi
}




run() {
	if [ "$1" = "-i" ]; then
		shift
		max_try_time=1
		log "[firefly-upgrade]: Running command with ignore error: %s" "$*"
	else
		max_try_time=3
		log "[firefly-upgrade]: Running command: %s" "$*"
	fi
	do_with_retry 1 "$@"
}

do_with_retry()
{
	local count=$1
	shift
	until "$@"; do
			((count--))
			((count==0)) && break
			# log "Failed, Try again"
			sleep 1
	done

	# if ((count==0)); then
	#         log "Failed, Reached Max Retry Times"
	#         return 1
	# else
	#         log "Success"
	# fi
}


yellow_light_on()
{
	echo 1 > /sys/class/leds/firefly\:yellow\:user/brightness
}

yellow_light_off()
{
	echo 0 > /sys/class/leds/firefly\:yellow\:user/brightness
}

flash_light_start()
{
	if [ "$BOOL_LED_BLINK" = "true" ] || [ "$BOOL_LED_BLINK" = "1" ]; then
		while true
		do
			yellow_light_on
			sleep 0.5
			yellow_light_off
			sleep 0.5
		done
	fi
}


flash_light_stop()
{
	if [ "$BOOL_LED_BLINK" = "true" ] || [ "$BOOL_LED_BLINK" = "1" ]; then
		kill -9 $PID_flash_light
		sleep 0.5
		yellow_light_on
	fi
}

trap_exit(){
	flash_light_stop
	yellow_light_off
	exit 0
}


wait_media_and_reboot(){
	local block_media=$1

	if [ "$UPGRADE_FW_REBOOT_WAIT_MEDIA" = "true" ] || [ "$UPGRADE_FW_REBOOT_WAIT_MEDIA" = "1" ]; then
		while true
		do
			if [ -b "$block_media" ];then
				log "Please remove U disk!!!, wait for reboot."
				sleep 1.5
			else
				reboot
			fi
		done
	else
		reboot
	fi
}

find_upgrade_point() {
	if [ "$BOOL_UPGRADE_FW_ENABLE" = "true" ] || [ "$BOOL_UPGRADE_FW_ENABLE" = "1" ]; then
		mmc_list=$(ls /dev/mmcblk[1-9])
		for local_mmc in $mmc_list; do
			ludevinfo=$(udevadm info $local_mmc)
			if echo $ludevinfo |grep -q storagemedia ; then
					run export emmc_point_name="$local_mmc"
			fi
		done
	fi
}

upgrade_fw() {
	if [ "$BOOL_UPGRADE_FW_ENABLE" = "true" ] || [ "$BOOL_UPGRADE_FW_ENABLE" = "1" ]; then
		if [ -f $BOARD_DIR/$UPGRADE_DIR/$UPGRADE_FW_NAME ]; then
			log "[firefly-upgrade]\tUpgrade firmware $BOARD_DIR/$UPGRADE_DIR/$UPGRADE_FW_NAME"
			log "---------------------- START ----------------------"
			#run export emmc_point_name="/dev/mmcblk0"
			if [ "$UPGRADE_FW_WITH_MISC_RECOVERY_IMG" = "true" || "$UPGRADE_FW_WITH_MISC_RECOVERY_IMG" = "1" ]; then
				log "\n\n\n-----------/usr/bin/rkupdate log_start-----------"
				run /usr/bin/rkupdate Version\ 1.0 NULL $BOARD_DIR/$UPGRADE_DIR/$UPGRADE_FW_NAME 1 > $DEBUG_CONSOLE
				log "\n\n\n-----------/usr/bin/rkupdate log_end-----------"
				firefly_update_success=1
			elif [ "$UPGRADE_FW_WITH_MISC_RECOVERY_IMG" = "false" || "$UPGRADE_FW_WITH_MISC_RECOVERY_IMG" = "0" ]; then
				run /usr/bin/rkupdate Version\ 1.0 NULL $BOARD_DIR/$UPGRADE_DIR/$UPGRADE_FW_NAME 0 > $DEBUG_CONSOLE
				firefly_update_success=1
			fi
			log "---------------------- END ----------------------"
			log "[firefly-upgrade]\tStop"
		else
			log "[firefly-upgrade]\tCan not find $BOARD_DIR/$UPGRADE_DIR/$UPGRADE_FW_NAME firmware"
		fi
	fi
}

upgrade_script() {
	if [ -f $BOARD_DIR/$UPGRADE_DIR/$UPGRADE_SCRIPT ]; then
		chmod +x $BOARD_DIR/$UPGRADE_DIR/$UPGRADE_SCRIPT

		# 防止多次插拔造成重复执行
		kill_num=$(ps -ef | grep $UPGRADE_SCRIPT | grep -v grep | awk -F ' ' '{print $2}')
		if [ -n "$kill_num" ]; then
			kill $kill_num
		fi

		# exec cmd
		cd $BOARD_DIR/$UPGRADE_DIR/

		log "[firefly-upgrade]\tStart executing $BOARD_DIR/$UPGRADE_DIR/$UPGRADE_SCRIPT"
		log "---------------------- START ----------------------"
		run $BOARD_DIR/$UPGRADE_DIR/$UPGRADE_SCRIPT
		log "---------------------- END ----------------------"
		log "[firefly-upgrade]\tStop"
	fi
}

update_tool()
{
	local mount_dir=$1

	if [ -d $mount_dir/$UPGRADE_DIR ]; then
		log "[$0] find $mount_dir/$UPGRADE_DIR on $dev"

		# Parse ff_upgrade_config.conf
		if [ -f $mount_dir/$UPGRADE_DIR/ff_upgrade_config.conf ]; then
			#source $BOARD_DIR/$UPGRADE_DIR/ff_upgrade_config.conf
			config=$(cat $mount_dir/$UPGRADE_DIR/ff_upgrade_config.conf| grep -v \#)
			for local_cmd in $config; do
				log "[firefly-upgrade]: Read $mount_dir/$UPGRADE_DIR/ff_upgrade_config.conf"
				run eval $local_cmd
			done
		fi

		# copy $BOARD_DIR to board
		if [ "$BOOL_COPY_DIR" = "true" ] || [ "$BOOL_COPY_DIR" = "1" ]; then
			if [ -d $BOARD_DIR ]; then
				rm $BOARD_DIR/ -fr
			fi

			yellow_light_on
			mkdir -p $BOARD_DIR

			run cp -rf $mount_dir/$UPGRADE_DIR $BOARD_DIR/
			run sync

			if [ $FIREFLY_MNT = $mount_dir ]; then
				umount $mount_dir
			fi
		else
			yellow_light_on
			# 用户自定义了路径，改写 BOARD_DIR
			BOARD_DIR=$mount_dir
		fi

		# Whether define UPGRADE_SCRIPT
		if [ -z "$UPGRADE_SCRIPT" ]; then
			UPGRADE_SCRIPT=$EXEC_BIN
		fi

		trap trap_exit SIGINT
		# 黄灯闪烁
		flash_light_start &
		PID_flash_light=$!


		if [ "$UPGRADE_SCRIPT_RUN_IN_OS_MODE" = "$current_os_mode" ]; then
			# 运行upgrade_script
			upgrade_script
		fi

		case ${UPGRADE_FW_RUN_IN_OS_MODE} in
			recovery)
					# 升级固件
					find_upgrade_point
					upgrade_fw
					;;
        esac

		# 释放trap，关闭黄灯
		trap SIGINT
		flash_light_stop
		yellow_light_on
		log "[$0] exit"
	fi
}

is_recovery_factory_reset
is_recovery


if [ ! -d $FIREFLY_MNT ]; then
	mkdir -p $FIREFLY_MNT
fi

for dev in `(ls /dev/sd[a-z][1-9])`; do
	mount | grep $dev > /dev/null
	if [ $? = 0 ]; then
		tmp=`mount | grep $dev| awk -F 'on' '{print $2}'|awk  '{print $1}' `
		update_tool $tmp
		continue
	fi

	if mount $dev $FIREFLY_MNT ; then
		update_tool $FIREFLY_MNT
		cd -
		sleep 1
		umount $FIREFLY_MNT
	fi

	if [ $firefly_update_success = 1 ]; then
		wait_media_and_reboot $dev
	fi
done


if [ $firefly_update_success = 1 ]; then
	wait_media_and_reboot $dev
fi





