#!/bin/bash

THISDAY=$(date +%A)
THISWEEK=$(date +%W)
HOURMIN=$(date +%H:%M)

LOGDIR=$HOME/logs/week${THISWEEK}
LOGFILE=$LOGDIR/${THISDAY}.txt

[ -d $LOGDIR ] || mkdir -p $LOGDIR
echo "$HOURMIN $@" >> $LOGFILE
