QUECTEL_CM_VERSION = master
QUECTEL_CM_SITE_METHOD = local
QUECTEL_CM_SITE = $(TOPDIR)/../external/quectel-cm

define QUECTEL_CM_BUILD_CMDS
    $(TARGET_MAKE_ENV) $(MAKE) -C $(@D) CC="$(TARGET_CC)"
endef

define QUECTEL_CM_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $($(PKG)_BUILDDIR)/S99_quectel-CM $(TARGET_DIR)/etc/init.d
	$(INSTALL) -m 0755 -D $($(PKG)_BUILDDIR)/quectel-CM $(TARGET_DIR)/usr/bin
	$(INSTALL) -m 0755 -D $($(PKG)_BUILDDIR)/default_quectel-CM.script $(TARGET_DIR)/usr/share/udhcpc/
endef

$(eval $(generic-package))

