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
if [ -z $port ]; then port=22; fi

#check if connection can be established
if ssh $host -n -p$port exit
then
  echo "Connection checked"
else
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
      if ps -p $(cat "/tmp/buttersync-$loopfolder")&>/dev/null
      then
          echo "$loopfolder: Another process of buttersync is accessing this directory. Try again later"
          continue
      fi
   fi
  echo $$>"/tmp/buttersync-$loopfolder"

  curent=$(ls -1 "$source/$loopfolder/$snapfolder" | tail -n 1)

  #Start

  # create folder if necessary
  if ssh $host -n -p$port "[ ! -d '$Rtarget/$loopfolder' ]" ;then
     ssh $host -n -p$port mkdir "$Rtarget/$loopfolder"
  fi

  #transfer snapshot with rsync
  echo "$loopfolder: File transfer: "$(du -sh "$source/$loopfolder/$snapfolder")
  rsync -e "ssh -p$port" -aP "--exclude=$snapfolder" "$source/$loopfolder/$snapfolder/$curent" "$host:'$Rtarget/$loopfolder/'"
  if [ $? ]
  then
   echo "sync done"
  else
    echo "$loopfolder: error during rsync file transfer."
    continue
  fi

  #delete old snapshot
  if [ ! -z $Rcount ]
  then
    ssh $host -n -p$port ls -dr '$Rtarget/$loopfolder/$snappattern' | tail -n +$Rcount | while read "snapshot"
    do
      ssh $host -n -p$port echo  "REMOVE: $snapshot"
      echo  "REMOVE: $snapshot"
    done
  fi

  rm "/tmp/buttersync-$loopfolder"

done < "$includefile" # read includefile
