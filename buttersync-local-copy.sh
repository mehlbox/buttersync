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

# check for include file. Use basic setting if specific setting does not exist.
if [ -f "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../.buttersync-include-local" ]
then
	includefile="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../.buttersync-include-local"
else
	if [ -f "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../.buttersync-include" ]
	then
		includefile="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../.buttersync-include"
	else
		echo "include file not found"
		exit 1
	fi
fi
# if not defined in settings file
if [ -z $snapname ]; then snapname=$(TZ=GMT date +@GMT-%Y.%m.%d-%H.%M.%S); fi
if [ -z $snappattern ]; then snappattern="@GMT-????.??.??-??.??.??"; fi
if [ -z $snapfolder ]; then snapfolder=".snapshot"; fi

if [ -z $source ]; then echo "source must be defined in settings file"; exit 1; fi

# specific
if [ -z $Lcount ]; then echo "Lcount must be defined in settings file"; exit 1; fi








while read loopfolder
do #for each folder

#check for empty line in include.db and skip it
  if [[ $loopfolder == [^[:space:]] ]]; then
    continue
  fi

# check pid
if [ -f /tmp/buttersync-$loopfolder ]; then
    ps -p $(cat /tmp/buttersync-$loopfolder)&>/dev/null
    if [ $? == 0 ]; then
        echo "$loopfolder: Another process of buttersync is accessing this directory. Try again later"
        continue
    fi
fi
echo $$>/tmp/buttersync-$loopfolder

#check if unfinished snapshot exist
if [ -f $source/$loopfolder/$snapfolder/.buttersync-unfinished.mark ]; then
    echo "$loopfolder: found unfinished snapshot. Deleting..."
    btrfs sub del $Ltarget/$loopfolder/$(cat $source/$loopfolder/$snapfolder/.buttersync-unfinished.mark)
    rm -f $source/$loopfolder/$snapfolder/.buttersync-unfinished.mark
fi

#determine names. Curent snapshot will be based on parent snapshot. Just the differences will be transferred
  ls -d1 $Ltarget/$loopfolder/\@GMT* &>/dev/null
  if [ $? != 0 ]; then
    parent="initial"
    optionP=""
  else
    parent=$(ls -1 $Ltarget/$loopfolder | tail -n 1)
    optionP="-p $source/$loopfolder/$snapfolder/$parent"
  fi #(from initial backup)
  curent=$(ls -1 $source/$loopfolder/$snapfolder | tail -n 1)

#check if different
  if [ $parent == $curent ]; then
    echo "$loopfolder: nothing to be transferred. Snapshot $curent seems to be the curent version"
    continue
  fi

#Start

#mark snapshot as unfinished
    echo $curent > $source/$loopfolder/$snapfolder/.buttersync-unfinished.mark
    echo "$loopfolder: Snapshot $parent will be updated with $curent"

# create folder if necessary
if [ ! -d $Ltarget/$loopfolder ]; then
    mkdir $Ltarget/$loopfolder
fi

#create snapshot directly
    btrfs send $optionP $source/$loopfolder/$snapfolder/$curent | btrfs receive $Ltarget/$loopfolder/
    if [ $? == 0 ]; then
      echo "OK"
      rm $source/$loopfolder/$snapfolder/.buttersync-unfinished.mark
    else
      echo "$loopfolder: error during snapshot creation."
      btrfs sub del $Ltarget/$loopfolder/$curent
      rm $source/$loopfolder/$snapfolder/.buttersync-unfinished.mark
      continue
    fi

#delete old snapshot
if [ ! -z $Lcount ]
then
  ls -dr $Ltarget/$loopfolder/$snappattern | tail -n +$Lcount | while read snapshot ; do
  btrfs sub del $snapshot
  done
fi

#rm /tmp/buttersync-$loopfolder
done < $includefile # read includefile

