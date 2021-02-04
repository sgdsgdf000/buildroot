#!/bin/sh

EVENT=${1:-short-press}

logger -t $(basename $0) "[$$]: Received power key event: $@..."

TIMEOUT=3 # s
PIDFILE="/tmp/$(basename $0).pid"

power_key_led_blink()
{
    echo 0 > /sys/class/leds/firefly:blue:power/brightness
    echo 0 > /sys/class/leds/firefly:yellow:user/brightness
    sleep 1
    echo 1 > /sys/class/leds/firefly:blue:power/brightness
    echo 1 > /sys/class/leds/firefly:yellow:user/brightness
    sleep 1
    echo 0 > /sys/class/leds/firefly:blue:power/brightness
    echo 0 > /sys/class/leds/firefly:yellow:user/brightness
    sleep 1
    echo 1 > /sys/class/leds/firefly:blue:power/brightness
    echo 1 > /sys/class/leds/firefly:yellow:user/brightness
}

short_press()
{
	power_key_led_blink
}

long_press()
{
	logger -t $(basename $0) "[$$]: Power key long press (${TIMEOUT}s)..."

	logger -t $(basename $0) "[$$]: Prepare to power off..."

	poweroff
}

case "$EVENT" in
	press)
		start-stop-daemon -K -q -p $PIDFILE
		start-stop-daemon -S -q -b -m -p $PIDFILE -x /bin/sh -- \
			-c "sleep $TIMEOUT; $0 long-press"
		;;
	release)
		# Avoid race with press event
		sleep .2

		start-stop-daemon -K -q -p $PIDFILE && short_press
		;;
	short-press)
		short_press
		;;
	long-press)
		long_press
		;;
esac
