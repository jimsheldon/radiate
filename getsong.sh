#!/bin/bash 

NEXTSONG=$HOME/playlists/nextsong
if [ -e $NEXTSONG ]; then
  cat $NEXTSONG
  rm -f $NEXTSONG &>/dev/null
  exit 0
fi

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
SCHEDULE=${DAYOFWEEK}.txt
IDDIR=$HOME/ids
SHOWNAME=$(grep "^$SHOWHOUR " $HOME/schedule/$SCHEDULE | awk '{print $2}')
# set IDDIR if one exists
ls /home/$SHOWNAME/ids/default*.mp3 &>/dev/null && IDDIR=/home/$SHOWNAME/ids
PLIST=$HOME/playlists/${SHOWNAME}week${THISWEEK}
if [ ! -e $PLIST ]; then
  SHOWNAME=""
  PLIST=$HOME/playlists/fallbackweek${THISWEEK}
  IDDIR=$HOME/ids
  if [ ! -e $PLIST ]; then
    generate_playlist.sh $HOME/fallback &>/dev/null
    sleep 2
  fi
  [ -e $PLIST ] || exit 1
fi

if [ -n "$SHOWNAME" ]; then
  FULLSHOWNAME=$(getent passwd $SHOWNAME | cut -d ':' -f 5 | awk -F, '{print $1}')
else
  FULLSHOWNAME="MetalInjection.FM"
fi
if [ ! -e $HOME/playlists/defaultids ]; then
  ls $IDDIR/default*.mp3 | sort -R > $HOME/playlists/defaultids
fi
IDCOUNT=$(wc -l $HOME/playlists/defaultids | awk '{print $1}')
SONGPATH=$(sed -n 1p $PLIST)
ALBUM=$(extract "$SONGPATH" | grep '^album' | head -n1 | awk -F ' - ' '{print $2}')
if [[ $SONGPATH =~ \#\#\#\ [0-9] ]]; then
  PLAYTHIS="annotate:type=\"unknown\",album=\"$ALBUM\",display_desc=\"$FULLSHOWNAME\",liq_start_next=\"1.5\",liq_fade_in=\"0.\",liq_fade_out=\"0.\":$SONGPATH"
elif [[ $SONGPATH =~ \#\#\ [0-9] ]]; then
  PLAYTHIS="annotate:type=\"nochart\",album=\"$ALBUM\",display_desc=\"$FULLSHOWNAME\",liq_start_next=\"2.5\",liq_fade_in=\"3.5\",liq_fade_out=\"3.5\":$SONGPATH"
elif [[ $SONGPATH =~ \#\ [0-9] ]]; then
  PLAYTHIS="annotate:type=\"song\",album=\"$ALBUM\",display_desc=\"$FULLSHOWNAME\",liq_start_next=\"2.5\",liq_fade_in=\"3.5\",liq_fade_out=\"3.5\":$SONGPATH"
else
  ARTIST=$(extract "$SONGPATH" | grep '^artist' | head -n1 | awk -F ' - ' '{print $2}')
  if [ -e "/home/$SHOWNAME/ids/${ARTIST}.mp3" ]; then
    PLAYTHIS="annotate:type=\"id\",display_desc=\"$FULLSHOWNAME\",liq_start_next=\"1.5\",liq_fade_in=\"0.\",liq_fade_out=\"0.\":/home/$SHOWNAME/ids/${ARTIST}.mp3"
    echo "annotate:type=\"song\",album=\"$ALBUM\",display_desc=\"$FULLSHOWNAME\",liq_start_next=\"2.5\",liq_fade_in=\"3.5\",liq_fade_out=\"3.5\":$SONGPATH" > $NEXTSONG
  elif [ -e "$IDDIR/${ARTIST}.mp3" ]; then
    PLAYTHIS="annotate:type=\"id\",display_desc=\"$FULLSHOWNAME\",liq_start_next=\"1.5\",liq_fade_in=\"0.\",liq_fade_out=\"0.\":$IDDIR/${ARTIST}.mp3"
    echo "annotate:type=\"song\",album=\"$ALBUM\",display_desc=\"$FULLSHOWNAME\",liq_start_next=\"2.5\",liq_fade_in=\"3.5\",liq_fade_out=\"3.5\":$SONGPATH" > $NEXTSONG
  else
    RANDID=$(($RANDOM % 5))
    if [ $RANDID -ne 0 -a $RANDID -ne 2 ]; then
      if [ -e $HOME/playlists/playeddefaultid ]; then
        rm $HOME/playlists/playeddefaultid
        PLAYTHIS="annotate:type=\"song\",album=\"$ALBUM\",display_desc=\"$FULLSHOWNAME\",liq_start_next=\"2.5\",liq_fade_in=\"3.5\",liq_fade_out=\"3.5\":$SONGPATH"
      else
        ID=$(sed -n 1p $HOME/playlists/defaultids)
        sed -i 1d $HOME/playlists/defaultids
        echo "$ID" >> $HOME/playlists/defaultids
        PLAYTHIS="annotate:type=\"id\",display_desc=\"$FULLSHOWNAME\",liq_start_next=\"1.5\",liq_fade_in=\"0.\",liq_fade_out=\"0.\":$ID"
        echo "annotate:type=\"song\",album=\"$ALBUM\",display_desc=\"$FULLSHOWNAME\",liq_start_next=\"2.5\",liq_fade_in=\"3.5\",liq_fade_out=\"3.5\":$SONGPATH" > $NEXTSONG
        touch $HOME/playlists/playeddefaultid
      fi
    else
      PLAYTHIS="annotate:type=\"song\",album=\"$ALBUM\",display_desc=\"$FULLSHOWNAME\",liq_start_next=\"2.5\",liq_fade_in=\"3.5\",liq_fade_out=\"3.5\":$SONGPATH"
    fi
  fi
fi
sed -i 1d $PLIST
if [ "$FULLSHOWNAME" = "MetalInjection.FM" ]; then
  echo "$SONGPATH" >> $PLIST
fi
SONGSLEFT=$(wc -l ${PLIST} | awk '{print $1}')
[ $SONGSLEFT -eq 0 ] && rm ${PLIST}
echo $PLAYTHIS
