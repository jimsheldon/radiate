#!/usr/bin/liquidsoap
# Log dir
set("log.file.path","/tmp/basic-radio.log")
set("harbor.bind_addr","0.0.0.0")
set("log.level",4)
live = input.harbor("test-harbor",port=8001,password="password",buffer=5.)

# Our custom request function
def get_request() = 
  # Get the URI
  uri = list.hd(get_process_lines("getsong.sh"))
  # Create a request
  request.create(uri)
end

dynamic = request.dynamic(id="dynamicplaylist",get_request)

# If something goes wrong, we'll play this
security = single("~/ids/default.mp3")

# And finally the security
radio = fallback(track_sensitive = false, [live, dynamic, security])

def process_meta(m) = 
#creating string variables of the input list
  type = m["type"]
  if type == "song" then
    show = m["display_desc"]
    artist = m["artist"]
    album = m["album"]
    title = m["title"]
    system("~/bin/logsong.sh " ^ quote (show ^ " --- " ^ artist ^ " -- " ^ album ^ " - " ^ title) ^ " >> /tmp/out 2>&1 &")
  end
end
radio = on_metadata(process_meta,radio)

def set_meta(m) =
  show = m["display_desc"] 
  artist = m["artist"]
  album = m["album"]
  title = m["title"]
  type = m["type"]
  if type == "song" then
    [
      ("artist","#{show} --- #{artist} -- #{album}"),
      ("title","#{title}")
    ]
  elsif type == "nochart" then
    [
      ("artist","#{show} --- #{artist} -- #{album}"),
      ("title","#{title}")
    ]
  else
    [
      ("artist","#{show}"),
      ("title","")
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
  host = "localhost", port = 8000, 
  password = "password", mount = "mountpoint", 
  description = "My Station", url = "http://www.example.com",
  radio)
