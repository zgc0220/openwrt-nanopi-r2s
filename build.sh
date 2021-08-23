#!/bin/bash
#
# This is free software, license use GPLv3.
#
# Copyright (c) 2021, Chuck <fanck0605@qq.com>
#

set -eu

PROJ_DIR=$(pwd)
readonly PROJ_DIR

MAINTAIN=false

while getopts 'm' opt; do
	case $opt in
	m)
		MAINTAIN=true
		;;
	*)
		echo "usage: $0 [-m]"
		exit 1
		;;
	esac
done

readonly MAINTAIN

apply_patches() {
	ln -sf "$1" patches
	find patches/ -maxdepth 1 -name '*.patch' -printf '%f\n' | sort >patches/series
	quilt push -a
	$MAINTAIN &&
		while IFS= read -r patch; do
			quilt refresh -p ab --no-timestamps --no-index -f "$patch"
		done <patches/series
	return 0
}

fetch_clash_download_urls() {
	local -r CPU_ARCH=$1

	echo >&2 "Fetching Clash download urls..."
	local LATEST_VERSIONS
	readarray -t LATEST_VERSIONS < <(curl -sL https://github.com/vernesong/OpenClash/raw/master/core_version)
	readonly LATEST_VERSIONS

	echo https://github.com/vernesong/OpenClash/releases/download/Clash/clash-linux-"$CPU_ARCH".tar.gz
	echo https://github.com/vernesong/OpenClash/releases/download/TUN-Premium/clash-linux-"$CPU_ARCH"-"${LATEST_VERSIONS[1]}".gz
	echo https://github.com/vernesong/OpenClash/releases/download/TUN/clash-linux-"$CPU_ARCH".tar.gz

	return 0
}

download_clash_files() {
	local -r WORKING_DIR=$(pwd)/${1%/}
	local -r CLASH_HOME=$WORKING_DIR/etc/openclash
	local -r CPU_ARCH=$2

	local -r GEOIP_DOWNLOAD_URL=https://github.com/clashdev/geolite.clash.dev/raw/gh-pages/Country.mmdb

	local CLASH_DOWNLOAD_URLS
	readarray -t CLASH_DOWNLOAD_URLS < <(fetch_clash_download_urls "$CPU_ARCH")
	readonly CLASH_DOWNLOAD_URLS

	mkdir -p "$CLASH_HOME"
	echo "Downloading GeoIP database..."
	curl -sL "$GEOIP_DOWNLOAD_URL" >"$CLASH_HOME"/Country.mmdb

	mkdir -p "$CLASH_HOME"/core
	echo "Downloading Clash core..."
	curl -sL "${CLASH_DOWNLOAD_URLS[0]}" | tar -xOz >"$CLASH_HOME"/core/clash
	curl -sL "${CLASH_DOWNLOAD_URLS[1]}" | zcat >"$CLASH_HOME"/core/clash_tun
	curl -sL "${CLASH_DOWNLOAD_URLS[2]}" | tar -xOz >"$CLASH_HOME"/core/clash_game
	chmod +x "$CLASH_HOME"/core/clash{,_tun,_game}

	return 0
}

# clone openwrt
cd "$PROJ_DIR"
rm -rf openwrt
git clone -b v21.02.0-rc4 https://github.com/openwrt/openwrt.git openwrt

# patch openwrt
cd "$PROJ_DIR/openwrt"
apply_patches ../patches

# clone feeds
cd "$PROJ_DIR/openwrt"
./scripts/feeds update -a

# patch feeds
cd "$PROJ_DIR/openwrt"
awk '/^src-git/ { print $2 }' feeds.conf.default | while IFS= read -r feed; do
	if [ -d "$PROJ_DIR/patches/$feed" ]; then
		cd "$PROJ_DIR/openwrt/feeds/$feed"
		apply_patches ../../../patches/"$feed"
	fi
done

# add scripts
cd "$PROJ_DIR/openwrt"
mv ../scripts/check_smartdns_connect.sh package/base-files/files/etc
mv ../scripts/check_wan_connect.sh package/base-files/files/etc
chmod +x package/base-files/files/etc/check_smartdns_connect.sh
chmod +x package/base-files/files/etc/check_wan_connect.sh

# addition packages
cd "$PROJ_DIR/openwrt/package"
# luci-app-openclash
svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash custom/luci-app-openclash
CPU_MODEL=armv8
download_clash_files custom/luci-app-openclash/root ${CPU_MODEL}
echo '
config openclash 'config'
  option proxy_port '7892'
  option update '0'
  option auto_update '0'
  option auto_update_time '0'
  option cn_port '9090'
  option enable_redirect_dns '1'
  option dns_advanced_setting '1'
  option servers_if_update '0'
  option servers_update '0'
  option log_level 'silent'
  option lan_ac_mode '0'
  option config_path '/etc/openclash/config/config.yaml'
  option core_version 'linux-${CPU_MODEL}'
  option enable_rule_proxy '1'
  option intranet_allowed '1'
  option http_port '7890'
  option socks_port '7891'
  option enable_custom_dns '1'
  option disable_masq_cache '1'
  option enable_custom_clash_rules '0'
  option other_rule_auto_update '1'
  option other_rule_update_week_time '*'
  option other_rule_update_day_time '2'
  option geo_auto_update '1'
  option geo_update_week_time '*'
  option geo_update_day_time '3'
  option auto_restart '1'
  option auto_restart_week_time '*'
  option auto_restart_day_time '5'
  option dns_port '7874'
  option create_config '1'
  option redirect_dns '1'
  option masq_cache '1'
  option operation_mode 'redir-host'
  option en_mode 'redir-host'
  option dns_revert '0'
  option proxy_mode 'rule'
  option dashboard_password 'openwrt'
  option rule_sources 'ConnersHua'
  option rule_source '1'
  option GlobalTV 'GlobalTV'
  option AsianTV 'AsianTV'
  option Proxy 'Proxy'
  option Domestic 'Domestic'
  option Others 'Others'
  option china_ip_route '1'
  option mix_proxies '0'
	option ipv6_enable '0'
	option chnr_auto_update '1'
	option chnr_update_week_time '*'
	option chnr_update_day_time '4'
	option restricted_mode '0'
	option small_flash_memory '0'
	option enable_udp_proxy '0'
	option enable '1'
	option config_reload '1'
	option common_ports '1'
	option interface_name '0'
	option mixed_port '7893'
	option geo_custom_url 'https://cdn.jsdelivr.net/gh/alecthw/mmdb_china_ip_list@release/Country.mmdb'
	option chnr_custom_url 'https://cdn.jsdelivr.net/gh/Hackl0us/GeoIP2-CN@release/CN-ip-cidr.txt'
	option default_resolvfile '/tmp/resolv.conf.d/resolv.conf.auto'
	option firewall_forward_default 'REJECT'
	option tolerance '0'
	option log_size '1024'
	option custom_fallback_filter '0'
	option custom_domain_dns_server '127.0.0.1#6053'
	option disable_udp_quic '0'
	option core_type 'TUN'

config dns_servers
  option type 'udp'
  option ip '8.8.8.8'
  option group 'fallback'
  option enabled '0'

config dns_servers
  option type 'udp'
  option ip '8.8.4.4'
  option group 'fallback'
  option enabled '0'

config dns_servers
  option type 'udp'
  option ip '1.1.1.1'
  option group 'fallback'
  option enabled '0'

config dns_servers
  option ip '1.0.0.1'
  option type 'udp'
  option group 'fallback'
  option enabled '0'

config dns_servers
  option type 'udp'
  option ip '4.2.2.1'
  option enabled '0'
  option group 'fallback'

config dns_servers
  option type 'udp'
  option ip '4.2.2.2'
  option enabled '0'
  option group 'fallback'

config dns_servers
  option type 'udp'
  option ip '119.29.29.29'
  option enabled '0'

config dns_servers
  option type 'udp'
  option ip '119.28.28.28'
  option enabled '0'

config dns_servers
  option type 'udp'
  option ip '223.5.5.5'
  option enabled '0'

config dns_servers
  option type 'udp'
  option enabled '0'
  option ip '223.6.6.6'

config dns_servers
  option ip '8.8.8.8'
  option type 'tcp'
  option group 'fallback'
  option enabled '0'

config dns_servers
  option ip '8.8.4.4'
  option type 'tcp'
  option group 'fallback'
  option enabled '0'

config dns_servers
  option ip '1.1.1.1'
  option type 'tcp'
  option group 'fallback'
  option enabled '0'

config dns_servers
  option ip '1.0.0.1'
  option type 'tcp'
  option group 'fallback'
  option enabled '0'

config dns_servers
  option ip '4.2.2.1'
  option type 'tcp'
  option enabled '0'
  option group 'fallback'

config dns_servers
  option ip '4.2.2.2'
  option enabled '0'
  option type 'tcp'
  option group 'fallback'

config dns_servers
  option enabled '0'
  option ip '119.29.29.29'
  option type 'tcp'

config dns_servers
  option enabled '0'
  option ip '119.28.28.28'
  option type 'tcp'

config dns_servers
  option enabled '0'
  option ip '223.5.5.5'
  option type 'tcp'

config dns_servers
  option enabled '0'
  option ip '223.6.6.6'
  option type 'tcp'

config dns_servers
  option ip '8.8.8.8'
  option type 'tls'
	option port '853'
  option group 'fallback'
  option enabled '0'

config dns_servers
  option ip '8.8.4.4'
  option type 'tls'
	option port '853'
  option enabled '0'
  option group 'fallback'

config dns_servers
  option ip '1.1.1.1'
  option type 'tls'
	option port '853'
  option group 'fallback'
  option enabled '0'

config dns_servers
  option ip '1.0.0.1'
  option type 'tls'
	option port '853'
  option enabled '0'
  option group 'fallback'

config dns_servers
  option ip 'dns.pub'
	option port '853'
  option type 'tls'
  option enabled '0'

config dns_servers
  option enabled '0'
  option ip 'doh.pub'
	option port '853'
  option type 'tls'

config dns_servers
  option ip '223.5.5.5'
  option type 'tls'
	option port '853'
  option enabled '0'

config dns_servers
  option enabled '0'
  option ip '223.6.6.6'
	option port '853'
  option type 'tls'

config dns_servers
  option ip 'https://1.1.1.1/dns-query'
  option type 'https'
  option group 'fallback'
  option enabled '0'

config dns_servers
  option ip 'https://8.8.8.8/dns-query'
  option type 'https'
  option group 'fallback'
  option enabled '0'

config dns_servers
  option ip 'https://doh.pub/dns-query'
  option type 'https'
  option enabled '0'

config dns_servers
  option ip 'https://223.5.5.5/dns-query'
  option type 'https'
  option enabled '0'

config dns_servers
  option enabled '1'
  option group 'nameserver'
  option ip '127.0.0.1'
  option port '6053'
  option type 'tcp'

config dns_servers
  option enabled '1'
  option ip '127.0.0.1'
  option port '7053'
  option group 'fallback'
  option type 'tcp'
' >custom/luci-app-openclash/root/etc/config/openclash
# luci-app-smartdns
git clone --depth 1 https://github.com/pymumu/smartdns.git smartdns
echo '
config smartdns
  option server_name 'smartdns'
  option port '6053'
  option ipv6_server '0'
  option dualstack_ip_selection '0'
  option prefetch_domain '1'
  option serve_expired '1'
  option redirect 'none'
  option cache_size '20000'
  option rr_ttl '3600'
  option rr_ttl_min '5'
  option seconddns_port '7053'
  option seconddns_no_rule_addr '0'
  option seconddns_no_rule_nameserver '0'
  option seconddns_no_rule_ipset '0'
  option seconddns_no_rule_soa '0'
  option coredump '0'
  option enabled '1'
  option seconddns_enabled '1'
  option seconddns_no_dualstack_selection '1'
  option force_aaaa_soa '1'
  option seconddns_server_group 'foreign'
  option tcp_server '1'
  option seconddns_tcp_server '1'
  option seconddns_no_cache '1'
  option seconddns_no_speed_check '1'

config server
  option type 'udp'
  option ip '8.8.8.8'
  option server_group 'foreign'
  option blacklist_ip '0'
  option addition_arg '-exclude-default-group'
  option enabled '0'

config server
  option type 'udp'
  option ip '8.8.4.4'
  option server_group 'foreign'
  option blacklist_ip '0'
  option addition_arg '-exclude-default-group'
  option enabled '0'

config server
  option type 'udp'
  option ip '1.1.1.1'
  option server_group 'foreign'
  option blacklist_ip '0'
  option addition_arg '-exclude-default-group'
  option enabled '0'

config server
  option ip '1.0.0.1'
  option type 'udp'
  option server_group 'foreign'
  option blacklist_ip '0'
  option addition_arg '-exclude-default-group'
  option enabled '0'

config server
  option type 'udp'
  option ip '4.2.2.1'
  option enabled '0'
  option server_group 'foreign'
  option blacklist_ip '0'
  option addition_arg '-exclude-default-group'

config server
  option type 'udp'
  option ip '4.2.2.2'
  option enabled '0'
  option server_group 'foreign'
  option blacklist_ip '0'
  option addition_arg '-exclude-default-group'

config server
  option type 'udp'
  option ip '119.29.29.29'
  option enabled '0'

config server
  option type 'udp'
  option ip '119.28.28.28'
  option enabled '0'

config server
  option type 'udp'
  option ip '223.5.5.5'
  option enabled '0'

config server
  option type 'udp'
  option enabled '0'
  option ip '223.6.6.6'

config server
  option ip '8.8.8.8'
  option type 'tcp'
  option server_group 'foreign'
  option blacklist_ip '0'
  option addition_arg '-exclude-default-group'
  option enabled '0'

config server
  option ip '8.8.4.4'
  option type 'tcp'
  option blacklist_ip '0'
  option server_group 'foreign'
  option addition_arg '-exclude-default-group'
  option enabled '0'

config server
  option ip '1.1.1.1'
  option type 'tcp'
  option server_group 'foreign'
  option blacklist_ip '0'
  option addition_arg '-exclude-default-group'
  option enabled '0'

config server
  option ip '1.0.0.1'
  option type 'tcp'
  option server_group 'foreign'
  option blacklist_ip '0'
  option addition_arg '-exclude-default-group'
  option enabled '0'

config server
  option ip '4.2.2.1'
  option type 'tcp'
  option enabled '0'
  option server_group 'foreign'
  option blacklist_ip '0'
  option addition_arg '-exclude-default-group'

config server
  option ip '4.2.2.2'
  option enabled '0'
  option type 'tcp'
  option server_group 'foreign'
  option blacklist_ip '0'
  option addition_arg '-exclude-default-group'

config server
  option enabled '0'
  option ip '119.29.29.29'
  option type 'tcp'

config server
  option enabled '0'
  option ip '119.28.28.28'
  option type 'tcp'

config server
  option enabled '0'
  option ip '223.5.5.5'
  option type 'tcp'

config server
  option enabled '0'
  option ip '223.6.6.6'
  option type 'tcp'

config server
  option ip '8.8.8.8'
  option type 'tls'
  option no_check_certificate '0'
  option server_group 'foreign'
  option blacklist_ip '0'
  option host_name 'dns.google'
  option addition_arg '-exclude-default-group'
  option enabled '1'

config server
  option ip '8.8.4.4'
  option type 'tls'
  option enabled '0'
  option no_check_certificate '0'
  option server_group 'foreign'
  option blacklist_ip '0'
  option host_name 'dns.google'
  option addition_arg '-exclude-default-group'

config server
  option ip '1.1.1.1'
  option type 'tls'
  option no_check_certificate '0'
  option server_group 'foreign'
  option blacklist_ip '0'
  option host_name '1dot1dot1dot1.cloudflare-dns.com'
  option addition_arg '-exclude-default-group'
  option enabled '1'

config server
  option ip '1.0.0.1'
  option type 'tls'
  option enabled '0'
  option no_check_certificate '0'
  option server_group 'foreign'
  option blacklist_ip '0'
  option host_name '1dot1dot1dot1.cloudflare-dns.com'
  option addition_arg '-exclude-default-group'

config server
  option ip 'dns.pub'
  option type 'tls'
  option no_check_certificate '0'
  option enabled '1'

config server
  option enabled '0'
  option ip 'doh.pub'
  option type 'tls'
  option no_check_certificate '0'

config server
  option ip '223.5.5.5'
  option type 'tls'
  option no_check_certificate '0'
  option enabled '1'
  option host_name 'dns.alidns.com'

config server
  option enabled '0'
  option ip '223.6.6.6'
  option type 'tls'
  option no_check_certificate '0'
  option host_name 'dns.alidns.com'

config server
  option ip 'https://1.1.1.1/dns-query'
  option type 'https'
  option no_check_certificate '0'
  option server_group 'foreign'
  option blacklist_ip '0'
  option host_name '1dot1dot1dot1.cloudflare-dns.com'
  option http_host '1dot1dot1dot1.cloudflare-dns.com'
  option addition_arg '-exclude-default-group'
  option enabled '1'

config server
  option ip 'https://8.8.8.8/dns-query'
  option type 'https'
  option no_check_certificate '0'
  option server_group 'foreign'
  option blacklist_ip '0'
  option host_name 'dns.google'
  option http_host 'dns.google'
  option addition_arg '-exclude-default-group'
  option enabled '1'

config server
  option ip 'https://doh.pub/dns-query'
  option type 'https'
  option no_check_certificate '0'
  option enabled '1'

config server
  option ip 'https://223.5.5.5/dns-query'
  option type 'https'
  option no_check_certificate '0'
  option enabled '1'
  option host_name 'dns.alidns.com'
  option http_host 'dns.alidns.com'
' >smartdns/package/openwrt/files/etc/config/smartdns
echo '

speed-check-mode tcp:80,ping
' >>smartdns/package/openwrt/custom.conf
svn co https://github.com/immortalwrt/luci/branches/openwrt-21.02/applications/luci-app-smartdns custom/luci-app-smartdns
sed -i 's#../../luci.mk#$(TOPDIR)/feeds/luci/luci.mk#g' custom/luci-app-smartdns/Makefile
svn co https://github.com/immortalwrt/packages/branches/openwrt-21.02/net/smartdns custom/smartdns
cat smartdns/package/openwrt/files/etc/config/smartdns >custom/smartdns/conf/smartdns.conf
cat smartdns/package/openwrt/custom.conf >custom/smartdns/conf/custom.conf
rm -rf smartdns
# luci-app-freq
svn co https://github.com/immortalwrt/luci/branches/openwrt-21.02/applications/luci-app-cpufreq custom/luci-app-cpufreq
sed -i 's#../../luci.mk#$(TOPDIR)/feeds/luci/luci.mk#g' custom/luci-app-cpufreq/Makefile
sed -i "s/option governor ''/option governor 'schedutil'/g" custom/luci-app-cpufreq/root/etc/config/cpufreq
sed -i "s/option minfreq ''/option minfreq '816000'/g" custom/luci-app-cpufreq/root/etc/config/cpufreq
sed -i "s/option maxfreq ''/option maxfreq '1512000'/g" custom/luci-app-cpufreq/root/etc/config/cpufreq
# luci-app-zerotier
svn co https://github.com/immortalwrt/packages/branches/openwrt-21.02/net/zerotier custom/zerotier
svn co https://github.com/immortalwrt/luci/branches/openwrt-21.02/applications/luci-app-zerotier custom/luci-app-zerotier
sed -i 's#../../luci.mk#$(TOPDIR)/feeds/luci/luci.mk#g' custom/luci-app-zerotier/Makefile
# luci-app-arpbind
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-arpbind custom/luci-app-arpbind
# luci-app-oled
git clone --depth 1 https://github.com/NateLol/luci-app-oled.git custom/luci-app-oled
sed -i "s/option enable '0'/option enable '1'/g" custom/luci-app-oled/root/etc/config/oled
# luci-app-unblockmusic
svn co https://github.com/cnsilvan/luci-app-unblockneteasemusic/trunk/luci-app-unblockneteasemusic custom/luci-app-unblockneteasemusic
svn co https://github.com/cnsilvan/luci-app-unblockneteasemusic/trunk/UnblockNeteaseMusic custom/UnblockNeteaseMusic
# luci-app-autoreboot
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-autoreboot custom/luci-app-autoreboot
# luci-app-vsftpd
svn co https://github.com/immortalwrt/luci/branches/openwrt-21.02/applications/luci-app-vsftpd custom/luci-app-vsftpd
sed -i 's#../../luci.mk#$(TOPDIR)/feeds/luci/luci.mk#g' custom/luci-app-vsftpd/Makefile
svn co https://github.com/immortalwrt/packages/branches/openwrt-21.02/net/vsftpd-alt custom/vsftpd-alt
# luci-app-netdata
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-netdata custom/luci-app-netdata
# ddns-scripts
svn co https://github.com/immortalwrt/packages/branches/openwrt-21.02/net/ddns-scripts_aliyun custom/ddns-scripts_aliyun
svn co https://github.com/immortalwrt/packages/branches/openwrt-21.02/net/ddns-scripts_dnspod custom/ddns-scripts_dnspod
# luci-theme-argon
git clone -b master --depth 1 https://github.com/jerrykuku/luci-theme-argon.git custom/luci-theme-argon
# luci-app-argon-config
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config.git custom/luci-app-argon-config
# luci-app-frpc
svn co https://github.com/immortalwrt/luci/branches/openwrt-21.02/applications/luci-app-frpc custom/luci-app-frpc
sed -i 's#../../luci.mk#$(TOPDIR)/feeds/luci/luci.mk#g' custom/luci-app-frpc/Makefile
svn co https://github.com/immortalwrt/packages/branches/openwrt-21.02/net/frp custom/frp
sed -i 's#../../luci.mk#$(TOPDIR)/feeds/luci/luci.mk#g' custom/frp/Makefile
sed -i 's#../../lang/golang/golang-package.mk#$(TOPDIR)/feeds/packages/lang/golang/golang-package.mk#g' custom/frp/Makefile
# default-settings
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/default-settings custom/default-settings
echo '
#!/bin/sh

uci batch <<-EOF
    set luci.themes.Argon=/luci-static/argon
    set luci.main.mediaurlbase=/luci-static/argon
    commit luci
EOF

if [[ "$(cat /etc/crontabs/root | grep "/etc/check_wan_connect.sh")" = "" ]]; then echo "#*/5 * * * * /etc/check_wan_connect.sh" >> /etc/crontabs/root; fi
if [[ "$(cat /etc/crontabs/root | grep "/etc/check_smartdns_connect.sh")" = "" ]]; then echo "#*/5 * * * * /etc/check_smartdns_connect.sh" >> /etc/crontabs/root; fi

exit 0
' >custom/default-settings/files/zzz-default-settings

# clean up packages
cd "$PROJ_DIR/openwrt/package"
find . -name .svn -exec rm -rf {} +
find . -name .git -exec rm -rf {} +

# zh_cn to zh_Hans
cd "$PROJ_DIR/openwrt/package"
"$PROJ_DIR/scripts/convert_translation.sh"

# create acl files
cd "$PROJ_DIR/openwrt"
"$PROJ_DIR/scripts/create_acl_for_luci.sh" -a
"$PROJ_DIR/scripts/create_acl_for_luci.sh" -c

$MAINTAIN && exit 0

# install packages
cd "$PROJ_DIR/openwrt"
./scripts/feeds install -a

# customize configs
cd "$PROJ_DIR/openwrt"
cat "$PROJ_DIR/config.seed" >.config
make defconfig

# build openwrt
cd "$PROJ_DIR/openwrt"
make download -j8
make -j$(($(nproc) + 1)) || make -j1 V=s

# copy output files
cd "$PROJ_DIR"
cp -rf openwrt/bin/targets/*/* artifact
