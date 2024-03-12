#!/usr/bin/env sh
WEBCAM_FOUND=$(ps aux | awk '{print $11}' | grep gphoto2)
if [ "$WEBCAM_FOUND" = 'gphoto2' ] ; then
    killall gphoto2
    exit
fi

gphoto2 --stdout --capture-movie | ffmpeg -i - -vcodec rawvideo -pix_fmt yuv420p -threads 0 -f v4l2 /dev/video0

