# buttersync
simple script to transfer btrfs snapshots over a slow or unreliable connection

Function:
- creating btrfs snapshots with 'make-snapshot.sh'
- deleting old snapshots after reaching a set amount of snapshots
- transfer snapshot to a remote destination with 'push-snapshot.sh'
- broken transfer will be resumed by next run of 'push-snapshot.sh'
- show progress during transfer

Usage:
- copy files from repository to a place you want
- list folder you want to use in 'include.db
- point path in 'make-snapshot.sh' to your folde
- path in 'make-snapshot.sh' must be the same as source in 'push-snapshot.sh'
- target in 'push-snapshot.sh' must be pointing to your destination folder
- edit host and port in 'push-snapshot.sh'

Misc:
- requires btrfs on both machines
- use a high kernel
- tested with Debian Jessie kernel 4.6 conecting to Ubuntu 16.04 kernel 4.4
