#!/bin/bash
source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/settings

while read loopfolder
do

# skip empty line
  if [ -z $loopfolder ]; then
    continue
  fi

# create folder
  if [ ! -d "$source/$loopfolder/$snapfolder" ]; then
    mkdir $source/$loopfolder/$snapfolder
  fi

#create snapshot
  btrfs sub snap -r $source/$loopfolder $source/$loopfolder/$snapfolder/$snapname

#delete old snapshot
  ls -dr $source/$loopfolder/$snapfolder/$snappattern | tail -n +$count | while read snapshot ; do
  btrfs sub del $snapshot
  done

done < $includefile

