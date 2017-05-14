#!/bin/bash
source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../settings

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root"
  exit 1
fi

#check if connection can be established
ssh $host -n -p$port
if [ $? != 0 ]; then
    exit 1
fi

while read loopfolder
do #for each folder

#check for empty line in include.db and skip it
  if [[ $loopfolder == [^[:space:]] ]]; then
    continue
  fi

#this file should be always be fresh
  if [ -f $source/$loopfolder/$snapfolder/.preprep_*~*.tmp ]; then
    rm -f $source/$loopfolder/$snapfolder/.preprep_*~*.tmp
  fi

#check if unfinished snapshot exist
if [ ! -f $source/$loopfolder/$snapfolder/.unfinished.inf ]; then

#determine names. Curent snapshot will be based on parent snapshot. Just the differences will be transferred
  ssh $host -n -p$port "ls -d1 $Rtarget/$loopfolder/\@GMT* &>/dev/null"
  if [ $? != 0 ]; then
    parent="initial"
    optionP=""
  else
    parent=$(ssh $host -n -p$port ls -1 $Rtarget/$loopfolder | tail -n 1)
    optionP="-p $source/$loopfolder/$snapfolder/$parent"
  fi #(from initial backup)
  curent=$(ls -1 $source/$loopfolder/$snapfolder | tail -n 1)

#check if different
  if [ $parent == $curent ]; then
    echo "$loopfolder: nothing to be transferred. Snapshot $curent seems to be the curent version"
    continue
  fi

#Start
#make file
    btrfs send $optionP $source/$loopfolder/$snapfolder/$curent -f $source/$loopfolder/$snapfolder/.preprep_$parent~$curent.tmp
    if [ $? == 0 ]; then
      mv $source/$loopfolder/$snapfolder/.preprep_$parent~$curent.tmp $source/$loopfolder/$snapfolder/.prep_$parent~$curent.tmp
    else
      rm $source/$loopfolder/$snapfolder/.preprep_*~*.tmp
      echo "$loopfolder: error during file creation."
      continue
    fi

#mark snapshot as unfinished
    echo $curent > $source/$loopfolder/$snapfolder/.unfinished.inf
    echo "$loopfolder: Snapshot $parent will be updated with $curent"

fi #(from check if unfinished snapshot exist)


# create folder if necessary
#if [ ! -d $Rtarget/$loopfolder ]; then  ## ssh inside if ????
    ssh $host -n -p$port sudo mkdir $Rtarget/$loopfolder 2>/dev/null
#fi

#transfer file with rsync
    echo "$loopfolder: File transfer: $(du -sh $source/$loopfolder/$snapfolder/.prep_*~*.tmp)"
    rsync -e "ssh -p$port" -P $source/$loopfolder/$snapfolder/.prep_*~*.tmp $host:$Rtarget/$loopfolder/
    if [ $? == 0 ]; then
      rm $source/$loopfolder/$snapfolder/.prep_*~*.tmp
    else
      echo "$loopfolder: error during rsync file transfer."
      continue
    fi

#create snapshot from file
    ssh $host -n -p$port sudo btrfs receive -f $Rtarget/$loopfolder/.prep_*~*.tmp $Rtarget/$loopfolder
    if [ $? == 0 ]; then
      ssh $host -n -p$port sudo rm $Rtarget/$loopfolder/.prep_*~*.tmp
    else
      echo "$loopfolder: error during snapshot creation."
      ssh $host -n -p$port sudo btrfs sub del $Rtarget/$loopfolder/$curent
      continue
    fi

#remove unfinished mark
    if [ $? == 0 ]; then
      rm $source/$loopfolder/$snapfolder/.unfinished.inf
    fi

done < $includefile # read includefile
