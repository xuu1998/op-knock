include $(TOPDIR)/rules.mk

PKG_NAME:=fn-knock
PKG_VERSION:=1.7.0
PKG_RELEASE:=1

PKG_SOURCE:=fn-knock-turborepo.tar.gz
PKG_SOURCE_URL:=local
PKG_HASH:=skip

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/fn-knock
  SECTION:=net
  CATEGORY:=Network
  TITLE:=fn-knock gateway and management panel
  URL:=https://github.com/xuu1998/op-knock
  DEPENDS:=+node +redis
  MAINTAINER:=op-knock
endef

define Package/fn-knock/description
  fn-knock is a gateway and management panel for private service exposure.
  It provides reverse proxy, authentication, SSL certificates, DDNS management,
  IP whitelist, WAF firewall, and tunnel integration (Cloudflared/frp) in a
  single panel. Designed for NAS and home servers.
  
  Features:
    - Reverse proxy with authentication
    - SSL/ACME certificate management
    - DDNS provider integration
    - IP whitelist and WAF
    - Cloudflared and frp tunnel support
    - Web-based admin panel
endef

define Package/fn-knock/conffiles
/etc/config/fn-knock
/etc/fn-knock/config.toml
endef

define Build/Prepare
	$(call Build/Prepare/Default)
endef

define Build/Configure
endef

define Build/Compile
	cd $(PKG_BUILD_DIR) && \
	npm install && \
	npm run build
endef

define Package/fn-knock/install
	$(INSTALL_DIR) $(1)/usr/lib/fn-knock/server/server-admin
	$(INSTALL_DIR) $(1)/usr/lib/fn-knock/server-auth-view/dist
	$(INSTALL_DIR) $(1)/usr/lib/fn-knock/ui/www
	$(INSTALL_DIR) $(1)/usr/lib/fn-knock/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/fn-knock

	$(CP) $(PKG_BUILD_DIR)/apps/server-admin/dist/* $(1)/usr/lib/fn-knock/server/server-admin/
	$(CP) $(PKG_BUILD_DIR)/apps/server-auth-view/dist/* $(1)/usr/lib/fn-knock/server-auth-view/dist/
	$(CP) $(PKG_BUILD_DIR)/apps/server-admin-view/dist/* $(1)/usr/lib/fn-knock/ui/www/

	$(INSTALL_BIN) ./files/etc/init.d/fn-knock $(1)/etc/init.d/fn-knock
	$(INSTALL_CONF) ./files/etc/config/fn-knock $(1)/etc/config/fn-knock

	$(INSTALL_DATA) ./files/etc/fn-knock/config.toml $(1)/etc/fn-knock/config.toml
endef

$(eval $(call BuildPackage,fn-knock))
