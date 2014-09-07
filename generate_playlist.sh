#!/bin/bash  

TMPDIR=/tmp/$$playlist
mkdir $TMPDIR
[ $# -ne 1 ] && exit 1
SHOWDIR=$1
SHOW=${SHOWDIR##*/}
THISWEEK=$(date +%W)
DAYOFWEEK=$(date +%A)
if [ -d $SHOWDIR/week${THISWEEK}/${DAYOFWEEK} ]; then
  WEEKDIR="$SHOWDIR/week${THISWEEK}/${DAYOFWEEK}"
else
  WEEKDIR="$SHOWDIR/week${THISWEEK}"
fi
[ -e $WEEKDIR ] || WEEKDIR="$SHOWDIR/default"
[ -e $WEEKDIR ] || exit 1
IDDIR=$HOME/ids
# set IDDIR if one exists
ls $SHOWDIR/ids/*.mp3 &>/dev/null && IDDIR=$SHOWDIR/ids
PASSED=$TMPDIR/passed
FAILED=$TMPDIR/failed
[ -e $PASSED ] && rm -fv $PASSED
[ -e $FAILED ] && rm -fv $FAILED
declare -A POSITIONS
(cd $WEEKDIR; ls *.{mp3,mp4,m4a,ogg} 2>/dev/null >$TMPDIR/tracks)
while read line; do
  ARTIST=$(extract "$WEEKDIR/$line" | grep '^artist' | head -n1 | awk -F ' - ' '{print $2}')
  ALBUM=$(extract "$WEEKDIR/$line" | grep '^album' | head -n1 | awk -F ' - ' '{print $2}')
  TITLE=$(extract "$WEEKDIR/$line" | grep '^title' | head -n1 | awk -F ' - ' '{print $2}')
  if [ -n "$ARTIST" -a -n "$ALBUM" -a -n "$TITLE" ]; then
    echo "$ARTIST - $ALBUM - $TITLE"
    if [[ $line =~ ^#{1,3}\ ([0-9]{1,2})\  ]]; then
      POS=${BASH_REMATCH[1]}
      if [ $POS -eq 0 ]; then
        # zero is an invalid position
        :
      else
        if [[ $POS =~ 0[1-9] ]]; then
          POSITIONS[${POS##*0}]="$line"
        else
          POSITIONS[${POS}]="$line"
        fi
      fi
    else
      echo "$line" >> $PASSED
    fi
  else
    echo "$line" >> $FAILED
  fi
done < $TMPDIR/tracks

TMPPLIST=$TMPDIR/playlist
[ -e $TMPPLIST ] && rm -fv $TMPPLIST
OUTFILE=$HOME/playlists/${SHOW}week${THISWEEK}
FAILFILE=$HOME/playlists/${SHOW}week${THISWEEK}failed
[ -e $OUTFILE ] && rm -fv $OUTFILE
LINECOUNT=$(wc -l $PASSED | awk '{print $1}')
for NUM in `seq 1 $LINECOUNT`; do
  SONGSLEFT=$(wc -l ${PASSED} | awk '{print $1}')
  SONGLINE=$(($RANDOM % $SONGSLEFT))
  [ $SONGLINE -eq 0 ] && SONGLINE=1
  SONGPATH=$(sed -n ${SONGLINE}p $PASSED)
  sed -i ${SONGLINE}d ${PASSED}
  if [ ! -e $TMPPLIST ]; then
    echo "$WEEKDIR/$SONGPATH" > $TMPPLIST
  else
    echo "$WEEKDIR/$SONGPATH" >> $TMPPLIST
  fi
done 
INORDER=$(for NUM in  "${!POSITIONS[@]}"; do echo $NUM; done | sort -g)
for POS in $INORDER; do
  LINECOUNT=$(wc -l $TMPPLIST | awk '{print $1}')
  if [ $POS -le $LINECOUNT ]; then
    sed -i "${POS}i $WEEKDIR/${POSITIONS[$POS]}" $TMPPLIST
  else
    echo "$WEEKDIR/${POSITIONS[$POS]}" >> $TMPPLIST
  fi
done
mv -v $TMPPLIST $OUTFILE
mv -v $FAILED $FAILFILE
rm -rfv $TMPDIR
