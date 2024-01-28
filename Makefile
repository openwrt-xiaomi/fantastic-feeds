#
# Copyright (C) 2023 remittor
#

include $(TOPDIR)/rules.mk

PKG_NAME:=fantastic-feeds
PKG_VERSION:=2
PKG_RELEASE:=0

PKG_MAINTAINER:=remittor <remittor@gmail.com>
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Installer for fantastic-packages feeds
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
Installer for fantastic-packages feeds
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/opkg/keys
	$(INSTALL_DATA) ./key.pub $(1)/etc/opkg/keys/53ff2b6672243d28
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
# check if we are on real system
[ -n "$${IPKG_INSTROOT}" ] && exit 0
FW_VER_FN="/etc/openwrt_release"
[ ! -f $$FW_VER_FN ] && { echo "File '/etc/openwrt_release' not found!"; exit 1; }
FW_VERSION=$$( grep -o "^DISTRIB_RELEASE='.*" $$FW_VER_FN | cut -d"'" -f2 )
if [ "$$FW_VERSION" = "SNAPSHOT" ]; then
	FW_REV=$$( grep -o "^DISTRIB_REVISION='.*" $$FW_VER_FN | cut -d"'" -f2 )
	FW_BRANCH=$${FW_REV:0:3}
	FANPKG_BRANCH="23.05"
	[ "$$FW_BRANCH" = "r21" ] && FANPKG_BRANCH="21.02"
	[ "$$FW_BRANCH" = "r22" ] && FANPKG_BRANCH="22.02"
	[ "$$FW_BRANCH" = "r23" ] && FANPKG_BRANCH="23.05"
	[ "$$FW_BRANCH" = "r24" ] && FANPKG_BRANCH="23.05"
else
	FW_VER_MAJOR=$$( echo "$$FW_VERSION" | cut -d. -f1 )
	FW_VER_MINOR=$$( echo "$$FW_VERSION" | cut -d. -f2 )
	FANPKG_BRANCH="$$FW_VER_MAJOR.$$FW_VER_MINOR"
fi
FW_ARCH=$$( grep -o "^DISTRIB_ARCH='.*" $$FW_VER_FN | cut -d"'" -f2 )
if [ ! -f /etc/opkg/customfeeds.conf ]; then
	echo "" > /etc/opkg/customfeeds.conf
fi
if [ $$( grep -c -F fantastic_packages_ /etc/opkg/customfeeds.conf ) = 0 ]; then
	BASE_URL="https://fantastic-packages.github.io/packages/releases"
	BASE_URL="$$BASE_URL/$$FANPKG_BRANCH/packages/$$FW_ARCH"
	echo "" >> /etc/opkg/customfeeds.conf
	echo "src/gz  fantastic_packages_luci      $$BASE_URL/luci"     >> /etc/opkg/customfeeds.conf
	echo "src/gz  fantastic_packages_packages  $$BASE_URL/packages" >> /etc/opkg/customfeeds.conf
fi
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
# check if we are on real system
[ -n "$${IPKG_INSTROOT}" ] && exit 0
sed -i "/fantastic_packages_/d" /etc/opkg/customfeeds.conf
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
