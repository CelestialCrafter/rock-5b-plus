# rock-5b-plus

alpine linux image for my radxa rock 5b+ 

## setup

<!-- @TODO document deployment scripts, and updated script syntax -->

1. populate `config/identifier` with the machine identifier (blupies, order: scarameow, blahaj, bootao, pupy, beebub):
2. modify `config/root/etc/fstab`, and populate it with the correct partition uuids
3. run `build.fish --mode u-boot --output u-boot.img`, and flash it onto a sd card
3. run `build.fish --mode extra --output <EXTRA_DIR>`
4. run `build.fish --mode root --output <ROOT_DIR>` as root
5. put EXTRA_DIR and ROOT_DIR the machine (inside the respective `/mnt-x` dirs from `config/root/etc/fstab`, boot the machine, and follow the post-install steps

## post-install

1. create `/home/<identifier>` with mode `700`, and `<identifier>:<identifier>` as the owner
2. create `/var/lib/media` and `/var/lib/media/public` with mode `777` and `media:media` as the owner
3. generate `ed25519` and `rsa` keys at `/var/lib/ssh/ssh_host_<type>_key`
4. run `tailscale login`

## extra

### what is extra?

extra is an externally mounted set of non-essential configs and packages.
on boot, the machine:
1. mounts extra
2. copies all configs from extra
3. installs all packages from extra's cache
4. unmounts extra
this is all done in `config/root/init`

this exists for a few reasons:
- for some reason, the kernel panics if the initramfs cpio is too big
- having non-essential configs and packages in an external location allows for easier iteration and modification of services

### how do i use extra?

to add **packages**, add entries to the `cached` variable in the `build_extra` function.
> [!NOTE]
> to add sub-packages with an install-if clause (ex. tailscale-openrc), ALL packages in the install-if clause must be added to the cache (openrc and tailscale, in tailscale-openrc's case)

to add **configs**, add files to the `config/extra` directory, optionally editing the `build_extra` function if dynamic logic is neccesary
