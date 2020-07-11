#!/bin/bash

set -eu

# install dependencies
sudo -E apt-get update
sudo -E apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs gcc-multilib g++-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler antlr3 gperf swig
wget -O- https://raw.githubusercontent.com/friendlyarm/build-env-on-ubuntu-bionic/master/install.sh | bash
sudo -E apt-get -y autoremove --purge

git clone -b master https://github.com/coolsnowwolf/lede.git

# customize patches
pushd lede
git am -3 ../patches/*.patch
popd

# upgrade argon theme
pushd lede/package
rm -rf lean/luci-theme-argon
git clone --depth 1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git lean/luci-theme-argon
popd

# install filebrowser
pushd lede/package
svn co https://github.com/project-openwrt/openwrt/trunk/package/ctcgfw/filebrowser lean/filebrowser
svn co https://github.com/project-openwrt/openwrt/trunk/package/ctcgfw/luci-app-filebrowser lean/luci-app-filebrowser
popd

# install luci for 0.91 oled
pushd lede/package
git clone --depth 1 -b master https://github.com/NateLol/luci-app-oled.git lean/luci-app-oled
popd

# initialize feeds
p_list=$(ls -l patches | grep ^d | awk '{print $NF}')
pushd lede
./scripts/feeds update -a
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
pushd lede
./scripts/feeds install -a
popd

# customize configs
pushd lede
cat ../config.seed > .config
make defconfig
popd

# build openwrt
pushd lede
make download -j8
make -j$(nproc)
popd
