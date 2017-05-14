#!/bin/bash
source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../settings

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root"
  exit 1
fi

while read loopfolder
do #for each folder

#check for empty line in include.db and skip it
  if [[ $loopfolder == [^[:space:]] ]]; then
    continue
  fi

#check if unfinished snapshot exist
if [ -f $source/$loopfolder/$snapfolder/.unfinished.inf ]; then
    echo "$loopfolder: found unfinished snapshot. Deleting..."
    btrfs sub del $Ltarget/$loopfolder/$(cat $source/$loopfolder/$snapfolder/.unfinished.inf)
    rm -f $source/$loopfolder/$snapfolder/.unfinished.inf
    continue
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
    echo $curent > $source/$loopfolder/$snapfolder/.unfinished.inf
    echo "$loopfolder: Snapshot $parent will be updated with $curent"

# create folder if necessary
if [ ! -d $Ltarget/$loopfolder ]; then
    mkdir $Ltarget/$loopfolder
fi

#create snapshot directly
    btrfs send $optionP $source/$loopfolder/$snapfolder/$curent | btrfs receive $Ltarget/$loopfolder/
    if [ $? == 0 ]; then
      echo "OK"
    else
      echo "$loopfolder: error during snapshot creation."
      btrfs sub del $Ltarget/$loopfolder/$curent
      continue
    fi

#remove unfinished mark
    if [ $? == 0 ]; then
      rm $source/$loopfolder/$snapfolder/.unfinished.inf
    fi

done < $includefile # read includefile

