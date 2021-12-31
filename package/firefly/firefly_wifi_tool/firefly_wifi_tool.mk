define FIREFLY_WIFI_TOOL_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 package/firefly/firefly_wifi_tool/src/wpa_ap $(TARGET_DIR)/usr/bin/
	$(INSTALL) -D -m 0755 package/firefly/firefly_wifi_tool/src/wpa_sta $(TARGET_DIR)/usr/bin/

	mkdir -p $(TARGET_DIR)/etc/dhcp/
	$(INSTALL) -D -m 0755 package/firefly/firefly_wifi_tool/src/dhcpd.conf $(TARGET_DIR)/etc/dhcp/
endef

$(eval $(generic-package))
