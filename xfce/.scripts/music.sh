#!/bin/bash

PID_FILE="/tmp/mpv_music.pid"

if [[ $1 == "stop" ]]; then
    if [[ -f $PID_FILE ]]; then
        kill "$(cat $PID_FILE)" && rm -f $PID_FILE
        echo "Music player stopped."
    else
        echo "No music player is running."
    fi
else
    if [[ -f $PID_FILE ]]; then
        echo "Music player is already running."
        exit 1
    fi

    nohup mpv -v --ytdl-format=ba --loop "$1" > /dev/null 2>&1 &

    echo $! > $PID_FILE
    echo "Music player started in the background."
fi

