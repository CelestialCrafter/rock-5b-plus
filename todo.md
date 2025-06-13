# todo

setup mpd
set up disk encryption
set up crypttab with script to get secret from secrets store
move secrets from buildtime compilation to compilation at inittime with secrets injected from /proc/cmdline

## post-localmount checkpath

```
/home/scarameow - 700
/var/lib/media - 777
/var/lib/media/public - 777
/var/lib/ssh - 755
```

ssh-keygen rsa,ed25519 /var/lib/ssh_host_<type>_key

## deployment

nix builds
script to deploy builds to server
deployment rollbacks
