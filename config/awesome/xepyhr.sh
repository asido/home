#!/bin/bash
# script xepyhr-awesome

# might need to export specific LUA_PATH if running not installed awesome
#	export LUA_PATH=";;$HOME/src/awesome-3.4.11/build/lib/?.lua;$HOME/src/awesome-3.4.11/build/lib/?/init.lua"

## mod4 key fix
#	 $ xmodmap -
# 	 keycode 133 = Super_L    # Your keycode might be different. See what it is using xev.
# 	 # Press Control-D here to finish xmodmap input


Xephyr -ac -br -noreset -screen 1024x768 :1 &
sleep 1
DISPLAY=:1.0 awesome -c ~/.config/awesome/dev_rc.lua
