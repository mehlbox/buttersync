#!/bin/bash
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root"
  exit 1
fi

if [ -f $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../settings ]; then
    source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../settings
else
    echo "cannot find settings file"
    exit 1
fi

if [ -z $source ];then
    echo "source must be defined in settings file"
    exit 1
fi

if [ -z $Bcount ];then
    echo "Bcount must be defined in settings file"
    exit 1
fi




while read loopfolder
do
# skip empty line
  if [ -z $loopfolder ]; then
    continue
  fi

# check
if [ -f /tmp/buttersync-$loopfolder ]; then
    echo "$loopfolder: Another process of buttersync is currently working with this directory. Try again later"
    exit 1
fi
touch /tmp/buttersync-$loopfolder

# create folder
  if [ ! -d "$source/$loopfolder/$snapfolder" ]; then
    mkdir $source/$loopfolder/$snapfolder
  fi

#create snapshot
  btrfs sub snap -r $source/$loopfolder $source/$loopfolder/$snapfolder/$snapname

#delete old snapshot
  ls -dr $source/$loopfolder/$snapfolder/$snappattern | tail -n +$Bcount | while read snapshot ; do
  btrfs sub del $snapshot
  done

rm /tmp/buttersync-$loopfolder
done < $Bincludefile

