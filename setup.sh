#!/bin/bash
configfile="/etc/buttersync.conf"
if [ ! -f $configfile ]
then
echo '
# you have to change this settings before use

## basic
source="/media/142cdfce-19b1-40be-8e80-947cc24b22be"
Bcount=30

## local copy 
Ltarget="/media/d99cf066-391d-46c1-98ea-f470037ef4bc/BACKUP_mehlbox"
Lcount=30

## remote copy
host="mehlbox@domain.com"
port="22"
Rtarget="/media/d99cf066-391d-46c1-98ea-f470037ef4bc/BACKUP_mehlbox"
Rcount=30



## optional settings
# snapname=$(TZ=GMT date +@GMT-%Y.%m.%d-%H.%M.%S)
# snappattern="@GMT-????.??.??-??.??.??"
# snapfolder=".snapshot"
'>$configfile
fi
