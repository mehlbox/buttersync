# buttersync
simple script to transfer btrfs snapshots over a slow or unreliable connection

## Function:

buttersync-create.sh:
- create btrfs snapshots
- delete old snapshots after reaching a set amount of snapshots

buttersync-local-copy.sh:
- copy snapshot to a local hard drive
- interrupted copy will be deleted by next run
- delete old snapshots after reaching a set amount of snapshots

buttersync-remote-sync.sh:
- transfer snapshot to a remote destination
- interrupted transfer will be resumed by next run
- show progress during transfer
- delete old snapshots after reaching a set amount of snapshots

## what's so special about this?
Usually you would use btrfs send and btrfs receive to transfer btrfs snapshots from one place to another using standard piping. You can even tunnel the btrfs pipe stream through ssh to any other machine in the world. The downside of using this is that btrfs cannot handle an aborted snapshot creation.
This script will use btrfs send to create a temporary file instead of direct piping. The created file will be transferred to the destination using rsync. Rsync is able to resume the transfer if your connection breaks down. On the destination btrfs receive is used to create a snapshot from file. Option parent is used when possible to keep down the amount of traffic. You keep all the advantages of btrfs. 

## Usage:
- copy files from repository to a place you want
- create a '.buttersync-include' file in the directory your subvolumes are at and add the names of your subvolumes. Check the '.example' files to see how it is done.
- copy the 'settings.example' file to 'settings' and edit it to match your structure
- run 'buttersync-create.sh' to create a snapshots locally
- run 'buttersync-local-copy.sh' to copy the lates snapshot localy to another harddisk
- run 'buttersync-remote-sync.sh' to transfer the lates snapshot to a remote host

## Misc:
- requires btrfs on both machines
- no installation on remote machine
- Initial remote sync requires additional space on your harddrive to create a temporary file. This file will have the size of your subvolume.

## Windows previous versions
You can add the following lines to your smb.conf to make your snapshots visible in the previous versions tab of windows
```
[global]
vfs objects = btrfs shadow_copy2
shadow:format = @GMT-%Y.%m.%d-%H.%M.%S
shadow:sort = desc
shadow:snapdir = .snapshot
```
<img src="http://www.techsupportalert.com/files/images/pc_freeware/techtips/previous-versions-1.png">

## coming soon
- export import function for huge snapshots to make the initial transfer with a usb drive
- mark unfinished snapshots on target too
- buttersync as application
