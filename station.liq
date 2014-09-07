#!/usr/bin/liquidsoap
# Log dir
set("log.file.path","/tmp/basic-radio.log")
set("harbor.bind_addr","0.0.0.0")
set("log.level",4)
live = input.harbor("stream.ogg",port=8001,password="pass",buffer=5.)

# Our custom request function
def get_request() = 
  # Get the URI
  uri = list.hd(get_process_lines("getsong.sh"))
  # Create a request
  request.create(uri)
end

dynamic = request.dynamic(id="dynamicplaylist",get_request)

# If something goes wrong, we'll play this
security = single("~/ids/default1.mp3")

# And finally the security
radio = fallback(track_sensitive = false, [live, dynamic, security])

def process_meta(m) = 
#creating string variables of the input list
  type = m["type"]
  show = m["display_desc"]
  artist = m["artist"]
  album = m["album"]
  title = m["title"]
  if type == "song" then
    system("~/bin/logsong.sh " ^ quote (show ^ " ~~~ " ^ artist ^ " ~~ " ^ album ^ " ~ " ^ title) ^ " >> /tmp/out 2>&1 &")
    system("~/bin/milinks.sh " ^ quote (artist) ^ " " ^ quote (title) ^ " & ")
    system("~/bin/mivids.sh " ^ quote (artist) ^ " & ")
    system("echo " ^ quote (show ^ " ~~~ " ^ artist ^ " ~~ " ^ album ^ " ~ " ^ title) ^ " > /var/www/nowplaying.txt")
  elsif type == "unknown" then
    system("echo " ^ quote (show ^ "") ^ " > /var/www/nowplaying.txt")
    system("echo '' > /var/www/milinks.txt")
    system("echo '' > /var/www/mivids.txt")
  elsif type == "id" then
    system("echo " ^ quote (show ^ "") ^ " > /var/www/nowplaying.txt")
    system("echo '' > /var/www/milinks.txt")
    system("echo '' > /var/www/mivids.txt")
  else
    system("echo " ^ quote (show ^ " ~~~ " ^ artist ^ " ~~ " ^ album ^ " ~ " ^ title) ^ " > /var/www/nowplaying.txt")
    system("echo '' > /var/www/milinks.txt")
    system("echo '' > /var/www/mivids.txt")
  end
end
radio = on_metadata(process_meta,radio)

def set_meta(m) =
  show = m["display_desc"] 
  artist = m["artist"]
#  album = m["album"]
  title = m["title"]
  type = m["type"]
  if type == "unknown" then
    [
      ("artist",""),
      ("title","")
    ]
  elsif type == "id" then
    [
      ("artist",""),
      ("title","")
    ]
  elsif artist == "n/a" then
    [
      ("artist","#{show}")
    ]
  else
    [
      ("artist","#{artist}"),
      ("title","#{title}")
    ]
  end
end
radio = map_metadata(set_meta,radio)

radio = audio_to_stereo(radio)
radio = crossfade(start_next=0.5,fade_in=0.5,fade_out=0.5,radio)

radio = nrj(radio)

# Stream it out
output.icecast(
  %mp3.vbr(quality=6,id3v2=true),
  host = "host", port = port, 
  password = "password", mount = "mountpoint", 
  description = "My Station", url = "http://www.example.com",
  genre = "Metal", 
  radio)
