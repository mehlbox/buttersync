#!/bin/bash
path="/media/142cdfce-19b1-40be-8e80-947cc24b22be"
includefile="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/include.db"
snapfolder=".snapshot"
snapname=$(TZ=GMT date +@GMT-%Y.%m.%d-%H.%M.%S)
snappattern="@GMT-????.??.??-??.??.??"
count=90

while read loopfolder
do

# skip empty line
  if [ -z $loopfolder ]; then
    continue
  fi

# create folder
  if [ ! -d "$path/$loopfolder/$snapfolder" ]; then
    mkdir $path/$loopfolder/$snapfolder
  fi

#create snapshot
  btrfs sub snap -r $path/$loopfolder $path/$loopfolder/$snapfolder/$snapname

#delete old snapshot
  ls -dr $path/$loopfolder/$snapfolder/$snappattern | tail -n +$count | while read snapshot ; do
  btrfs sub del $snapshot
  done

done < $includefile

