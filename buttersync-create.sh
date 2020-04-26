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
if [ -f "$( cd "$source" && pwd )/.buttersync-include" ]
then
  includefile="$( cd "$source" && pwd )/.buttersync-include"
else
  echo "include file not found"
  exit 1
fi

# if not defined in settings file
if [ -z $snapname ]; then snapname=$(TZ=GMT date +@GMT-%Y.%m.%d-%H.%M.%S); fi
if [ -z $snappattern ]; then snappattern="@GMT-????.??.??-??.??.??"; fi
if [ -z $snapfolder ]; then snapfolder=".snapshot"; fi

if [ -z "$source" ]; then echo "source must be defined in settings file"; exit 1; fi

# specific
if [ -z $Bcount ]; then echo "Bcount must be defined in settings file"; exit 1; fi

while read "loopfolder"
do #for each folder

  #check for empty line in include.db and skip it
  if [[ ! "$loopfolder" =~ [^[:space:]] ]]; then
    continue
  fi

  # check pid
  if [ -f "/tmp/buttersync-$loopfolder" ]; then
    ps -p $(cat "/tmp/buttersync-$loopfolder") &>/dev/null
    if [ $? == 0 ]; then
      echo "$loopfolder: Another process of buttersync is accessing this directory. Try again later"
      continue
    fi
  fi
  echo $$>"/tmp/buttersync-$loopfolder"

  # create folder
  if [ ! -d "$source/$loopfolder/$snapfolder" ]; then
    mkdir "$source/$loopfolder/$snapfolder"
  fi

  #create snapshot
  btrfs sub snap -r "$source/$loopfolder" "$source/$loopfolder/$snapfolder/"$snapname

  #delete old snapshot
  if [ ! -z $Bcount ]
  then
    ls -dr "$source/$loopfolder/$snapfolder/"$snappattern | tail -n +$Bcount | while read "snapshot"
    do
      btrfs sub del "$snapshot"
    done
  fi

  rm "/tmp/buttersync-$loopfolder"

done < "$includefile"

