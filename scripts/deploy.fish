#!/usr/bin/env fish

argparse 'r/reboot' 'i/identifier=' -- $argv
or return

set id $_flag_identifier

ssh $id@homelab-$id "doas -n deploy" < artifacts/main.tar.xz
echo "deployed to $id"

if set -q _flag_reboot
	ssh $id@homelab-$id "doas -n reboot"
	echo "rebooted $id"
end
