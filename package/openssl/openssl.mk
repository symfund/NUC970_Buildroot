################################################################################
#
# openssl
#
################################################################################

OPENSSL_VERSION = 1.1.1q
OPENSSL_SITE = https://www.openssl.org/source/old/1.1.1
OPENSSL_LICENSE = OpenSSL or SSLeay
OPENSSL_LICENSE_FILES = LICENSE
OPENSSL_INSTALL_STAGING = YES
OPENSSL_DEPENDENCIES = zlib
HOST_OPENSSL_DEPENDENCIES = host-zlib
OPENSSL_TARGET_ARCH = $(if $(BR2_arm),linux-armv4,linux-generic32)
OPENSSL_CFLAGS = $(TARGET_CFLAGS)

# relocation truncated to fit: R_68K_GOT16O
ifeq ($(BR2_m68k_cf),y)
OPENSSL_CFLAGS += -mxgot
OPENSSL_CFLAGS += -DOPENSSL_SMALL_FOOTPRINT
endif

ifeq ($(BR2_USE_MMU),)
OPENSSL_CFLAGS += -DHAVE_FORK=0 -DOPENSSL_NO_MADVISE
endif

ifeq ($(BR2_PACKAGE_HAS_CRYPTODEV),y)
OPENSSL_DEPENDENCIES += cryptodev
endif

define HOST_OPENSSL_CONFIGURE_CMDS
	(cd $(@D); \
		$(HOST_CONFIGURE_OPTS) \
		./config \
		--prefix=$(HOST_DIR)/ \
		--openssldir=$(HOST_DIR)/etc/ssl \
		no-tests \
		no-fuzz-libfuzzer \
		shared \
		zlib-dynamic \
	)
	$(SED) "s#-O[0-9sg]#$(HOST_CFLAGS)#" $(@D)/Makefile
endef

define OPENSSL_CONFIGURE_CMDS
	(cd $(@D); \
		$(TARGET_CONFIGURE_ARGS) \
		$(TARGET_CONFIGURE_OPTS) \
		./Configure \
			$(OPENSSL_TARGET_ARCH) \
			--prefix=/usr \
			--openssldir=/etc/ssl \
			$(if $(BR2_TOOLCHAIN_HAS_LIBATOMIC),-latomic) \
			$(if $(BR2_TOOLCHAIN_HAS_THREADS),threads,no-threads) \
			$(if $(BR2_STATIC_LIBS),no-shared,shared) \
			$(if $(BR2_PACKAGE_HAS_CRYPTODEV),enable-devcryptoeng) \
			no-rc5 \
			enable-camellia \
			enable-mdc2 \
			no-tests \
			no-fuzz-libfuzzer \
			no-fuzz-afl \
			no-chacha \
			no-rc5 \
			no-rc2 \
			no-rc4 \
			no-md2 \
			no-md4 \
			no-mdc2 \
			no-blake2 \
			no-idea \
			no-seed \
			no-des \
			no-rmd160 \
			no-whirlpool \
			no-bf \
			no-ssl \
			no-ssl2 \
			no-ssl3 \
			no-weak-ssl-ciphers \
			no-psk \
			no-cast \
			no-unit-test no-crypto-mdebug-backtrace no-crypto-mdebug no-autoerrinit \
			no-dynamic-engine \
			no-comp \
			$(if $(BR2_TOOLCHAIN_USES_UCLIBC),no-async) \
			$(if $(BR2_STATIC_LIBS),zlib,zlib-dynamic) \
			$(if $(BR2_STATIC_LIBS),no-dso) \
	)
	$(SED) "s#-march=[-a-z0-9] ##" -e "s#-mcpu=[-a-z0-9] ##g" $(@D)/Makefile
	$(SED) "s#-O[0-9sg]#$(OPENSSL_CFLAGS)#" $(@D)/Makefile
	$(SED) "s# build_tests##" $(@D)/Makefile
endef

# libdl is not available in a static build, and this is not implied by no-dso
ifeq ($(BR2_STATIC_LIBS),y)
define OPENSSL_FIXUP_STATIC_MAKEFILE
	$(SED) 's#-ldl##g' $(@D)/Makefile
endef
OPENSSL_POST_CONFIGURE_HOOKS += OPENSSL_FIXUP_STATIC_MAKEFILE
endif

define HOST_OPENSSL_BUILD_CMDS
	$(HOST_MAKE_ENV) $(MAKE) -C $(@D)
endef

define OPENSSL_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)
endef

define OPENSSL_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) install
endef

define HOST_OPENSSL_INSTALL_CMDS
	$(HOST_MAKE_ENV) $(MAKE) -C $(@D) install
endef

define OPENSSL_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) DESTDIR=$(TARGET_DIR) install
	rm -rf $(TARGET_DIR)/usr/lib/ssl
	rm -f $(TARGET_DIR)/usr/bin/c_rehash
endef

# libdl has no business in a static build
ifeq ($(BR2_STATIC_LIBS),y)
define OPENSSL_FIXUP_STATIC_PKGCONFIG
	$(SED) 's#-ldl##' $(STAGING_DIR)/usr/lib/pkgconfig/libcrypto.pc
	$(SED) 's#-ldl##' $(STAGING_DIR)/usr/lib/pkgconfig/libssl.pc
	$(SED) 's#-ldl##' $(STAGING_DIR)/usr/lib/pkgconfig/openssl.pc
endef
OPENSSL_POST_INSTALL_STAGING_HOOKS += OPENSSL_FIXUP_STATIC_PKGCONFIG
endif

ifeq ($(BR2_PACKAGE_PERL),)
define OPENSSL_REMOVE_PERL_SCRIPTS
	$(RM) -f $(TARGET_DIR)/etc/ssl/misc/{CA.pl,tsget}
endef
OPENSSL_POST_INSTALL_TARGET_HOOKS += OPENSSL_REMOVE_PERL_SCRIPTS
endif

ifeq ($(BR2_PACKAGE_OPENSSL_BIN),)
define OPENSSL_REMOVE_BIN
	$(RM) -f $(TARGET_DIR)/usr/bin/openssl
	$(RM) -f $(TARGET_DIR)/etc/ssl/misc/{CA.*,c_*}
endef
OPENSSL_POST_INSTALL_TARGET_HOOKS += OPENSSL_REMOVE_BIN
endif

ifneq ($(BR2_PACKAGE_OPENSSL_ENGINES),y)
define OPENSSL_REMOVE_OPENSSL_ENGINES
	rm -rf $(TARGET_DIR)/usr/lib/engines-1.1
endef
OPENSSL_POST_INSTALL_TARGET_HOOKS += OPENSSL_REMOVE_OPENSSL_ENGINES
endif

$(eval $(generic-package))
$(eval $(host-generic-package))
