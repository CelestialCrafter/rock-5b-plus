#!/usr/bin/env fish

argparse 'r/reboot' 'i/identifier=' 'm/mode=' -- $argv
or return

set mode $_flag_mode
set id $_flag_identifier

ssh $id@homelab-$id "doas -n deploy $mode" < artifacts/$mode.tar.xz
echo "deployed to $id"

if set -q _flag_reboot
	ssh $id@homelab-$id "doas -n reboot"
	echo "rebooted $id"
end
