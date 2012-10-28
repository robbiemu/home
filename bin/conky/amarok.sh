#!/bin/bash

usest=yes	# Put "yes" to display album as "Self-Titled" where applicable, "no" to use album name

case "$1" in

# Now Playing Info
artist) qdbus org.kde.amarok /Player GetMetadata | grep artist | cut -c9- ;;
title) qdbus org.kde.amarok /Player GetMetadata | grep title | cut -c8- ;;
year)   qdbus org.kde.amarok /Player GetMetadata | grep year | cut -c7- ;;
genre)  qdbus org.kde.amarok /Player GetMetadata | grep genre | cut -c8- ;;
album)

  artistname=`qdbus org.kde.amarok /Player GetMetadata | grep artist | cut -c9-`
  albumname=`qdbus org.kde.amarok /Player GetMetadata | grep album: | cut -c8-`

    if [ "$albumname" = "" ]
      then
	echo ""
      else
	if [ "$usest" = yes ]
	then
	    if [ "$albumname" = "$artistname" ]
	      then
		echo "Self-titled"
	      else
		echo $albumname
	    fi
	else
	  echo $albumname
	fi
    fi  
;;
cover) 
  # Temp directory must be full path.
  tempdir="/tmp"
  tempfile="${tempdir}/nowplaying"

  [ -d "$tempdir" ] || mkdir -p "$tempdir"  #test if $tempdir exists, if not create it.
  [ -e "$tempfile" ] || touch "$tempfile"

  cover="$(qdbus org.kde.amarok /Player GetMetadata | grep arturl)"
  [ -z "$cover" ] && exit      #test if $cover was set, if not exit.

  hash=$(echo "$cover" | cut -c16- | sed "s/%20/\\\ /g") #Generate hash for current song.

  read oldhash < "$tempfile"

  if [ "$oldhash" == "$hash" ];then
	  :
  else
	    cp $hash $tempdir/cover.jpg
	  echo $hash > "$tempfile"
  fi
;;
esac
