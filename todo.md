# todo

- figure out artifact management (only dynamically include extra.img, probably can be done after network is initialized via openrc script)
- find out whats creating /setup/extra.img/env-vars
- flatten /setup/extra.img/extra into /setup/extra.img
- flatten /setup/extra.img/etc/apk/cache/<drv> to /setup/extra.img/extra/apk/cache
- flatten /setup/extra.img/etc/etc to /setup/extra.img/extra/etc
- figure out why /setup/extra.img/usr isn't populated

- find out whats creating /setup/root.img/env-vars

## ensure paths exist in /init

```
/home/<identifier> 700 <identifier>:<identifier>
/var/lib/media 777 media:media
/var/lib/media 777 media:media
/var/lib/ssh 700 root:root
/var/lib/ssh_host_<rsa,ed25519>_key 600 root:root
```
