#!/bin/bash -x
PATH=/home/ubuntu/bin:/home/ubuntu/bin:/home/ubuntu/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
export PATH

THISHOUR=$(date +%k)
THISHOUR=${THISHOUR// /}
MOD3HOUR=$(($THISHOUR % 3))
if [ $MOD3HOUR -eq 0 ]; then
  SHOWHOUR=$THISHOUR
else
  SHOWHOUR=$(($THISHOUR - $MOD3HOUR))
fi
# if a new day just started, we need to look at the show that just ended yesterday
if [ $THISHOUR -eq 0 ]; then
  DAYOFWEEK=$(date -d '1 day ago' +%A)
  LASTSHOWHOUR=21
else
  LASTSHOWHOUR=$((THISHOUR - 3))
  DAYOFWEEK=$(date +%A)
fi
THISWEEK=$(date +%W)
SCHEDULE=${DAYOFWEEK}.txt
SHOWNAME=$(grep "^$LASTSHOWHOUR " $HOME/schedule/$SCHEDULE | awk '{print $2}')
PLIST=$HOME/playlists/${SHOWNAME}week${THISWEEK}
# remove the playlist of the show that just ended, it will be recreated by watch_dirs.sh
[ -e $PLIST ] && rm -f $PLIST
# remove default ID playlist so it re-randomizes
rm -f $HOME/playlists/defaultids

COUNT=0
while [ $COUNT -lt 10 ]; do
  sleep 1
  REMAINING=$(telnet_command.sh radio.remaining | telnet localhost 1234 | grep [0-9]\.[0-9] | grep -v Trying)
  if [ -z "$REMAINING" ]; then
    :
  elif [ ${REMAINING%.*} -gt 300 ]; then
    echo "skipping current song at `date`"
    telnet_command.sh radio.skip | telnet localhost 1234 &>/dev/null
    exit 0
  else
    echo "less than 5 minutes left in song, not skipping"
    exit 0
  fi
  let COUNT++
done
