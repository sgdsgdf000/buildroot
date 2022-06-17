#!/bin/sh

killall brcm_patchram_plus1

echo 0 > /sys/class/rfkill/rfkill0/state
sleep 2
echo 1 > /sys/class/rfkill/rfkill0/state
sleep 2

uart=$(basename /sys/firmware/devicetree/base/pinctrl/wireless-bluetooth/uart*-gpios | tr -cd "[0-9]")
uart="/dev/ttyS${uart}"		
fwname=$(/usr/bin/bt_fwname ${uart})

if [[ ${fwname} = "bcm43438a1.hcd" ]]; then
	ln -sf /vendor/etc/firmware/nvram_ap6212a.txt /vendor/etc/firmware/nvram.txt
elif [[ ${fwname} = "BCM4345C0.hcd" ]]; then
	ln -sf /vendor/etc/firmware/nvram_ap6255.txt /vendor/etc/firmware/nvram.txt
fi

brcm_patchram_plus1 --bd_addr_rand --enable_hci --no2bytes --use_baudrate_for_download  --tosleep  200000 --baudrate 1500000 --patchram  /system/etc/firmware/${fwname} $uart &
hciconfig hci0 up
