#!/usr/bin/env just --justfile

apk_base := "apk --arch aarch64 --root"
extra_pkgs := "openrc mdevd busybox-suid doas util-linux \
openssh-server tailscale rclone podman nftables \
git inotify-tools jq"

set script-interpreter := ["sh", "-euo", "pipefail"]
set unstable

# utils

# internal - do not run manually
[script]
alpine output:
    mkdir -p sources
    mkdir -p {{output}}

    if [ ! -e sources/alpine.tar.gz ]; then
        base="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64"
        file=$(curl $base/latest-releases.yaml | \
            yq '.[] | select(.flavor == "alpine-minirootfs") | .file')
        curl -o sources/alpine.tar.gz $base/$file
    fi

    tar -xzf sources/alpine.tar.gz -C {{output}}
    sed -i 's/v[0-9]\+\.[0-9]\+/edge/' {{output}}/etc/apk/repositories

# internal - do not run manually
[script]
nix-build package:
    mkdir -p sources
    if [ ! -e sources/{{package}} ]; then
        nix build .#packages.aarch64-linux.{{package}} --out-link sources/{{package}}
    fi

# intermediates

# internal - do not run manually
[script]
extra output identifier:
    # setup
    mkdir -p {{output}}
    tmp=$(mktemp --directory)
    rootfs=$tmp/rootfs
    trap "rm -rf $tmp" EXIT

    # rootfs
    just alpine $rootfs
    mkdir $rootfs/etc/apk/cache

    {{apk_base}} $rootfs update
    {{apk_base}} $rootfs --add-dependencies cache download {{extra_pkgs}}
    echo "{{extra_pkgs}}" > $rootfs/etc/apk/cache/installed

    # outputs
    mv $rootfs/etc/apk/cache {{output}}/cache
    cp -r config/extra {{output}}/files
    echo "{{identifier}}" > {{output}}/files/identifier

# internal - do not run manually
[script]
root output:
    just nix-build linux

    # setup
    mkdir -p {{output}}
    tmp=$(mktemp --directory)
    trap "chmod -R 755 $tmp && rm -rf $tmp" EXIT

    # rootfs
    just alpine $rootfs
    {{apk_base}} $rootfs --no-scripts add zstd zmap
    cp -r config/root/* $rootfs
    cp -r sources/linux/lib/* $rootfs/lib

    useradd --prefix $rootfs --shell /bin/sh \
    	--user-group --groups wheel,deployers \
    	--password (mkpasswd -m sha512crypt $id) $id
    
    # outputs
    cp sources/linux/Image {{output}}
    cp sources/linux/dtbs/rockchip/rk3588-rock-5b-plus.dtb {{output}}/rock-5b-plus.dtb

    (cd $tmp && find . | cpio --create --format newc | zstd) > \
        $tmp/alpine-initramfs.cpio.zst

    mkimage \
        --architecture arm64 \
        --type ramdisk \
        --compression zstd \
        --image $tmp/alpine-initramfs.cpio.zst {{output}}/uInitrd

# outputs

# flashes the device, follow link in README.md before using this
[script]
flash:
    just nix-build u-boot
    just nix-build spl-loader

    if [ $(id -u) -ne 0 ]; then
        echo "effective user id is not 0, please run this as root!"
        exit 1
    fi

    rkdeveloptool db sources/spl-loader
    rkdeveloptool wl 0 sources/u-boot/u-boot-rockchip-spi.bin
    rkdeveloptool rd

# creates build.tar.xz in the cwd
[script]
[no-cd]
build identifier:
    tmp=$(mktemp --directory)
    trap "rm -rf $tmp" EXIT

    just extra $tmp/extra {{identifier}}
    just root $tmp/root

    mkimage --architecture arm64 --type script --image config/boot.txt $tmp/boot.scr

    tar --zstd -C $tmp -cf build.tar.zst
