#!/bin/bash 

PATH=/home/ubuntu/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
export PATH

TMPDIR=/tmp/$$_milinks

die () {
  echo "*** Error ***: $@" >&2
  exit 1
  [ -d $TMPDIR ] && rm -rf $TMPDIR
}

mkdir $TMPDIR
cd $TMPDIR || die "failed to create $TMPDIR"
echo "" > /var/www/milinks.txt

AMAZONLINK=$(amazonlink.php "$1 $2")
if [[ $AMAZONLINK =~ (http.*) ]]; then
  CLEANLINK=${BASH_REMATCH[1]}
  echo "<strong>(Buy on <a href=\"$CLEANLINK\" target=\"new\">Amazon</a></strong>)" >> /var/www/milinks.txt
fi

QUERY=$(urlencode.sh "$1")

wget -O feed.out http://www.metalinjection.net/?feed=rss2\&s=%22${QUERY}%22 &>/dev/null

xmlstarlet sel --text -t -m "rss/channel/item" -o '&#187;&nbsp;<a href="' -v "link" -o '" target="new">' -v "title" -o '</a><br/>' -n feed.out | head -n3 > links
LINKLINES=$(wc -l links | awk '{print $1}')
if [ $LINKLINES -gt 0 ]; then
  echo '<br/><br/>Related Links:<br/>' >> /var/www/milinks.txt
  cat links >> /var/www/milinks.txt
fi

cd $HOME
rm -rf $TMPDIR

