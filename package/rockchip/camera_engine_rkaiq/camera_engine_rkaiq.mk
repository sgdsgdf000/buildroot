################################################################################
#
# Rockchip Camera Engine RKaiq For Linux
#
################################################################################

ifeq ($(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ), y)
CAMERA_ENGINE_RKAIQ_VERSION = 1.0
CAMERA_ENGINE_RKAIQ_SITE = $(TOPDIR)/../external/camera_engine_rkaiq
CAMERA_ENGINE_RKAIQ_SITE_METHOD = local
CAMERA_ENGINE_RKAIQ_INSTALL_STAGING = YES

CAMERA_ENGINE_RKAIQ_LICENSE = Apache V2.0
CAMERA_ENGINE_RKAIQ_LICENSE_FILES = NOTICE

CAMERA_ENGINE_RKAIQ_DEPENDENCIES =

CAMERA_ENGINE_RKAIQ_TARGET_INSTALL_DIR = $(TARGET_DIR)

CAMERA_ENGINE_RKAIQ_CONF_OPTS = -DBUILDROOT_BUILD_PROJECT=TRUE -DARCH=$(BR2_ARCH)

ifeq ($(BR2_PACKAGE_RK_OEM), y)
ifneq ($(BR2_PACKAGE_THUNDERBOOT), y)
ifneq ($(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_FORCE_INSTALL_TO_ROOTFS), y)
CAMERA_ENGINE_RKAIQ_INSTALL_TARGET_OPTS = DESTDIR=$(BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR) install/fast
CAMERA_ENGINE_RKAIQ_DEPENDENCIES += rk_oem
CAMERA_ENGINE_RKAIQ_TARGET_INSTALL_DIR = $(call qstrip,$(BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR))
endif
endif
endif

ifeq ($(BR2_PACKAGE_RV1126_RV1109),y)
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DISP_HW_VERSION=-DISP_HW_V20
else ifeq ($(BR2_PACKAGE_RK356X),y)
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DISP_HW_VERSION=-DISP_HW_V21
endif

ifeq ($(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_RKISP_DEMO), y)
CAMERA_ENGINE_RKAIQ_DEPENDENCIES += linux-rga
endif

ifeq ($(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE_USE_BIN), y)

RKISP_PARSER_HOST_BINARY = $(HOST_DIR)/bin/rkisp_parser

define conver_iqfiles
dir=`echo $(1)`; \
iqfile=`echo $(2)`; \
if [[ -z "$$iqfile" ]]; then \
	echo "## conver iqfiles"; \
	for i in $$dir/*.json; do \
		echo "### conver iqfiles: $$i"; \
		$(RKISP_PARSER_HOST_BINARY) $$i; \
	done; \
else  \
	echo "### conver iqfile: $$dir/$$iqfile"; \
	$(RKISP_PARSER_HOST_BINARY) $$dir/$$iqfile; \
fi;
endef

define INSTALL_RKISP_PARSER_M32_CMD
	$(INSTALL) -D -m  755 $(@D)/rkisp_parser_demo/bin/rkisp_parser_m32   $(HOST_DIR)/bin/rkisp_parser
endef

define INSTALL_RKISP_PARSER_M64_CMD
	$(INSTALL) -D -m  755 $(@D)/rkisp_parser_demo/bin/rkisp_parser_m64   $(HOST_DIR)/bin/rkisp_parser
endef

define IQFILE_CONVER_CMD
        $(foreach iqfile, $(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE)),
		$(call conver_iqfiles, $(@D)/iqfiles, $(iqfile))
        )
endef

define IQFILES_CONVER_CMD
	$(call conver_iqfiles, $(@D)/iqfiles)
endef

	ifeq ($(BR2_arm), y)
		CAMERA_ENGINE_RKAIQ_PRE_BUILD_HOOKS += INSTALL_RKISP_PARSER_M32_CMD
	else
		CAMERA_ENGINE_RKAIQ_PRE_BUILD_HOOKS += INSTALL_RKISP_PARSER_M64_CMD
	endif

	ifneq ($(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE)),)
		CAMERA_ENGINE_RKAIQ_PRE_BUILD_HOOKS += IQFILE_CONVER_CMD
	else
		CAMERA_ENGINE_RKAIQ_PRE_BUILD_HOOKS += IQFILES_CONVER_CMD
	endif
	CAMERA_ENGINE_RKAIQ_IQFILE = *.bin
else # BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE_USE_BIN
	ifneq ($(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE)),)
		CAMERA_ENGINE_RKAIQ_IQFILE = $(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE))
	else
		CAMERA_ENGINE_RKAIQ_IQFILE = */*.json
	endif
endif # BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE_USE_BIN

ifeq ($(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_RKISP_DEMO), y)
CAMERA_ENGINE_RKAIQ_CONF_OPTS += -DENABLE_RKISP_DEMO=ON
endif

define CAMERA_ENGINE_RKAIQ_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) DESTDIR=$(STAGING_DIR) $(MAKE) -C $($(PKG)_BUILDDIR) install
endef

define CAMERA_ENGINE_RKAIQ_INSTALL_CMDS
	mkdir -p $(CAMERA_ENGINE_RKAIQ_TARGET_INSTALL_DIR)/etc/iqfiles/
	mkdir -p $(CAMERA_ENGINE_RKAIQ_TARGET_INSTALL_DIR)/usr/lib/
	mkdir -p $(CAMERA_ENGINE_RKAIQ_TARGET_INSTALL_DIR)/usr/bin/
	$(TARGET_MAKE_ENV) DESTDIR=$(CAMERA_ENGINE_RKAIQ_TARGET_INSTALL_DIR) $(MAKE) -C $($(PKG)_BUILDDIR) install
	$(INSTALL) -D -m  644 $(@D)/all_lib/Release/librkaiq.so $(CAMERA_ENGINE_RKAIQ_TARGET_INSTALL_DIR)/usr/lib/
	$(foreach iqfile,$(CAMERA_ENGINE_RKAIQ_IQFILE),
		$(INSTALL) -D -m  644 $(@D)/iqfiles/$(iqfile) \
		$(CAMERA_ENGINE_RKAIQ_TARGET_INSTALL_DIR)/etc/iqfiles/
	)
endef

CAMERA_ENGINE_RKAIQ_POST_INSTALL_TARGET_HOOKS += CAMERA_ENGINE_RKAIQ_INSTALL_CMDS

ifeq ($(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE)),$(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_FAKE_CAMERA_IQFILE)))
		ifeq ($(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE_USE_BIN), y)
define INSTALL_FAKE_CAMERA_IQFILE_CMD
			ln -sf `echo ${BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE} | sed "s/xml/bin/g"` \
				$(CAMERA_ENGINE_RKAIQ_TARGET_INSTALL_DIR)/etc/iqfiles/FakeCamera.bin
endef
		else
define INSTALL_FAKE_CAMERA_IQFILE_CMD
			ln -sf $(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_IQFILE) \
				$(CAMERA_ENGINE_RKAIQ_TARGET_INSTALL_DIR)/etc/iqfiles/FakeCamera.xml
endef
		endif
	else
define INSTALL_FAKE_CAMERA_IQFILE_CMD
		$(INSTALL) -D -m  644 $(@D)/iqfiles/$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_FAKE_CAMERA_IQFILE) \
			$(CAMERA_ENGINE_RKAIQ_TARGET_INSTALL_DIR)/etc/iqfiles/FakeCamera.json
endef
	endif

ifneq ($(call qstrip,$(BR2_PACKAGE_CAMERA_ENGINE_RKAIQ_FAKE_CAMERA_IQFILE)),)
        CAMERA_ENGINE_RKAIQ_POST_INSTALL_TARGET_HOOKS += INSTALL_FAKE_CAMERA_IQFILE_CMD
endif

$(eval $(cmake-package))
$(eval $(host-generic-package))

endif
