################################################################################
#
# libmodbus
#
################################################################################

LIBMODBUS_VERSION = 3.1.10
LIBMODBUS_SOURCE = libmodbus-$(LIBMODBUS_VERSION).tar.gz
LIBMODBUS_SITE = https://github.com/stephane/libmodbus/releases/download/v$(LIBMODBUS_VERSION)
LIBMODBUS_LICENSE = LGPLv2.1+
LIBMODBUS_LICENSE_FILES = COPYING.LESSER
LIBMODBUS_INSTALL_STAGING = YES

$(eval $(autotools-package))
