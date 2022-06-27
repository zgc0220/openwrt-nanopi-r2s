#!/bin/bash

set -eu

rm -rf openwrt
git clone https://github.com/coolsnowwolf/lede.git openwrt

# customize patches
pushd openwrt
git show -s --format=%h
git am -3 ../patches/*.patch
popd

# add scripts
pushd openwrt
mv ../scripts/check_smartdns_connect.sh package/base-files/files/etc
mv ../scripts/check_wan_connect.sh package/base-files/files/etc
chmod +x package/base-files/files/etc/check_smartdns_connect.sh
chmod +x package/base-files/files/etc/check_wan_connect.sh
sed -i '/exit 0/i\if [[ "$(cat /etc/crontabs/root | grep "/etc/check_smartdns_connect.sh")" = "" ]]; then echo "#*/5 * * * * /etc/check_smartdns_connect.sh" >> /etc/crontabs/root; fi' package/lean/default-settings/files/zzz-default-settings
sed -i '/exit 0/i\if [[ "$(cat /etc/crontabs/root | grep "/etc/check_wan_connect.sh")" = "" ]]; then echo "#*/5 * * * * /etc/check_wan_connect.sh" >> /etc/crontabs/root; fi' package/lean/default-settings/files/zzz-default-settings
# sed -i '/exit 0/i\if [[ "$(cat /etc/crontabs/root | grep "/usr/sbin/netspeed")" = "" ]]; then echo "0 * * * * kill -9 $(ps -ef | grep "/usr/sbin/netspeed" | grep -v grep | awk "{print $1}") 2>/dev/null" >> /etc/crontabs/root; fi' package/lean/default-settings/files/zzz-default-settings
popd

# addition packages
pushd openwrt/package
# luci-theme-argon
rm -rf lean/luci-theme-argon
git clone --depth 1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git lean/luci-theme-argon
sed -i '/uci commit luci/i\uci set luci.main.mediaurlbase="/luci-static/argon"' lean/default-settings/files/zzz-default-settings
# luci-app-argon-config
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config.git lean/luci-app-argon-config
# luci-app-filebrowser
svn co https://github.com/immortalwrt/luci/branches/openwrt-18.06/applications/luci-app-filebrowser lean/luci-app-filebrowser
sed -i "s/..\/..\/luci.mk/\$(TOPDIR)\/feeds\/luci\/luci.mk/g" lean/luci-app-filebrowser/Makefile
svn co https://github.com/immortalwrt/packages/branches/openwrt-18.06/utils/filebrowser lean/filebrowser
sed -i "s/..\/..\/lang\/golang\/golang-package.mk/\$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g" lean/filebrowser/Makefile
# luci-app-oled
git clone --depth 1 https://github.com/NateLol/luci-app-oled.git lean/luci-app-oled
sed -i "s/option enable '0'/option enable '1'/g" lean/luci-app-oled/root/etc/config/oled
# luci-app-openclash
git clone --depth 1 -b dev https://github.com/vernesong/OpenClash.git
CPU_MODEL=armv8
mv OpenClash/luci-app-openclash lean
echo '
config openclash 'config'
  option proxy_port '7892'
	option tproxy_port '7895'
	option mixed_port '7893'
	option socks_port '7891'
	option http_port '7890'
	option dns_port '7874'
	option update '0'
	option auto_update '0'
	option auto_update_time '0'
	option cn_port '9090'
	option dashboard_password 'openwrt'
	option ipv6_enable '0'
	option ipv6_dns '0'
	option core_version 'linux-${CPU_MODEL}'
	option release_branch 'dev'
	option en_mode 'redir-host'
	option servers_if_update '0'
	option servers_update '0'
	option log_level 'silent'
	option proxy_mode 'rule'
	option lan_ac_mode '0'
	option operation_mode 'redir-host'
	option redirect_dns '0'
	option small_flash_memory '0'
	option interface_name '0'
	option log_size '1024'
	option tolerance '0'
	option store_fakeip '1'
	option custom_fallback_filter '0'
	option append_wan_dns '0'
	option stream_domains_prefetch '0'
	option stream_auto_select '0'
	option geo_custom_url 'https://cdn.jsdelivr.net/gh/alecthw/mmdb_china_ip_list@release/lite/Country.mmdb'
	option chnr6_custom_url 'https://ispip.clang.cn/all_cn_ipv6.txt'
	option enable_udp_proxy '1'
	option disable_udp_quic '0'
	option enable_rule_proxy '1'
	option common_ports '1'
	option china_ip_route '1'
	option intranet_allowed '1'
	option enable_redirect_dns '0'
	option enable_custom_dns '1'
	option disable_masq_cache '1'
	option dns_advanced_setting '1'
	option custom_domain_dns_server '127.0.0.1#6053'
	option rule_source '1'
	option enable_custom_clash_rules '1'
	option other_rule_auto_update '1'
	option other_rule_update_week_time '*'
	option other_rule_update_day_time '2'
	option geo_auto_update '1'
	option geo_update_week_time '*'
	option geo_update_day_time '3'
	option chnr_auto_update '1'
	option chnr_update_week_time '*'
	option chnr_update_day_time '4'
	option chnr_custom_url 'https://fastly.jsdelivr.net/gh/Hackl0us/GeoIP2-CN@release/CN-ip-cidr.txt'
	option auto_restart '0'
	option auto_restart_week_time '1'
	option auto_restart_day_time '0'
	option config_path '/etc/openclash/config/config.yaml'
	option restricted_mode '0'
	option core_type 'Meta'
	option create_config '1'
	option rule_sources 'ConnersHua'
	option mix_proxies '0'
	option dns_remote '1'
	option bypass_gateway_compatible '0'
	option github_address_mod '0'
	option delay_start '0'
	option dnsmasq_cachesize '0'
	option cachesize_dns '1'
	option filter_aaaa_dns '0'
	option router_self_proxy '1'
	option enable_meta_core '1'
	option enable_meta_sniffer '1'
	option enable_meta_sniffer_custom '0'
	option enable_tcp_concurrent '1'
	option geodata_loader 'standard'
	option geosite_auto_update '1'
	option geosite_update_week_time '*'
	option geosite_update_day_time '6'
	option geosite_custom_url 'https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat'
	option enable_geoip_dat '1'
	option geoip_auto_update '1'
	option geoip_update_week_time '*'
	option geoip_update_day_time '5'
	option geoip_custom_url 'https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat'
	option dashboard_forward_ssl '0'
	option enable '1'
	option config_reload '1'

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
' >lean/luci-app-openclash/root/etc/config/openclash
mkdir -p base-files/files/etc/openclash/core
#curl -L https://github.com/vernesong/OpenClash/releases/download/TUN/clash-linux-${CPU_MODEL}.tar.gz | tar zxf -
#mv clash base-files/files/etc/openclash/core/clash_game
#chmod +x base-files/files/etc/openclash/core/clash_game
#curl -L https://github.com/vernesong/OpenClash/releases/download/Clash/clash-linux-${CPU_MODEL}.tar.gz | tar zxf -
#mv clash base-files/files/etc/openclash/core/clash
#chmod +x base-files/files/etc/openclash/core/clash
OPENCLASH_TUN_VERSION=$(sed -n '2p' OpenClash/core_version)
#curl -OL https://github.com/vernesong/OpenClash/releases/download/TUN-Premium/clash-linux-${CPU_MODEL}-${OPENCLASH_TUN_VERSION}.gz
#gzip -d OpenClash/core-lateset/premium/clash-linux-${CPU_MODEL}-${OPENCLASH_TUN_VERSION}.gz
#mv OpenClash/core-lateset/premium/clash-linux-${CPU_MODEL}-${OPENCLASH_TUN_VERSION} base-files/files/etc/openclash/core/clash_tun
#chmod +x base-files/files/etc/openclash/core/clash_tun
tar zxf OpenClash/core-lateset/meta/clash-linux-${CPU_MODEL}.tar.gz
mv clash base-files/files/etc/openclash/core/clash_meta
chmod +x base-files/files/etc/openclash/core/clash_meta
rm -rf OpenClash
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
  option enabled '1'

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
  option enabled '1'

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
  option enabled '1'
  option ip '119.29.29.29'
  option type 'tcp'

config server
  option enabled '0'
  option ip '119.28.28.28'
  option type 'tcp'

config server
  option enabled '1'
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
svn co https://github.com/immortalwrt/luci/branches/openwrt-18.06/applications/luci-app-smartdns lean/luci-app-smartdns
sed -i "s/..\/..\/luci.mk/\$(TOPDIR)\/feeds\/luci\/luci.mk/g" lean/luci-app-smartdns/Makefile
svn co https://github.com/immortalwrt/packages/branches/openwrt-18.06/net/smartdns lean/smartdns
cat smartdns/package/openwrt/files/etc/config/smartdns >lean/smartdns/conf/smartdns.conf
cat smartdns/package/openwrt/custom.conf >lean/smartdns/conf/custom.conf
rm -rf smartdns
#luci-app-freq
rm -rf lean/luci-app-cpufreq
svn co https://github.com/immortalwrt/luci/branches/openwrt-18.06/applications/luci-app-cpufreq lean/luci-app-cpufreq
sed -i "s/..\/..\/luci.mk/\$(TOPDIR)\/feeds\/luci\/luci.mk/g" lean/luci-app-cpufreq/Makefile
sed -i "s/option governor ''/option governor0 'schedutil'/g" lean/luci-app-cpufreq/root/etc/config/cpufreq
sed -i "s/option minfreq ''/option minfreq0 '816000'/g" lean/luci-app-cpufreq/root/etc/config/cpufreq
sed -i "s/option maxfreq ''/option maxfreq0 '1608000'/g" lean/luci-app-cpufreq/root/etc/config/cpufreq
# zerotier
svn co https://github.com/immortalwrt/packages/branches/openwrt-18.06/net/zerotier lean/zerotier
# luci-app-adguardhome
#svn co https://github.com/immortalwrt/luci/branches/openwrt-18.06-k5.4/applications/luci-app-adguardhome lean/luci-app-adguardhome
git clone --depth 1 -b beta https://github.com/rufengsuixing/luci-app-adguardhome.git lean/luci-app-adguardhome
#sed -i "s/..\/..\/luci.mk/\$(TOPDIR)\/feeds\/luci\/luci.mk/g" lean/luci-app-adguardhome/Makefile
sed -i "s/\$(TOPDIR)\/luci.mk/\$(TOPDIR)\/feeds\/luci\/luci.mk/g" lean/luci-app-adguardhome/Makefile
#sed -i "s/+PACKAGE_\$(PKG_NAME)_INCLUDE_binary:adguardhome//g" lean/luci-app-adguardhome/Makefile
#sed -i "s/PKG_CONFIG_DEPENDS:= CONFIG_PACKAGE_\$(PKG_NAME)_INCLUDE_binary//g" lean/luci-app-adguardhome/Makefile
#svn co https://github.com/immortalwrt/packages/branches/openwrt-18.06/net/adguardhome lean/adguardhome
#sed -i "s/..\/..\/lang\/golang\/golang-package.mk/\$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g" lean/adguardhome/Makefile
Arch="arm64"
latest_ver="$(curl https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest 2>/dev/null|grep -E 'tag_name' |grep -E 'v[0-9.]+' -o 2>/dev/null)"
curl -L https://github.com/AdguardTeam/AdGuardHome/releases/download/${latest_ver}/AdGuardHome_linux_${Arch}.tar.gz | tar zxf -
mkdir -p base-files/files/usr/bin
mv AdGuardHome/AdGuardHome base-files/files/usr/bin/AdGuardHome
rm -rf AdGuardHome
echo '
bind_host: 0.0.0.0
bind_port: 3000
beta_bind_port: 0
users:
- name: root
  password: $2y$10$56/.x0qHxLz4YfXJNuAphOuUb71kBo5eQ2AyreqrI3PZvfGJiU/gy
auth_attempts: 5
block_auth_min: 15
http_proxy: ""
language: ""
debug_pprof: false
web_session_ttl: 720
dns:
  bind_hosts:
  - 0.0.0.0
  port: 5553
  statistics_interval: 1
  querylog_enabled: false
  querylog_file_enabled: true
  querylog_interval: 24h
  querylog_size_memory: 1000
  anonymize_client_ip: false
  protection_enabled: true
  blocking_mode: nxdomain
  blocking_ipv4: ""
  blocking_ipv6: ""
  blocked_response_ttl: 10
  parental_block_host: family-block.dns.adguard.com
  safebrowsing_block_host: standard-block.dns.adguard.com
  ratelimit: 0
  ratelimit_whitelist: []
  refuse_any: false
  upstream_dns:
  - "#127.0.0.1:7874"
  - 127.0.0.1:6053
  - "#127.0.0.1:7053"
  upstream_dns_file: ""
  bootstrap_dns:
  - 119.29.29.29
  - 223.5.5.5
  all_servers: true
  fastest_addr: false
  fastest_timeout: 1s
  allowed_clients: []
  disallowed_clients: []
  blocked_hosts:
  - version.bind
  - id.server
  - hostname.bind
  trusted_proxies:
  - 127.0.0.0/8
  - ::1/128
  cache_size: 0
  cache_ttl_min: 0
  cache_ttl_max: 0
  cache_optimistic: true
  bogus_nxdomain: []
  aaaa_disabled: false
  enable_dnssec: false
  edns_client_subnet: false
  max_goroutines: 300
  ipset: []
  filtering_enabled: true
  filters_update_interval: 1
  parental_enabled: false
  safesearch_enabled: false
  safebrowsing_enabled: false
  safebrowsing_cache_size: 1048576
  safesearch_cache_size: 1048576
  parental_cache_size: 1048576
  cache_time: 30
  rewrites: []
  blocked_services: []
  upstream_timeout: 10s
  local_domain_name: lan
  resolve_clients: true
  use_private_ptr_resolvers: true
  local_ptr_upstreams: []
tls:
  enabled: false
  server_name: ""
  force_https: false
  port_https: 443
  port_dns_over_tls: 853
  port_dns_over_quic: 784
  port_dnscrypt: 0
  dnscrypt_config_file: ""
  allow_unencrypted_doh: false
  strict_sni_check: false
  certificate_chain: ""
  private_key: ""
  certificate_path: ""
  private_key_path: ""
filters:
- enabled: true
  url: https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt
  name: AdGuard Simplified Domain Names filter
  id: 1
- enabled: true
  url: https://adaway.org/hosts.txt
  name: AdAway
  id: 2
- enabled: false
  url: https://www.malwaredomainlist.com/hostslist/hosts.txt
  name: MalwareDomainList.com Hosts List
  id: 4
- enabled: false
  url: https://raw.githubusercontent.com/vokins/yhosts/master/data/tvbox.txt
  name: tvbox
  id: 1575018007
- enabled: false
  url: http://sbc.io/hosts/hosts
  name: StevenBlack host basic
  id: 1575618242
- enabled: false
  url: http://sbc.io/hosts/alternates/fakenews-gambling-porn-social/hosts
  name: StevenBlack host+fakenews + gambling + porn + social
  id: 1575618243
- enabled: true
  url: https://anti-ad.net/easylist.txt
  name: anti-AD
  id: 1577113202
- enabled: true
  url: https://raw.githubusercontent.com/o0HalfLife0o/list/master/ad.txt
  name: halflife
  id: 1636875676
- enabled: false
  url: https://raw.hellogithub.com/hosts
  name: GitHub520
  id: 1637220663
whitelist_filters: []
user_rules: []
dhcp:
  enabled: false
  interface_name: ""
  dhcpv4:
    gateway_ip: ""
    subnet_mask: ""
    range_start: ""
    range_end: ""
    lease_duration: 86400
    icmp_timeout_msec: 1000
    options: []
  dhcpv6:
    range_start: ""
    lease_duration: 86400
    ra_slaac_only: false
    ra_allow_slaac: false
clients: []
log_compress: false
log_localtime: false
log_max_backups: 0
log_max_size: 100
log_max_age: 3
log_file: ""
verbose: false
os:
  group: ""
  user: ""
  rlimit_nofile: 0
schema_version: 12
' >base-files/files/etc/AdGuardHome.yaml
popd

# initialize feeds
p_list=$(ls -l patches | grep ^d | awk '{print $NF}')
pushd openwrt
# clone feeds
./scripts/feeds update -a
# patching
pushd feeds
for p in $p_list ; do
  [ -d $p ] && {
    pushd $p
    git am -3 ../../../patches/$p/*.patch
    popd
  }
done
popd
popd

#install packages
pushd openwrt
./scripts/feeds install -a
popd

# customize configs
pushd openwrt
cat ../config.seed > .config
make defconfig
popd

# build openwrt
pushd openwrt
make download -j8
make -j$(($(nproc) + 1)) || make -j1 V=s
popd

# package output files
archive_tag=OpenWrt_$(date +%Y%m%d)_NanoPi-R2S
pushd openwrt/bin/targets/*/*
# repack openwrt*.img.gz
set +e
gunzip openwrt*.img.gz
set -e
gzip openwrt*.img
sha256sum -b $(ls -l | grep ^- | awk '{print $NF}' | grep -v sha256sums) >sha256sums
tar zcf $archive_tag.tar.gz $(ls -l | grep ^- | awk '{print $NF}')
popd
mv openwrt/bin/targets/*/*/$archive_tag.tar.gz .
