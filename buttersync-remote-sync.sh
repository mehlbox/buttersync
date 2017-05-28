#!/bin/bash
source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../settings

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root"
  exit 1
fi

#check if connection can be established
ssh $host -n -p$port exit
if [ $? != 0 ]; then
    echo "No connection to host"
    exit 1
fi

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

#this file should be always be fresh
  if [ -a $source/$loopfolder/$snapfolder/.preprep_*~*.tmp ]; then
    echo "found some trash - deleting..."
    rm -f $source/$loopfolder/$snapfolder/.preprep_*~*.tmp
  fi

#check if unfinished prep file exist
if [ ! -f $source/$loopfolder/$snapfolder/.prep_*~*.tmp ]; then

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
    echo "$loopfolder: preparing file for transfer... Snapshot $parent will be updated with $curent"
    btrfs send $optionP $source/$loopfolder/$snapfolder/$curent -f $source/$loopfolder/$snapfolder/.preprep_$parent~$curent.tmp
    if [ $? == 0 ]; then
      mv $source/$loopfolder/$snapfolder/.preprep_$parent~$curent.tmp $source/$loopfolder/$snapfolder/.prep_$parent~$curent.tmp
    else
      rm $source/$loopfolder/$snapfolder/.preprep_*~*.tmp
      echo "$loopfolder: error during file creation."
      continue
    fi

else
    echo "resume previous transfer"
fi #(from check if unfinished snapshot exist)

# create folder if necessary
if (ssh $host -n -p$port '[ ! -d $Rtarget/$loopfolder ]') ;then
    ssh $host -n -p$port mkdir $Rtarget/$loopfolder
fi

#transfer file with rsync
    echo "$loopfolder: File transfer: $(du -sh $source/$loopfolder/$snapfolder/.prep_*~*.tmp)"
    rsync -e "ssh -p$port" -P $source/$loopfolder/$snapfolder/.prep_*~*.tmp $host:$Rtarget/$loopfolder/
    if [ $? != 0 ]; then
      echo "$loopfolder: error during rsync file transfer."
      continue
    fi

#create snapshot from file
#this area needs a remote unfinished check
    ssh $host -n -p$port btrfs receive -f $Rtarget/$loopfolder/.prep_*~*.tmp $Rtarget/$loopfolder
    if [ $? == 0 ]; then
      ssh $host -n -p$port rm $Rtarget/$loopfolder/.prep_*~*.tmp
      rm $source/$loopfolder/$snapfolder/.prep_*~*.tmp
    else
      echo "$loopfolder: error during snapshot creation."
      ssh $host -n -p$port btrfs sub del $Rtarget/$loopfolder/$curent
      continue
    fi

#delete old snapshot
  ssh $host -n -p$port ls -dr $Rtarget/$loopfolder/$snappattern | tail -n +$Rcount | while read snapshot ; do
  ssh $host -n -p$port btrfs sub del $snapshot
  done

rm /tmp/buttersync-$loopfolder
done < $Rincludefile # read includefile

