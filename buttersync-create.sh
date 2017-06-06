#!/bin/bash
while read loopfolder
do
# skip empty line
  if [ -z $loopfolder ]; then
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

# create folder
  if [ ! -d "$source/$loopfolder/$snapfolder" ]; then
    mkdir $source/$loopfolder/$snapfolder
  fi

#create snapshot
  btrfs sub snap -r $source/$loopfolder $source/$loopfolder/$snapfolder/$snapname

#delete old snapshot
if [ ! -z $Bcount ]
then
  ls -dr $source/$loopfolder/$snapfolder/$snappattern | tail -n +$Bcount | while read snapshot ; do
  btrfs sub del $snapshot
  done
fi
rm /tmp/buttersync-$loopfolder
done < $includefile

