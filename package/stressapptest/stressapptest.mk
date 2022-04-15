################################################################################
#
# stress app test
#
################################################################################
STRESSAPPTEST_SITE = https://github.com/stressapptest/stressapptest
STRESS_LICENSE = Apache-2.0
STRESS_LICENSE_FILES = COPYING
STRESSAPPTEST_VERSION = 6714c57d0d67f5a2a7a9987791af6729289bf64e
STRESSAPPTEST_SITE_METHOD = git

$(eval $(autotools-package))
