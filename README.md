# rock-5b-plus

alpine linux image for my radxa rock 5b+
this entire document is for future reference

## setup

<!-- @TODO document deployment scripts, and updated script syntax -->

1. populate `config/identifier` with the machine identifier (blupies, order: scarameow, blahaj, bootao, pupy, beebub):
1. modify `config/root/etc/fstab`, and populate it with the correct partition uuids
1. run `build.fish --mode u-boot --output u-boot.img`, and flash it onto a sd card
1. run `build.fish --mode extra --output <EXTRA_DIR>`
1. run `build.fish --mode root --output <ROOT_DIR>` as root
1. put EXTRA_DIR and ROOT_DIR the machine (inside the respective `/mnt-x` dirs from `config/root/etc/fstab`, boot the machine, and follow the post-install steps

## post-install

1. create `/home/<identifier>` with mode `700`, and `<identifier>:<identifier>` as the owner
1. create `/var/lib/media` and `/var/lib/media/public` with mode `777` and `media:media` as the owner
1. generate `ed25519` and `rsa` keys at `/var/lib/ssh/ssh_host_<type>_key`
1. run `tailscale login`

## extra

### what is extra?

extra is an externally mounted set of non-essential configs and packages.
on boot, the machine:

1. mounts extra
1. copies all configs from extra
1. installs all packages from extra's cache
1. unmounts extra
   this is all done in `config/root/init`

this exists for a few reasons:

- for some reason, the kernel panics if the initramfs cpio is too big
- having non-essential configs and packages in an external location allows for easier iteration and modification of services

### how do i use extra?

to add **packages**, add entries to the `cached` variable in the `build_extra` function.

> [!NOTE]
> to add sub-packages with an install-if clause (ex. tailscale-openrc), ALL packages in the install-if clause must be added to the cache (openrc and tailscale, in tailscale-openrc's case)

to add **configs**, add files to the `config/extra` directory, optionally editing the `build_extra` function if dynamic logic is neccesary

## u-boot

- these commands are to generate u-boot
- this is assuming alpine linux
- you may run prerequisites thru building in a container

### prerequisites

```sh
# https://docs.u-boot.org/en/latest/build/gcc.html#alpine-linux
apk add alpine-sdk bc bison dtc flex gnutls-dev linux-headers ncurses-dev \
openssl-dev py3-elftools py3-setuptools python3-dev swig util-linux-dev

git clone --depth=1 https://gitlab.collabora.com/hardware-enablement/rockchip-3588/rkbin.git
git clone --depth=1 https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot.git
```

### cross compilation

```sh
apk add gcc-aarch64-none-elf;\
alias aarch64-none-elf-gcc='gcc-aarch64-none-elf';
CROSS_COMPILE="aarch64-none-elf-";
```

### building

```sh
(cd rkbin && ./tools/boot_merger RKBOOT/RK3588MINIALL.ini)

ROCKCHIP_TPL=$(ls $PWD/rkbin/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v*.bin)
BL31=$(ls $PWD/rkbin/bin/rk35/rk3588_bl31_v*.elf)
(cd u-boot && \
  make rock5b-rk3588_defconfig
  make -j$(nproc))

mkdir artifacts
cp rkbin/rk3588_spl_loader_v*.bin artifacts/spl-loader.bin
cp rkbin/u-boot-rockchip-spi.bin artifacts/u-boot-spi.bin
```

### flashing

follow [step 3](https://docs.radxa.com/en/rock5/rock5b/low-level-dev/maskrom/linux#enter-to-maskrom)

```sh
apk add rkdeveloptool
rkdeveloptool ld # ensure step 3 worked
rkdeveloptool db artifacts/spl-loader.bin
rkdeveloptool wl 0 artifacts/u-boot-spi.bin
rkdeveloptool rd # reboot into u-boot
```
