#!/bin/bash

STATSDIR=/var/www/stats
[ -d $STATSDIR ] || mkdir -p $STATSDIR
TMPDIR=/tmp/stats_$$
mkdir -p $TMPDIR
THISWEEK=$(date +%W)
THISDAY=$(date +%A)

LOGFILE=$HOME/logs/week${THISWEEK}/${THISDAY}.txt
if [ -e $LOGFILE ]; then
  while read line; do
    if [[ $line =~ ([0-9]{1,2}:[0-9]{1,2})\ (.*)\ ---\ (.*)\ --\ (.*)\ -\ (.*) ]]; then
      TIME="${BASH_REMATCH[1]}"
      SHOW="${BASH_REMATCH[2]}"
      ARTIST="${BASH_REMATCH[3]}"
      ALBUM="${BASH_REMATCH[4]}"
      TRACK="${BASH_REMATCH[5]}"
      echo "$ARTIST - $ALBUM" >> $TMPDIR/${THISDAY}_albums
      echo "$ARTIST - $TRACK" >> $TMPDIR/${THISDAY}_tracks
      echo "$ARTIST" >> $TMPDIR/${THISDAY}_artists
    fi
  done < $LOGFILE
  TMPSTATS=$TMPDIR/$THISDAY
  echo "<html><head>" > $TMPSTATS
  echo "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />" >> $TMPSTATS
  echo "<title>Statistics for $THISDAY</title>" >> $TMPSTATS
  echo "</head><body><pre>" >> $TMPSTATS
  echo "Generated at `date`" >> $TMPSTATS
  echo -e "\nALBUMS\n" >> $TMPSTATS
  echo -e " Plays | Artist - Album\n" >> $TMPSTATS
  cat $TMPDIR/${THISDAY}_albums | sort | uniq -c | sort -r >> $TMPSTATS
  echo -e "\nTRACKS\n" >> $TMPSTATS
  echo -e " Plays | Aritst - Track\n" >> $TMPSTATS
  cat $TMPDIR/${THISDAY}_tracks | sort | uniq -c | sort -r >> $TMPSTATS
  echo -e "\nARTISTS\n" >> $TMPSTATS
  echo -e " Plays | Artist\n" >> $TMPSTATS
  cat $TMPDIR/${THISDAY}_artists | sort | uniq -c | sort -r >> $TMPSTATS
  echo -e "</pre></body></html>" >> $TMPSTATS
fi

mv -v $TMPSTATS $STATSDIR/${THISDAY}.html
rm -rfv $TMPDIR

