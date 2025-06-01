#!/usr/bin/env fish

function setting -a key
	jq -r $key rootfs/settings.json
end

function create
	install -D -m 644 $argv
end

function root_base
	cp -r sources/unpacked/alpine/* $dir
	cp -r sources/unpacked/modules $dir/lib
	install -m +x rootfs/init $dir
	apk --arch aarch64 --no-scripts --root $dir add \
		alpine-base busybox-suid doas linux-firmware-rtw89 mdevd
end

function root_config
	set -l id (setting .identifier)

	install -m 755 rootfs/add-extra.initd $etc/init.d/add-extra
	cp rootfs/fstab $etc/fstab
	mkdir $dir/mnt-extra

	echo "ttyFIQ0::respawn:/sbin/getty -L 1500000 ttyFIQ0 vt100" >> $etc/inittab
	echo "celestial-homelab-$id" > $etc/hostname
	echo "permit persist :wheel" > $etc/doas.conf
	echo "rc_logger=\"YES\"" >> $etc/rc.conf

	echo "$id:$(mkpasswd -m sha512crypt $id):::::::" >> $etc/shadow
	echo "$id:x:1000:1000::/home/$id:/bin/sh" >> $etc/passwd
	string replace --regex "(wheel:.*)" "\$1,$id" (cat $etc/group) > $etc/group
end

function extra_packages
	set -l cached util-linux openssh-server wpa_supplicant btrfs-progs tailscale openrc

	set -l tmp (mktemp --directory)
	cp -r sources/unpacked/alpine/* $tmp
	mkdir $tmp/etc/apk/cache

	apk --arch aarch64 --root $tmp update
	apk --arch aarch64 --root $tmp --add-dependencies cache download $cached

	mv $tmp/etc/apk/cache $dir
	rm -rf $tmp

	echo "$cached" > $dir/cache/packages
end

function extra_config
	create rootfs/motd $etc/motd
	create rootfs/sshd.conf $etc/ssh/sshd_config.d/custom.conf
	create rootfs/interfaces $etc/network/interfaces
	wpa_passphrase "$(setting .wifi.ssid)" "$(setting .wifi.password)" | \
		create /dev/stdin $etc/wpa_supplicant/wpa_supplicant.conf
end

argparse 'm/mode=' 'd/dir=' -- $argv
or return

set dir $_flag_dir
if not test -e $dir
	echo "$dir does not exist"
	exit 1
end

set etc $dir/etc
switch $_flag_mode
case root
	root_base
	root_config
case extra
	extra_packages
	extra_config
case '*'
	echo "mode flag is not one of \"extra\" or \"root\""
	exit 1
end
