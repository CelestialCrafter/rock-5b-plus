#!/usr/bin/env fish

function pack
	set -l file artifacts/{$mode}.tar.xz
	tar --xz -C $argv[1] -cf $file .
	echo "packed into $file"
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
	set -l file artifacts/u-boot.img
	fallocate -l 16M $file
	parted -s $file mklabel gpt
	dd if=sources/unpacked/u-boot.itb of=$file seek=16384 conv=notrunc
	echo "written into $file"
end

function build_root
	# base
	set -l id (cat config/identifier)
	set -l tmp (mktemp --directory)
	set -l rootfs $tmp/rootfs
	mkdir $rootfs

	make_rootfs $rootfs
	cp -r config/root/* $rootfs
	echo "ttyFIQ0::respawn:/sbin/getty -L 1500000 ttyFIQ0 vt100" >> $rootfs/etc/inittab
	echo "celestial-homelab-$id" > $rootfs/etc/hostname

	groupadd --prefix $rootfs deployers
	useradd --prefix $rootfs --shell /bin/sh \
		--user-group --groups wheel,deployers \
		--password \
		(mkpasswd -m sha512crypt $id) $id
	useradd --prefix $rootfs --shell /sbin/nologin \
		--user-group \
		--no-create-home --home-dir /var/lib/media media

	cp -r sources/unpacked/modules $rootfs/lib
	apk_base $rootfs --no-scripts add \
		alpine-base busybox-suid doas linux-firmware-rtw89 mdevd btrfs-progs

	# finalize
	mkdir $tmp/final

	cp sources/unpacked/rock-5b-plus.dtb $tmp/final
	cp sources/unpacked/fan-control.dtbo $tmp/final
	cp sources/unpacked/Image $tmp/final
	
	cd $tmp/rootfs
	find . \
		| cpio --create --format newc \
		| zstd > $tmp/alpine-initramfs.cpio.zst
	cd -

	mkimage \
		--architecture arm64 \
		--type ramdisk \
		--compression zstd \
		--image $tmp/alpine-initramfs.cpio.zst $tmp/final/uInitrd
	mkimage --architecture arm64 --type script --image config/boot.txt $tmp/final/boot.scr

	pack $tmp/final
	rm -rf $tmp
end

function build_extra
	# base
	set -l cached \
		openrc util-linux openssh-server tailscale rclone podman nftables git
	set -l tmp (mktemp --directory)

	mkdir $tmp/output
	cp -r config/extra/* $tmp/output

	make_rootfs $tmp
	mkdir $tmp/etc/apk/cache

	apk_base $tmp update
	apk_base $tmp --add-dependencies cache download $cached
	echo "$cached" > $tmp/etc/apk/cache/packages

	mv $tmp/etc/apk/cache $tmp/output
	pack $tmp/output
	rm -rf $tmp
end

set mode $argv[1]

switch $mode
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
