# rock-5b-plus

alpine linux setup for my radxa rock 5b+

## setup

### part 1

1. download "ROCK 5B+ Debian" from https://docs.radxa.com/en/rock5/rock5b/download and flash it onto a sd card
1. put the sd card into the rock 5b+ and boot it
1. (5b+) on the boot drive, create partitions to match `config/root/etc/fstab`
1. (host) modify the UUIDs in `config/root/etc/fstab` according to the partition uuids in the previous step

### part 2

1. run `nix develop` on an `aarch64` or `x86_64` based host machine
1. run `just build <identifier>` (identifier order: scarameow, blahaj, bootao)
1. (5b+) extract build.tar.xz from the previous step into the ext4 partition
1. follow step 3 of https://docs.radxa.com/en/rock5/rock5b/low-level-dev/maskrom/linux#enter-to-maskrom
1. run `just flash`
1. after it boots, add the device to your tailnet

## extra

### what is extra?

extra is an externally mounted set of configs and packages.
on boot, the machine:

1. mounts extra
1. copies all configs from extra
1. installs all packages from extra's cache
1. unmounts extra

this exists because:

- for some reason, the kernel panics if the initramfs is too big
- having non-essential configs and packages in an external location allows for easier iteration and modification of services

### how do i use extra?

to add **packages**, add entries to the `cached` variable in the `extra` recipe.
to add **configs**, add files to the `config/extra` directory, optionally editing the `extra` reicpe if dynamic logic is neccesary
