#!/bin/sh
#
# Start firefly-otg-upgrade for Linux...
#

case "$1" in
  start)
		/usr/bin/flock -xn /tmp/.firefly_check.lock -c /usr/local/bin/firefly-otg-upgrade.sh &

	;;
  stop)
		killall firefly-otg-upgrade
		printf "stop finished"
        ;;
  *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
exit 0
