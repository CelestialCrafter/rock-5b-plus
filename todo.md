# todo

- setup mpd and doodle
- setup games
- nftables deny all eth0 inbound
- add swap memory

## post-localmount checkpath

```
/home/<identifier> 700 <identifier>:<identifier>
/var/lib/media 777 media:media
/var/lib/media/public 777 media:media
/var/lib/media/repos 755 <identifier>:<identifier>
/var/lib/ssh 700 root:root
/var/lib/ssh_host_<rsa,ed25519>_key 600 root:root
/var/lib/deployments 755 root:root
```

