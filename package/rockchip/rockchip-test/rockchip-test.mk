# add test tool for rockchip platform

ROCKCHIP_TEST_VERSION = 20220212
ROCKCHIP_TEST_SITE_METHOD = local
ROCKCHIP_TEST_SITE = $(TOPDIR)/package/rockchip/rockchip-test/src
ROCKCHIP_TEST_LICENSE = Apache V2.0
ROCKCHIP_TEST_LICENSE_FILES = NOTICE

define ROCKCHIP_TEST_INSTALL_TARGET_CMDS
	cp -rf  $(@D)/rockchip-test  ${TARGET_DIR}/
	$(INSTALL) -D -m 0755 $(@D)/rockchip-test/auto_reboot/S99_auto_reboot $(TARGET_DIR)/etc/init.d/
endef

$(eval $(generic-package))