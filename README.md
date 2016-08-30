# buttersync
simple script to transfer btrfs snapshots over a slow or unreliable connection

Function:

  make-snapshot.sh:
- creating btrfs snapshots
- deleting old snapshots after reaching a set amount of snapshots

  push-snapshot.sh:
- transfer snapshot to a remote destination
- broken transfer will be resumed by next run
- show progress during transfer

Usage:
- copy files from repository to a place you want
- list btrfs subvolumes you want to be used for snapshots in 'include.db'
- edit 'settings' file
- run 'make-snapshot.sh' to create snapshots localy
- run 'push-snapshot.sh' to transfer snapshot to remote host

Misc:
- requires btrfs on both machines
- use a high kernel
- tested with Debian Jessie kernel 4.6 conecting to Ubuntu 16.04 kernel 4.4
