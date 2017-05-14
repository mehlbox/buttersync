# buttersync
simple script to transfer btrfs snapshots over a slow or unreliable connection

## Function:

make-snapshot.sh:
- creating btrfs snapshots
- deleting old snapshots after reaching a set amount of snapshots

push-snapshot.sh:
- transfer snapshot to a remote destination
- interrupted transfer will be resumed by next run
- show progress during transfer

## what's so special about this?
Usually you would use btrfs send and btrfs receive to transfer btrfs snapshots from one place to another using standard piping. You can even tunnel the btrfs pipe stream through ssh to any other machine in the world. The downside of using this is that btrfs cannot handle an aborted snapshot creation.
This script will use btrfs send to create a temporary file instead of direct piping. The created file will be transferred to the destination using rsync. Rsync is able to resume the transfer if your connection breaks down. On the destination btrfs receive is used to create a snapshot from file. Option parent is used when possible to keep down the amount of traffic. You keep all the advantages of btrfs. 

## Usage:
- copy files from repository to a place you want
- copy example files to the folder above all other files
- rename files / remove >.example<  
- list btrfs subvolumes you want to be used for snapshots in 'include.db'
- edit 'settings' file
- run 'make-snapshot.sh' to create a snapshots locally
- run 'local-push-snapshot.sh' to transfer the lates snapshot to localy to another harddisk
- run 'remote-push-snapshot.sh' to transfer the lates snapshot to remote host # This file is not tested

## Misc:
- requires btrfs on both machines
- use a high kernel
- target snapshot will be deleted if an error occurs
<<<<<<< HEAD

## Windows previous versions
You can add the following lines to your smb.conf to make your snapshots visible in the previous versions tab of windows
'''
[global]
vfs objects = btrfs shadow_copy2
shadow:format = @GMT-%Y.%m.%d-%H.%M.%S
shadow:sort = desc
shadow:snapdir = .snapshot
'''
=======
>>>>>>> ae5d9aba0db528192bd2c91cf5e08c7eae6498b6
