#!/usr/bin/env fish

function setting -a key
	jq -r $key config/settings.json
end

function apk_base
	apk --arch aarch64 --root $argv
end

function make_rootfs -a output
	cp -r sources/unpacked/alpine/* $output
	string replace --regex 'v[0-9]+\.[0-9]+' edge \
		(cat $output/etc/apk/repositories) > $output/etc/apk/repositories
end

function build_u_boot
	fallocate -l 125MB $output
	parted -s $output mklabel gpt
	dd if=sources/unpacked/u-boot.itb of=$output seek=16384 conv=notrunc
end

function build_root
	# base
	set -l id (setting .identifier)
	set -l tmp (mktemp --directory)
	set -l rootfs $tmp/rootfs
	mkdir $rootfs

	make_rootfs $rootfs
	cp -r config/root/* $rootfs
	echo "ttyFIQ0::respawn:/sbin/getty -L 1500000 ttyFIQ0 vt100" >> $rootfs/etc/inittab
	echo "celestial-homelab-$id" > $rootfs/etc/hostname

	useradd --prefix $rootfs --shell /bin/sh \
		--user-group --groups wheel \
		--password \
		(mkpasswd -m sha512crypt $id) $id
	useradd --prefix $rootfs --shell /sbin/nologin \
		--user-group \
		--no-create-home --home-dir /var/lib/media media

	cp -r sources/unpacked/modules $rootfs/lib
	apk_base $rootfs --no-scripts add \
		alpine-base busybox-suid doas linux-firmware-rtw89 mdevd btrfs-progs

	# finalize
	cp sources/unpacked/rock-5b-plus.dtb $output
	cp sources/unpacked/fan-control.dtbo $output
	cp sources/unpacked/Image $output
	
	cd $tmp/rootfs
	find . \
		| cpio --create --format newc \
		| zstd > $tmp/alpine-initramfs.cpio.zst
	cd -

	mkimage \
		--architecture arm64 \
		--type ramdisk \
		--compression zstd \
		--image $tmp/alpine-initramfs.cpio.zst $output/uInitrd
	mkimage --architecture arm64 --type script --image config/boot.txt $output/boot.scr

	rm -rf $tmp
end

function build_extra
	# base
	set -l cached \
		openrc util-linux openssh-server tailscale rclone podman nftables

	cp -r config/extra/* $output
	echo "password=\"$(setting .media_password)\"" > $output/etc/conf.d/media 

	set -l tmp (mktemp --directory)
	make_rootfs $tmp
	mkdir $tmp/etc/apk/cache

	apk_base $tmp update
	apk_base $tmp --add-dependencies cache download $cached

	mv $tmp/etc/apk/cache $output
	echo "$cached" > $output/cache/packages
	rm -rf $tmp
end

argparse 'm/mode=' 'o/output=' -- $argv
or return

set output (path resolve $_flag_output)
if test $_flag_mode != "u-boot"; and not test -e $output
	test -e $output; and echo hi
	echo "$output does not exist"
	exit 1
end

switch $_flag_mode
case "root"
	build_root
case "extra"
	build_extra
case "u-boot"
	build_u_boot
case '*'
	echo "mode flag is not one of \"extra\", \"root\", or \"u-boot\""
	exit 1
end
