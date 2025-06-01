# rock-5b-plus

alpine linux image for my radxa rock 5b+ 

## setup

1. populate `rootfs/settings.json` with the following schema:
    ```
    {
    	"identifier": "machine id",
    	"wifi": {
    		"ssid": "wifi ssid",
    		"password": "wifi password"
    	}
    }
    ```
2. modify `rootfs/fstab`
3. run `build.sh` as root
4. run `rootfs/build.fish --mode extra --dir <EXTRA_DIR>`
3. once in the machine, make sure to `tailscale login`

## extra

### what is extra?

extra is an externally mounted set of non-essential configs and packages.
on boot, the machine:
1. mounts extra
2. copies all configs from extra
3. installs all packages from extra's cache
4. unmounts extra
this is all done in `rootfs/add-extra.initd`

this exists for a few reasons:
- for some reason, the kernel panics if the initramfs cpio is too big
- having non-essential configs and packages in an external location allows for easier iteration and modification of services

### how do i use extra?

extra is created by `rootfs/build.sh`.

to add **packages**, add entries to the `$cached` variable in the `extra_packages` function.
> [!NOTE]
> to add sub-packages with an install-if clause (ex. tailscale-openrc), ALL packages in the install-if clause must be added to the cache (openrc and tailscale, in tailscale-openrc's case)

to add **configs**, edit the `extra_config` function. optionally making use of the `rootfs/` directory to store larger, (mostly) static files.
