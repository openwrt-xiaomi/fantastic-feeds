#
# Copyright (C) 2023 remittor
#

include $(TOPDIR)/rules.mk

PKG_NAME:=fantastic-feeds
PKG_VERSION:=2.4
PKG_RELEASE:=20250321

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
	$(INSTALL_DIR) $(1)/usr/share/fantastic_packages
	$(INSTALL_DATA) ./53ff2b6672243d28.pub $(1)/usr/share/fantastic_packages/53ff2b6672243d28.pub
	$(INSTALL_DATA) ./20241123170031.pub   $(1)/usr/share/fantastic_packages/20241123170031.pub
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
# check if we are on real system
[ -n "$${IPKG_INSTROOT}" ] && exit 0
FW_VER_FN="/etc/openwrt_release"
[ ! -f $$FW_VER_FN ] && { echo "File '/etc/openwrt_release' not found!"; exit 1; }
if [ -d /etc/apk/repositories.d/distfeeds.list ]; then
	KEYS_DIR=/etc/apk/keys
	CUSTFEEDS=/etc/apk/repositories.d/customfeeds.list
	cp -f /usr/share/fantastic_packages/20241123170031.pub $$KEYS_DIR/fantastic-packages-20241123170031.pem
else
	KEYS_DIR=/etc/opkg/keys
	CUSTFEEDS=/etc/opkg/customfeeds.conf
	cp -f /usr/share/fantastic_packages/53ff2b6672243d28.pub $$KEYS_DIR/53ff2b6672243d28
fi
FW_VERSION=$$( grep -o "^DISTRIB_RELEASE='.*" $$FW_VER_FN | cut -d"'" -f2 )
if [ "$$FW_VERSION" = "SNAPSHOT" ]; then
	#FW_REV=$$( grep -o "^DISTRIB_REVISION='.*" $$FW_VER_FN | cut -d"'" -f2 | cut -d"-" -f1 )
	#FW_BRANCH=$${FW_REV:1:5}
	# r10860-a3ffeb413b   19.07.0
	# r16122-c2139eef27   21.02-rc1
	# r19302-df622768da   22.03-rc1
	# r23069-e2701e0f33   23.05-rc1
	# r32308-9da8dfc1b9   24.10-snapshot
	#FANPKG_BRANCH="24.10"
	#[ "$$FW_BRANCH" -lt 32308 ] && FANPKG_BRANCH="23.05"
	#[ "$$FW_BRANCH" -lt 23069 ] && FANPKG_BRANCH="22.03"
	#[ "$$FW_BRANCH" -lt 19302 ] && FANPKG_BRANCH="21.02"
	FANPKG_BRANCH="SNAPSHOT"
else
	FW_VER=$$( echo "$$FW_VERSION" | cut -d"-" -f1 )
	FW_VER_MAJOR=$$( echo "$$FW_VER" | cut -d. -f1 )
	FW_VER_MINOR=$$( echo "$$FW_VER" | cut -d. -f2 )
	FANPKG_BRANCH="$$FW_VER_MAJOR.$$FW_VER_MINOR"
fi
FW_ARCH=$$( grep -o "^DISTRIB_ARCH='.*" $$FW_VER_FN | cut -d"'" -f2 )
if [ ! -f $$CUSTFEEDS ]; then
	echo "" > $$CUSTFEEDS
fi
if ! grep -q "fantastic-packages" $$CUSTFEEDS ; then
	BASE_URL="https://fantastic-packages.github.io/packages/releases"
	BASE_URL="$$BASE_URL/$$FANPKG_BRANCH/packages/$$FW_ARCH"
	echo "" >> $$CUSTFEEDS
	if [ -d /etc/apk/repositories.d/distfeeds.list ]; then
		echo "$$BASE_URL/luci/packages.adb"     >> $$CUSTFEEDS
		echo "$$BASE_URL/packages/packages.adb" >> $$CUSTFEEDS
		echo "$$BASE_URL/special/packages.adb"  >> $$CUSTFEEDS
	else
		echo "src/gz  fantastic_packages_luci      $$BASE_URL/luci"     >> $$CUSTFEEDS
		echo "src/gz  fantastic_packages_packages  $$BASE_URL/packages" >> $$CUSTFEEDS
		echo "src/gz  fantastic_packages_special   $$BASE_URL/special"  >> $$CUSTFEEDS
	fi
fi
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
# check if we are on real system
[ -n "$${IPKG_INSTROOT}" ] && exit 0
if [ -f /etc/opkg/customfeeds.conf ]; then
	sed -i "/fantastic_packages_/d" /etc/opkg/customfeeds.conf
fi
if [ -f /etc/apk/repositories.d/customfeeds.list ]; then
	sed -i "/fantastic-packages/d" /etc/apk/repositories.d/customfeeds.list
fi
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
