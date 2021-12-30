define IOT_CLIENT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 package/firefly/iot_client/iot_client $(TARGET_DIR)/usr/bin/
	mkdir -p $(TARGET_DIR)/usr/share/iot_client
	cp -rfp package/firefly/iot_client/config/* $(TARGET_DIR)/usr/share/iot_client
endef

$(eval $(generic-package))

