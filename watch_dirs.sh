#!/bin/bash 

THISHOUR=$(date +%k)
THISHOUR=${THISHOUR// /}
MOD3HOUR=$(($THISHOUR % 3))
if [ $MOD3HOUR -eq 0 ]; then
  SHOWHOUR=$THISHOUR
else
  SHOWHOUR=$(($THISHOUR - $MOD3HOUR))
fi
DAYOFWEEK=$(date +%A)
THISWEEK=$(date +%W)
SHOWDIRS=$HOME/schedule/showdirs.txt

while read line; do
  SHOW=$(echo $line | awk '{print $1}')
  SHOWDIR=$(echo $line | awk '{print $2}')
  WEEKDIR=$SHOWDIR/week${THISWEEK}
  [ -d $WEEKDIR ] || continue
  ONAIR=$(grep "^$SHOWHOUR " $HOME/schedule/${DAYOFWEEK}.txt | awk '{print $2}')
  [ "$ONAIR" = "$SHOW" ] && continue
  PLIST=$HOME/playlists/${SHOW}week${THISWEEK}
  if [ ! -e $PLIST ]; then
    $HOME/bin/generate_playlist.sh $SHOWDIR
  else
    NEWFILES=$(find $WEEKDIR -type f -newer $PLIST | wc -l | awk '{print $1}')
    if [ $NEWFILES -gt 0 ]; then
      $HOME/bin/generate_playlist.sh $SHOWDIR
    fi
  fi
done < $SHOWDIRS
