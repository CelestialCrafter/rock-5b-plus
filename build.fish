#!/usr/bin/env fish

function pack -a dir
	set -l file artifacts/{$mode}.tar.xz
	tar --xz -C $dir -cf $file .
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

function build_root -a output
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

function build_extra -a output
	set -l cached \
		openrc util-linux openssh-server tailscale rclone podman nftables git inotify-tools jq
	set -l tmp (mktemp --directory)

	cp -r config/extra/* $output

	make_rootfs $tmp
	mkdir $tmp/etc/apk/cache
	apk_base $tmp update
	apk_base $tmp --add-dependencies cache download $cached
	echo "$cached" > $tmp/etc/apk/cache/packages

	mv $tmp/etc/apk/cache $output
	rm -rf $tmp
end

set mode $argv[1]

switch $mode
case "main"
	set -l output (mktemp --directory)
	mkdir $output/root
	mkdir $output/extra

	build_root $output/root
	mv $output/root/boot.scr $output
	build_extra $output/extra

	pack $output
case "u-boot"
	build_u_boot
case '*'
	echo "mode flag is not one of \"main\" or \"u-boot\""
	exit 1
end
