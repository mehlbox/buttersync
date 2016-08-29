# buttersync
use rsync for transmitting btrfs snapshots over a slow or unreliable connection

Function:
- creating btrfs snapshots with 'make-snapshot.sh'
- deleting snapshots after reaching a set amount of snapshots
- transfer snapshot to a remote destination with 'push-snapshot.sh'
- broken transfer will resumed by next run of 'push-snapshot.sh'
- progres during transfer 

Usage:
- copy all files to a place you want
- list folder you want to use in 'include.db'
- point path in 'make-snapshot.sh' to your folder
- path in 'make-snapshot.sh' must be the same as source in 'push-snapshot.sh'
- target in 'push-snapshot.sh' must be pointing to your destination folder
- edit host and port ind 'push-snapshot.sh'
 
Misc:
- requires btrfs on both machines
- use a high kernel
- tested with Debian Jessie with kernel 4.6 to Ubuntu ? with kernel 4.4
