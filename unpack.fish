#!/usr/bin/env fish

# vars
set alpine "https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/aarch64/alpine-minirootfs-3.22.0-aarch64.tar.gz"
set armbian "https://armbian.chi.auroradev.org/dl/rock-5b-plus/archive/Armbian_25.5.1_Rock-5b-plus_bookworm_edge_6.14.6_minimal.img.xz"

# setup
set tmp (mktemp --directory)
function cleanup; rm -rf $tmp; end
trap cleanup EXIT

mkdir -p sources/unpacked

# u-boot
dpkg-deb -x sources/u-boot.deb $tmp/u-boot
cp $tmp/u-boot/usr/lib/u-boot/rock-5b-plus/u-boot.itb sources/unpacked

# kernel
curl $armbian | xz --decompress > $tmp/armbian.img
scripts/extract.fish --image $tmp/armbian.img --offset 32768 --output $tmp --regex \
	'^(/boot/dtb-.*/rockchip/rk3588-rock-5b-plus.dtb)|(boot/vmlinuz-.*?)|(/usr/lib/modules)'

mv $tmp/usr/lib/modules sources/unpacked
mv $tmp/boot/dtb-*/rockchip/rk3588-radxa-rock-5b-plus.dtb sources/unpacked/rock-5b-plus.dtb
mv $tmp/boot/vmlinuz-* sources/unpacked/Image

# alpine
mkdir -p sources/unpacked/alpine
curl $alpine | tar -xz -C sources/unpacked/alpine
