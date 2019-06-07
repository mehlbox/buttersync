#!/bin/bash
# general
if [ "$(id -u)" != "0" ]; then echo "This script must be run as root"; exit 1; fi

# check for setting file in the buttersync directory or in the directory above
if [ -f $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/settings ]; then
    source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/settings
else
    if [ -f $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../settings ]; then
        source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../settings
    else
        echo "cannot find settings file"
        exit 1
    fi
fi

# check for include file.
includefile=$( cd "$source" && pwd )/.buttersync-include
if [ ! -f "$includefile" ]
then
  echo "include file not found"
  exit 1
fi

# if not defined in settings file
if [ -z $snapname ]; then snapname=$(TZ=GMT date +@GMT-%Y.%m.%d-%H.%M.%S); fi
if [ -z $snappattern ]; then snappattern="@GMT-????.??.??-??.??.??"; fi
if [ -z $snapfolder ]; then snapfolder=".snapshot"; fi

if [ -z "$source" ]; then echo "source must be defined in settings file"; exit 1; fi

# specific
if [ -z $Rcount ]; then echo "Rcount must be defined in settings file"; exit 1; fi
if [ -z $host ]; then echo "host must be defined in settings file"; exit 1; fi

#check if connection can be established
ssh $host -n exit
if [ $? != 0 ]; then
    echo "No connection to host"
    exit 1
fi

while read "loopfolder"
do #for each folder

  #check for empty line in include.db and skip it
  if [[ "$loopfolder" == [^[:space:]] ]]; then
    continue
  fi

  # check pid
  if [ -f "/tmp/buttersync-$loopfolder" ]; then
    if ps -p $(cat "/tmp/buttersync-$loopfolder") &>/dev/null
    then
      echo "$loopfolder: Another process of buttersync is accessing this directory. Try again later"
      continue
    fi
  fi
  echo $$>"/tmp/buttersync-$loopfolder"

  #this file should be always be fresh
  if [ -a "$source/$loopfolder/$snapfolder/.buttersync-prepfile_*~*.tmp" ]; then
    echo "found some trash - deleting..."
    rm -f "$source/$loopfolder/$snapfolder/.buttersync-prepfile_*~*.tmp"
  fi

#check if unfinished snapshot on target exist
if ssh $host -n '[ -f "$Rtarget/$loopfolder/.buttersync-unfinished.mark" ]' ;then
echo $(ssh $host -n cat "$Rtarget/$loopfolder/.buttersync-unfinished.mark")
      echo "found unfinished snapshot. deleting..."
      ssh $host -n btrfs sub del "$Rtarget/$loopfolder/"$(ssh $host -n cat "$Rtarget/$loopfolder/.buttersync-unfinished.mark")
      ssh $host -n rm "$Rtarget/$loopfolder/.buttersync-unfinished.mark"
fi

#check if unfinished prep file exist
if [ ! -f "$source/$loopfolder/$snapfolder/.buttersync-syncfile_*~*.tmp" ]; then

#determine names. Curent snapshot will be based on parent snapshot. Just the differences will be transferred
  unset optionP
  unset parent
  if ssh $host -n "ls -d1 $Rtarget/$loopfolder/\@GMT* &>/dev/null"
  then
    parent=$(ssh $host -n ls -1 "$Rtarget/$loopfolder" | tail -n 1)
    optionP="$source/$loopfolder/$snapfolder/$parent"
  fi
  curent=$(ls -1 "$source/$loopfolder/$snapfolder" | tail -n 1)

  #check if folder exists in destination
  if ssh $host -n '[ -d  "$Ltarget/$loopfolder/$curent" ]'
  then
    echo "$loopfolder: nothing to be transferred. Snapshot $curent already exists"
    continue
  fi

#Start

#prepare file
  if [ -z "$optionP" ]
  then
    echo "$loopfolder: preparing file for transfer... Snapshot $curent will be initialy created"
    btrfs send -f "$source/$loopfolder/$snapfolder/.buttersync-prepfile_$parent~$curent.tmp" "$source/$loopfolder/$snapfolder/$curent"
  else
    echo "$loopfolder: preparing file for transfer... Snapshot $curent will be based on $parent"
    btrfs send -f "$source/$loopfolder/$snapfolder/.buttersync-prepfile_$parent~$curent.tmp" -p "$optionP" "$source/$loopfolder/$snapfolder/$curent"
  fi
    if [ $? == 0 ]; then
      mv "$source/$loopfolder/$snapfolder/.buttersync-prepfile_$parent~$curent.tmp" "$source/$loopfolder/$snapfolder/.buttersync-syncfile_$parent~$curent.tmp"
    else
      rm "$source/$loopfolder/$snapfolder/.buttersync-prepfile_*~*.tmp"
      echo "$loopfolder: error during file creation."
      continue
    fi

else
    echo "resume previous transfer"
fi #(from check if unfinished snapshot exist)

# create folder if necessary
if ssh $host -n '[ ! -d "$Rtarget/$loopfolder" ]' ;then
   ssh $host -n mkdir "$Rtarget/$loopfolder"
fi

#transfer file with rsync
    echo "$loopfolder: File transfer: $(du -sh $source/$loopfolder/$snapfolder/.buttersync-syncfile_*~*.tmp)"
    rsync -e "ssh " -P "$source/$loopfolder/$snapfolder/.buttersync-syncfile_*~*.tmp" "$host:$Rtarget/$loopfolder/"
    if [ $? != 0 ]; then
      echo "$loopfolder: error during rsync file transfer."
      continue
    fi

#create snapshot from file
    ssh $host -n "echo $curent > $Rtarget/$loopfolder/.buttersync-unfinished.mark"
    ssh $host -n btrfs receive -f "$Rtarget/$loopfolder/.buttersync-syncfile_*~*.tmp" "$Rtarget/$loopfolder"
    if [ $? == 0 ]; then
      ssh $host -n rm "$Rtarget/$loopfolder/.buttersync-unfinished.mark"
      ssh $host -n rm "$Rtarget/$loopfolder/.buttersync-syncfile_*~*.tmp"
      rm "$source/$loopfolder/$snapfolder/.buttersync-syncfile_*~*.tmp"
    else
      echo "$loopfolder: error during snapshot creation."
      ssh $host -n btrfs sub del "$Rtarget/$loopfolder/$curent"
      continue
    fi

#delete old snapshot
if [ ! -z $Rcount ]
then
  ssh $host -n ls -dr "$Rtarget/$loopfolder/$snappattern" | tail -n +$Rcount | while read "snapshot"
  do
    ssh $host -n btrfs sub del "$snapshot"
  done
fi

rm "/tmp/buttersync-$loopfolder"
done < "$includefile" # read includefile

