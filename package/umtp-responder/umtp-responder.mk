UMTP_RESPONDER_VERSION = origin/master
UMTP_RESPONDER_SITE = https://github.com/viveris/uMTP-Responder.git
UMTP_RESPONDER_SITE_METHOD = git

UMTP_RESPONDER_DEPENDENCIES = 
UMTP_RESPONDER_LICENSE = GPL-3.0
UMTP_RESPONDER_LICENSE_FILES = LICENSE

#CFLAGS="$(TARGET_CFLAGS) -fPIC -I. -Dlinux"
UMTP_RESPONDER_CPPFLAGS = \
	$(TARGET_CPPFLAGS) \
	-DUSE_SYSLOG=1 \
	-DDEBUG=1 \
	-I$(@D)/inc

#UMTP_RESPONDER_MAKE_OPTS = USE_SYSLOG=1 DEBUG=1

define UMTP_RESPONDER_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
	$(TARGET_CONFIGURE_OPTS) \
	CPPFLAGS="$(UMTP_RESPONDER_CPPFLAGS)"
endef

define UMTP_RESPONDER_INSTALL_TARGET_CONF
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/etc/umtprd
	mkdir -p $(TARGET_DIR)/home/user $(TARGET_DIR)/www
	$(INSTALL) -m 0755 $(@D)/conf/umtprd.conf $(TARGET_DIR)/etc/umtprd
	$(INSTALL) -m 0755 $(@D)/conf/umtprd-ffs.sh $(TARGET_DIR)/usr/bin
	$(INSTALL) -m 0755 $(@D)/umtprd $(TARGET_DIR)/usr/bin/umtprd
endef

UMTP_RESPONDER_POST_INSTALL_TARGET_HOOKS += \
	UMTP_RESPONDER_INSTALL_TARGET_CONF

$(eval $(generic-package))
