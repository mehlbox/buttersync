# buttersync
simple script to transfer btrfs snapshots over a slow or unreliable connection

##Function:

make-snapshot.sh:
- creating btrfs snapshots
- deleting old snapshots after reaching a set amount of snapshots

push-snapshot.sh:
- transfer snapshot to a remote destination
- interrupted transfer will be resumed by next run
- show progress during transfer

##what's so special about this?
Usually you would use btrfs send and btrfs receive to transfer btrfs snapshots from one place to another unsing standart piping. You can even tunnel the btrfs pipe stream through ssh to any other machine in the world. The downside of using this is that btrfs can not handel an aborted snapshot creation.
This script will use btrfs send to create a temporary file instead of direct piping. The created file will be transfered to the destination using rsync. Rsync is able to resume the transfer if your connection breaks down. On the destination btrfs receive is used to create a snapshot from file. Option parent is used when possible to keep down the amount of traffic. You keep all the advantages of btrfs. 

##Usage:
- copy files from repository to a place you want
- list btrfs subvolumes you want to be used for snapshots in 'include.db'
- edit 'settings' file
- run 'make-snapshot.sh' to create snapshots localy
- run 'push-snapshot.sh' to transfer snapshot to remote host

##Misc:
- requires btrfs on both machines
- use a high kernel
- tested with Debian Jessie kernel 4.6 conecting to Ubuntu 16.04 kernel 4.4
