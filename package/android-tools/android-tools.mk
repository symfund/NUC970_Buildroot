################################################################################
#
# android-tools
#
################################################################################

ANDROID_TOOLS_SITE = https://launchpad.net/ubuntu/+archive/primary/+files
ANDROID_TOOLS_VERSION = 4.2.2+git20130218
ANDROID_TOOLS_SOURCE = android-tools_$(ANDROID_TOOLS_VERSION).orig.tar.xz
ANDROID_TOOLS_EXTRA_DOWNLOADS = android-tools_$(ANDROID_TOOLS_VERSION)-3ubuntu41.debian.tar.gz
HOST_ANDROID_TOOLS_EXTRA_DOWNLOADS = $(ANDROID_TOOLS_EXTRA_DOWNLOADS)
ANDROID_TOOLS_LICENSE = Apache-2.0
ANDROID_TOOLS_LICENSE_FILES = debian/copyright

# Extract the Debian tarball inside the sources
define ANDROID_TOOLS_DEBIAN_EXTRACT
	$(call suitable-extractor,$(notdir $(ANDROID_TOOLS_EXTRA_DOWNLOADS))) \
		$(DL_DIR)/$(notdir $(ANDROID_TOOLS_EXTRA_DOWNLOADS)) | \
		$(TAR) -C $(@D) $(TAR_OPTIONS) -
endef

HOST_ANDROID_TOOLS_POST_EXTRACT_HOOKS += ANDROID_TOOLS_DEBIAN_EXTRACT
ANDROID_TOOLS_POST_EXTRACT_HOOKS += ANDROID_TOOLS_DEBIAN_EXTRACT

# Apply the Debian patches before applying the Buildroot patches
define ANDROID_TOOLS_DEBIAN_PATCH
	$(APPLY_PATCHES) $(@D) $(@D)/debian/patches \*
endef

HOST_ANDROID_TOOLS_PRE_PATCH_HOOKS += ANDROID_TOOLS_DEBIAN_PATCH
ANDROID_TOOLS_PRE_PATCH_HOOKS += ANDROID_TOOLS_DEBIAN_PATCH

ifeq ($(BR2_PACKAGE_HOST_ANDROID_TOOLS_FASTBOOT),y)
HOST_ANDROID_TOOLS_TARGETS += fastboot
HOST_ANDROID_TOOLS_DEPENDENCIES += host-zlib host-libselinux
endif

ifeq ($(BR2_PACKAGE_HOST_ANDROID_TOOLS_ADB),y)
HOST_ANDROID_TOOLS_TARGETS += adb
HOST_ANDROID_TOOLS_DEPENDENCIES += host-zlib host-openssl
endif

ifeq ($(BR2_PACKAGE_ANDROID_TOOLS_FASTBOOT),y)
ANDROID_TOOLS_TARGETS += fastboot
ANDROID_TOOLS_DEPENDENCIES += zlib libselinux
endif

ifeq ($(BR2_PACKAGE_ANDROID_TOOLS_ADB),y)
ANDROID_TOOLS_TARGETS += adb
ANDROID_TOOLS_DEPENDENCIES += zlib openssl
endif

ifeq ($(BR2_PACKAGE_ANDROID_TOOLS_ADBD),y)
ANDROID_TOOLS_TARGETS += adbd
ANDROID_TOOLS_DEPENDENCIES += zlib openssl
endif

# Build each tool in its own directory not to share object files

define HOST_ANDROID_TOOLS_BUILD_CMDS
	$(foreach t,$(HOST_ANDROID_TOOLS_TARGETS),\
		mkdir -p $(@D)/build-$(t) && \
		$(HOST_MAKE_ENV) $(HOST_CONFIGURE_OPTS) $(MAKE) SRCDIR=$(@D) \
			-C $(@D)/build-$(t) -f $(@D)/debian/makefiles/$(t).mk$(sep))
endef

define ANDROID_TOOLS_BUILD_CMDS
	$(foreach t,$(ANDROID_TOOLS_TARGETS),\
		mkdir -p $(@D)/build-$(t) && \
		$(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $(MAKE) SRCDIR=$(@D) \
			-C $(@D)/build-$(t) -f $(@D)/debian/makefiles/$(t).mk$(sep))
endef

define HOST_ANDROID_TOOLS_INSTALL_CMDS
	$(foreach t,$(HOST_ANDROID_TOOLS_TARGETS),\
		$(INSTALL) -D -m 0755 $(@D)/build-$(t)/$(t) $(HOST_DIR)/usr/bin/$(t)$(sep))
endef

define ANDROID_TOOLS_INSTALL_TARGET_CMDS
	$(foreach t,$(ANDROID_TOOLS_TARGETS),\
		$(INSTALL) -D -m 0755 $(@D)/build-$(t)/$(t) $(TARGET_DIR)/usr/bin/$(t)$(sep))
endef

define ANDROID_TOOLS_INSTALL_INIT_SYSV
        $(INSTALL) -m 0755 -D $(ANDROID_TOOLS_PKGDIR)/S99adb+serial \
                $(TARGET_DIR)/etc/init.d/S99adb+serial
	$(INSTALL) -m 0755 -D $(ANDROID_TOOLS_PKGDIR)/adb \
                $(TARGET_DIR)/etc/init.d/adb
endef

$(eval $(host-generic-package))
$(eval $(generic-package))
