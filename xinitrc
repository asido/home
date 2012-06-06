#!/bin/sh
# $XConsortium: xinitrc.cpp,v 1.4 91/08/22 11:41:34 rws Exp $

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f $userresources ]; then
    xrdb -merge $userresources
fi

if [ -f $usermodmap ]; then
    xmodmap $usermodmap
fi

xmodmap ~/.xmodmap

# Set dualscreen settings if using nouveau drivers
if lsmod | grep nouveau ; then
	xrandr --output DVI-I-1 --mode 1920x1080 --pos 0x0 --rotate normal --output HDMI-1 --off --output DVI-I-2 --mode 1920x1080 --pos 1920x0 --rotate normal
fi

# Disable mouse acceleration
xset m 1 0

# Start the window manager:
# exec ck-launch-session /usr/bin/awesome
exec /usr/bin/awesome
#exec ~/src/awesome/awesome
#exec openbox-session
