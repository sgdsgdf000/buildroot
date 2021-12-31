define FIREFLY_BRIDGE_NET_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/etc/init.d/
	$(INSTALL) -D -m 0755 package/firefly/firefly_bridge_net/src/S42bridge $(TARGET_DIR)/etc/init.d/

	mkdir -p $(TARGET_DIR)/etc/firefly_bridge/
	$(INSTALL) -D -m 0755 package/firefly/firefly_bridge_net/src/bridge_config $(TARGET_DIR)/etc/firefly_bridge/

	mkdir -p $(TARGET_DIR)/etc/dhcp/
	$(INSTALL) -D -m 0755 package/firefly/firefly_bridge_net/src/dhcpd.conf $(TARGET_DIR)/etc/dhcp/
endef

$(eval $(generic-package))
