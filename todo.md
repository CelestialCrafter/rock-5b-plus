# todo

setup mpd and doodle
setup games
encrypt and transfer irl files
add `inotifywait -mr --event create,delete,modify,move --f %w%0 --no-newline $PWD | xargs --null rclone rc vfs/forget dir=` to the `media` service to refresh vfs cache on fs change
nftables deny all eth0 inbound
set up disk encryption
set up crypttab with script to get secret from secrets store
move secrets from buildtime compilation to compilation at inittime with secrets injected from /proc/cmdline

## post-localmount checkpath

```
/home/<identifier> - 700 <identifier>:<identifier>
/var/lib/media - 777 media:media
/var/lib/media/public - 777 media:media
/var/lib/ssh - 700 root:root
/var/lib/ssh_host_<rsa,ed25519>_key - 600 root:root
```

## deployment

script to deploy builds to server
deployment rollbacks
